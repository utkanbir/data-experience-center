import json,os,re,shutil
from pathlib import Path
from datetime import datetime,timezone
from decimal import Decimal
import psycopg
from trino.dbapi import connect

def close_enough(a,b):return abs(Decimal(str(a))-Decimal(str(b)))<Decimal('0.0001')
def evaluate_totals(rows):
    monthly={};by_key={}
    for month,channel,revenue,liters in rows:
        key=(str(month),channel)
        if key in by_key:raise ValueError('Duplicate month/channel row')
        by_key[key]=(revenue,liters);monthly[str(month)]=monthly.get(str(month),Decimal(0))+Decimal(str(revenue))
    jan=by_key.get(('2025-01-01','HoReCa'));feb=by_key.get(('2025-02-01','HoReCa'))
    if not jan or not feb or len(by_key)!=6:raise ValueError('Expected six month/channel rows')
    checks={'months':len(monthly)==2 and close_enough(monthly.get('2025-01-01',0),'27820.80') and close_enough(monthly.get('2025-02-01',0),'23284.80'),'horeca':close_enough(jan[0],'8164.80') and close_enough(feb[0],'3628.80'),'volume':close_enough(jan[1],'1844.64') and close_enough(feb[1],'819.84'),'price':close_enough(Decimal(str(jan[0]))/Decimal(str(jan[1])),Decimal(str(feb[0]))/Decimal(str(feb[1]))) and close_enough(Decimal(str(jan[0]))/Decimal(str(jan[1])),'4.4262295082')}
    return checks,{'janRevenue':float(jan[0]),'febRevenue':float(feb[0]),'janLiters':float(jan[1]),'febLiters':float(feb[1]),'change':float(Decimal(str(feb[0]))-Decimal(str(jan[0])))}

def main():
    base=Path('/artifacts');config=json.loads(Path('/experience/run.json').read_text());run_id=config['runId']
    if not re.fullmatch(r'run-[A-Za-z0-9-]{1,70}',run_id):raise ValueError('Invalid run ID')
    out=base/'runs'/run_id;out.mkdir(parents=True,exist_ok=False);evidence=out/'kanitlar';evidence.mkdir()
    profile=json.loads(Path('/experience/report-profile.json').read_text());states={k:'not_tested' for k,*_ in profile['checks']};metrics=dict.fromkeys(['janRevenue','febRevenue','janLiters','febLiters','change']);executions=[];details={}
    def tq(statement):
        conn=connect(host='trino',port=8080,user='rm9_report',catalog='models',schema='dwh');cursor=conn.cursor()
        try:cursor.execute(statement.strip().rstrip(';'));return cursor.fetchall()
        finally:cursor.close();conn.close()
    def pg(host,db,admin=False):return psycopg.connect(host=host,dbname=db,user='rm9_admin' if admin else 'rm9_bi',password=os.environ['PGADMIN_PASSWORD'] if admin else os.environ['PGPASSWORD'],connect_timeout=15)
    def check(key,result):states[key]='passed' if result else 'failed'
    for stage,names,filename in [('dbt',['dbt_models','dbt_tests','dbt_docs'],'dbt-status.txt'),('cube',['cube_api','cube_sql','cube_match','two_consumers','api_auth'],'cube-status.txt'),('catalog',['om_catalog','om_owner','om_glossary','om_lineage','om_metric','om_quality','om_product'],'governance-status.txt')]:
        try:
            status=(base/filename).read_text().splitlines()
            if config['stages'].get(stage) and len(status)==len(names) and all(v in ('passed','failed','not_tested') for v in status):states.update(zip(names,status))
        except Exception:pass
    for name in ['manifest.json','build_results.json','catalog.json','static_index.html','dbt-checks.json','cube-checks.json','cube-results.json','cube-sql.json','python-results.json','dashboard-results.json','governance-checks.json','catalog-lineage-map.json']:
        if (base/name).exists():shutil.copyfile(base/name,evidence/name)
    try:
        identifiers=[];layouts=[];roles=[];empty=[]
        for host,db,relation in [('postgres','komtas_rm9','sales_line'),('postgres-reference','komtas_rm9_reference','dim_outlet')]:
            with pg(host,db,True) as c:identifiers.append(str(c.execute('SELECT system_identifier FROM pg_control_system()').fetchone()[0]))
            with pg(host,db) as c:
                layouts.append([x[0] for x in c.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='raw' ORDER BY table_name")]);empty.append(c.execute("SELECT count(*) FROM information_schema.tables WHERE table_schema='dwh'").fetchone()[0]==0)
                roles.append(c.execute("SELECT current_user, current_setting('default_transaction_read_only'),has_table_privilege(current_user,%s,'INSERT')",('raw.'+relation,)).fetchone())
                if host=='postgres':check('rows',c.execute('SELECT count(*) FROM raw.sales_line').fetchone()[0]==2016)
        check('source_instances',len(set(identifiers))==2);check('source_split',layouts[0]==['sales_line'] and layouts[1]==['dim_date','dim_outlet','dim_product','dim_promotion']);check('schemas',all(layouts));check('bi_role',all(row[0]=='rm9_bi' for row in roles));check('no_insert',all(not row[2] for row in roles));check('source_readonly',all(row[0]=='rm9_bi' and row[1]=='on' and not row[2] for row in roles))
        views=tq("SELECT table_name,table_type FROM models.information_schema.tables WHERE table_schema='dwh'");check('no_materialization',len(views)==7 and all(row[1]=='VIEW' for row in views) and all(empty));details.update(instanceIdentifiers=identifiers,sourceTables=layouts,modelObjects=views)
    except Exception as error:details['sourceError']=str(error);states['source_instances']='failed'
    join='SELECT count(*) FROM sales.raw.sales_line s JOIN reference.raw.dim_outlet o ON s.outlet_key=o.outlet_key JOIN reference.raw.dim_product p ON s.product_key=p.product_key'
    try:
        check('federated_join',tq(join)[0][0]==2016);plan='\n'.join(str(row[0]) for row in tq('EXPLAIN (TYPE DISTRIBUTED) '+join));(evidence/'federation-plan.txt').write_text(plan);check('federation_plan',all(v in plan.lower() for v in ['sales','reference','sales_line','dim_outlet','dim_product']))
    except Exception as error:states['federated_join']='failed';states['federation_plan']='failed';details['joinError']=str(error)
    try:
        totals=tq('SELECT month_start,channel,sum(gross_revenue_eur-discount_amount_eur-return_amount_eur),sum(net_volume_liters) FROM models.dwh.v_sales_detail GROUP BY month_start,channel ORDER BY month_start,channel');evaluated,metrics=evaluate_totals(totals)
        for key,result in evaluated.items():check(key,result)
        (evidence/'reference-totals.json').write_text(json.dumps(totals,default=str,indent=2))
    except Exception as error:details['totalsError']=str(error)
    for filename in ['01-kanal-geliri.sql','02-horeca-degisim.sql','03-distributor-urun.sql','verify.sql']:
        statement=Path('/experience/'+filename).read_text();(evidence/filename).write_text(statement);status='failed'
        try:
            result=tq(statement);(evidence/(filename+'.json')).write_text(json.dumps(result,default=str,indent=2));status='passed'
            if filename=='verify.sql' and ((len(result)!=1 or len(result[0])!=1 or result[0][0]!=2016) or any(states[k]!='passed' for k in ['months','horeca','volume','price','source_instances','source_split','federated_join','federation_plan','no_materialization','source_readonly'])):status='failed'
        except Exception as error:(evidence/(filename+'.error.txt')).write_text(str(error))
        executions.append({'file':filename,'status':status})
    (evidence/'federation-checks.json').write_text(json.dumps({'checks':[{'id':k,'status':states[k]} for k in ['source_instances','source_split','federated_join','federation_plan','no_materialization','source_readonly']],'details':details},default=str,indent=2))
    result={'schemaVersion':1,'architecture':profile['architecture'],'architectureVersion':profile['architectureVersion'],'scenario':profile['scenario'],'generatedAt':datetime.now(timezone.utc).isoformat(),'namespace':os.environ['NAMESPACE'],'executions':executions,'observation':{'checks':[{'id':k,'status':v} for k,v in states.items()],'metrics':metrics}}
    (out/'sonuc.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps({state:sum(c==state for c in states.values()) for state in ['passed','failed','not_tested']}));return 0

if __name__=='__main__':raise SystemExit(main())

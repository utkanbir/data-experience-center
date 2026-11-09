import json,os,re,shutil
from pathlib import Path
from datetime import datetime,timezone
from decimal import Decimal
import psycopg

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
    def pg():return psycopg.connect(host='postgres',dbname='komtas_rm10',user='rm10_bi',password=os.environ['PGPASSWORD'],connect_timeout=15)
    def tq(statement):
        with pg() as conn:return conn.execute(statement).fetchall()
    def check(key,result):states[key]='passed' if result else 'failed'
    stages=[('dbt',['dbt_models','dbt_tests','dbt_docs'],'dbt-status.txt'),('cube',['cube_api','cube_sql','cube_match','two_consumers','api_auth'],'cube-status.txt'),('catalog',['om_catalog','om_owner','om_glossary','om_lineage','om_metric','om_quality','om_product'],'governance-status.txt'),('graph',['ontology_definition','graph_entities','graph_relationships','graph_provenance','graph_freshness','graph_paths','graph_metric_context','graph_model_binding'],'graph-status.txt')]
    for stage,names,filename in stages:
        try:
            status=(base/filename).read_text().splitlines()
            if config['stages'].get(stage) and len(status)==len(names) and all(v in ('passed','failed','not_tested') for v in status):states.update(zip(names,status))
        except Exception:pass
    for name in ['manifest.json','build_results.json','catalog.json','static_index.html','dbt-checks.json','cube-checks.json','cube-results.json','cube-sql.json','python-results.json','dashboard-results.json','governance-checks.json','graph-checks.json','graph-results.json']:
        if (base/name).exists():shutil.copyfile(base/name,evidence/name)
    shutil.copyfile('/experience/ontology.json',evidence/'ontology.json')
    try:
        check('schemas',tq("SELECT count(*) FROM information_schema.schemata WHERE schema_name IN ('raw','dwh')")[0][0]==2)
        check('rows',tq('SELECT count(*) FROM dwh.fact_sales')[0][0]==2016)
        role=tq("SELECT current_user,current_setting('default_transaction_read_only'),has_table_privilege(current_user,'dwh.fact_sales','INSERT')")[0]
        check('bi_role',role[0]=='rm10_bi' and role[1]=='on');check('no_insert',not role[2])
        totals=tq('SELECT month_start,channel,sum(gross_revenue_eur-discount_amount_eur-return_amount_eur),sum(net_volume_liters) FROM dwh.v_sales_detail GROUP BY month_start,channel ORDER BY month_start,channel');evaluated,metrics=evaluate_totals(totals)
        for key,result in evaluated.items():check(key,result)
        (evidence/'reference-totals.json').write_text(json.dumps(totals,default=str,indent=2))
    except Exception as error:details['sourceError']=str(error)
    for filename in ['01-kanal-geliri.sql','02-horeca-degisim.sql','03-distributor-urun.sql','verify.sql']:
        statement=Path('/experience/'+filename).read_text();(evidence/filename).write_text(statement);status='failed'
        try:
            result=tq(statement);(evidence/(filename+'.json')).write_text(json.dumps(result,default=str,indent=2));status='passed'
            if filename=='verify.sql' and (len(result)!=1 or result[0][0]!=2016 or any(states[k]!='passed' for k in ['months','horeca','volume','price','bi_role','no_insert'])):status='failed'
        except Exception as error:(evidence/(filename+'.error.txt')).write_text(str(error))
        executions.append({'file':filename,'status':status})
    (evidence/'report-details.json').write_text(json.dumps(details,indent=2))
    result={'schemaVersion':1,'architecture':profile['architecture'],'architectureVersion':profile['architectureVersion'],'scenario':profile['scenario'],'generatedAt':datetime.now(timezone.utc).isoformat(),'namespace':os.environ['NAMESPACE'],'executions':executions,'observation':{'checks':[{'id':k,'status':v} for k,v in states.items()],'metrics':metrics}}
    (out/'sonuc.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps({state:sum(c==state for c in states.values()) for state in ['passed','failed','not_tested']}));return 0

if __name__=='__main__':raise SystemExit(main())

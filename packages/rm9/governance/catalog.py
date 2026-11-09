import base64,json,os,re,sys,time,traceback
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.parse import quote,urlencode
from urllib.error import HTTPError
import psycopg

mode=sys.argv[1] if len(sys.argv)>1 else 'verify'
out=Path('/artifacts');policy=json.loads(Path('/catalog/metric-contract.json').read_text())
base='http://openmetadata:8585/api/v1/';access_token=None
keys=['om_catalog','om_owner','om_glossary','om_lineage','om_metric','om_quality','om_product']
states=dict.fromkeys(keys,'not_tested');evidence={'mode':mode,'checks':[]}
def save():
    evidence['checks']=[{'id':k,'status':v} for k,v in states.items()]
    (out/'governance-checks.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2))
    (out/'governance-status.txt').write_text('\n'.join(states.values())+'\n')
def api(path,method='GET',data=None,auth=True,patch=False):
    headers={'Content-Type':'application/json-patch+json' if patch else 'application/json'}
    if auth and access_token:headers['Authorization']='Bearer '+access_token
    request=Request(base+path,data=None if data is None else json.dumps(data).encode(),headers=headers,method=method)
    try:
        with urlopen(request,timeout=90) as response:
            raw=response.read()
            if not raw:return {}
            try:return json.loads(raw)
            except json.JSONDecodeError:return {'message':raw.decode(errors='replace')}
    except HTTPError as error:
        detail=error.read().decode(errors='replace')[:1500]
        raise RuntimeError(f'OpenMetadata {method} {path}: HTTP {error.code} {detail}') from None
def named(kind,name,fields=''):
    return api(kind+'/name/'+quote(name,safe='')+('?' + urlencode({'fields':fields}) if fields else ''))
def put(kind,payload):return api(kind,'PUT',payload)
def ref(entity,kind):return {'id':entity['id'],'type':kind}
def normalize(s):return re.sub(r'\s+','',s or '').lower()
def login(password):
    value=api('users/login','POST',{'email':'admin@open-metadata.org','password':base64.b64encode(password.encode()).decode()},auth=False)
    return value['accessToken']
def owned(entity,owner):return any(v.get('id')==owner for v in entity.get('owners',[]) or [])
def tag(term):return {'tagFQN':policy['glossary']+'.'+term,'source':'Glossary','labelType':'Manual','state':'Confirmed'}
def connect():return psycopg.connect(host=os.environ['PGHOST'],dbname=os.environ['PGDATABASE'],user=os.environ['PGUSER'],password=os.environ['PGPASSWORD'],connect_timeout=15)
from trino.dbapi import connect as trino_connect
def tq(statement):
    conn=trino_connect(host='trino',port=8080,user='rm9_catalog',catalog='models',schema='dwh');cursor=conn.cursor()
    try:cursor.execute(statement);return cursor.fetchall()
    finally:cursor.close();conn.close()
def pg(host,dbname):return psycopg.connect(host=host,dbname=dbname,user='rm9_bi',password=os.environ['PGPASSWORD'],connect_timeout=15)
specs={'sales':('RM9Sales','komtas_rm9','postgres'),'reference':('RM9Reference','komtas_rm9_reference','postgres-reference'),'models':('RM9Trino','models','trino')}
def database_metadata():
    result={}
    for catalog,(service,db,host) in specs.items():
        if catalog=='models':rows=tq("SELECT table_schema,table_name,column_name,data_type,ordinal_position FROM models.information_schema.columns WHERE table_schema='dwh' ORDER BY table_name,ordinal_position")
        else:
            with pg(host,db) as c:rows=c.execute("SELECT table_schema,table_name,column_name,data_type,ordinal_position FROM information_schema.columns WHERE table_schema='raw' ORDER BY table_name,ordinal_position").fetchall()
        for schema,name,column,kind,ordinal in rows:
            entry=result.setdefault((catalog,schema,name),{'name':name,'databaseSchema':service+'.'+db+'.'+schema,'tableType':'View' if catalog=='models' else 'Regular','columns':[]})
            dtype='DATE' if kind=='date' else 'BIGINT' if kind=='bigint' else 'INT' if kind in ('integer','smallint') else 'NUMERIC' if kind.startswith(('numeric','decimal')) else 'TIMESTAMP' if kind.startswith('timestamp') else 'STRING'
            entry['columns'].append({'name':column,'dataType':dtype,'dataTypeDisplay':kind,'ordinalPosition':ordinal})
    return result
def quality(table,owner):
    count=tq('SELECT count(*) FROM models.dwh.fact_sales')[0][0]
    case=put('dataQuality/testCases',{'name':'rm9_federated_row_count','description':'Actual Trino SQL row count across the two PostgreSQL sources; not a scheduled profiler.','testDefinition':'tableRowCountToEqual','entityLink':'<#E::table::'+table['fullyQualifiedName']+'>','parameterValues':[{'name':'value','value':'2016'}],'owners':[ref(owner,'team')]})
    result={'timestamp':int(time.time()*1000),'testCaseStatus':'Success' if count==2016 else 'Failed','result':'Federated Trino row count = '+str(count),'testResultValue':[{'name':'rowCount','value':str(count)}]}
    api('dataQuality/testCases/testCaseResults/'+quote(case['fullyQualifiedName'],safe=''),'POST',result)
    fetched=named('dataQuality/testCases',case['fullyQualifiedName'],'testCaseResult').get('testCaseResult',{});evidence['quality']={'count':count,'testCaseFQN':case['fullyQualifiedName'],'result':fetched}
    return count==2016 and fetched.get('testCaseStatus')=='Success'
try:
    if mode in ('sync','verify'):
        for name in ['governance-checks.json','governance-status.txt']:(out/name).unlink(missing_ok=True)
        save()
    desired=os.environ['OM_ADMIN_PASSWORD']
    try:access_token=login(desired)
    except RuntimeError:
        if mode!='sync':raise
        access_token=login('admin');api('users/changePassword','PUT',{'username':'admin','oldPassword':'admin','newPassword':desired,'confirmPassword':desired,'requestType':'SELF'});access_token=login(desired)
    owner=put('teams',{'name':policy['ownerTeam'],'displayName':'Beverage Sales Stewards','teamType':'Group','description':'Reference stewardship metadata, not an automated approval workflow.'}) if mode in ('sync','restore') else named('teams',policy['ownerTeam'])
    owner_ref=ref(owner,'team');actual=database_metadata();table_fqn='RM9Trino.models.dwh.v_sales_detail'
    if mode in ('sync','restore'):
        put('domains',{'name':policy['domain'],'domainType':'Source-aligned','description':'Federated beverage sales.','owners':[owner_ref]})
        put('glossaries',{'name':policy['glossary'],'description':'Reference business definitions.','owners':[owner_ref]})
        for m in policy['metrics']:put('glossaryTerms',{'name':m['term'],'glossary':policy['glossary'],'description':m['description'],'owners':[owner_ref]})
        for catalog,(service,db,host) in specs.items():
            put('services/databaseServices',{'name':service,'serviceType':'Trino' if catalog=='models' else 'Postgres','description':'Explicit lab API metadata push; no native scheduled ingestion.','owners':[owner_ref]})
            put('databases',{'name':db,'service':service,'owners':[owner_ref]})
            put('databaseSchemas',{'name':'dwh' if catalog=='models' else 'raw','database':service+'.'+db,'owners':[owner_ref]})
        registered={}
        for key,payload in actual.items():
            payload.update(owners=[owner_ref],domains=[policy['domain']])
            if key==('models','dwh','v_sales_detail'):payload.update(description='dbt view across two PostgreSQL sources; Cube REST is the output interface.',tags=[tag(m['term']) for m in policy['metrics']])
            registered[key]=put('tables',payload)
        manifest=json.loads((out/'manifest.json').read_text());entities={}
        for node in list(manifest.get('nodes',{}).values())+list(manifest.get('sources',{}).values()):
            key=(node.get('database'),node.get('schema'),node.get('alias') or node.get('identifier') or node.get('name'))
            if key in registered:entities[node['unique_id']]=registered[key]
        edges=[]
        for node in manifest.get('nodes',{}).values():
            target=entities.get(node['unique_id'])
            if not target:continue
            for dependency in node.get('depends_on',{}).get('nodes',[]):
                source=entities.get(dependency)
                if source:api('lineage','PUT',{'edge':{'fromEntity':ref(source,'table'),'toEntity':ref(target,'table'),'lineageDetails':{'description':'Actual dbt manifest dependency across catalogs.','source':'DbtLineage'}}});edges.append([source['fullyQualifiedName'],target['fullyQualifiedName']])
        (out/'catalog-lineage-map.json').write_text(json.dumps(edges,indent=2));table=registered['models','dwh','v_sales_detail']
        metrics=[put('metrics',{'name':m['name'],'description':m['description'],'metricType':m['type'],'metricExpression':{'language':'SQL','code':m['sql']},'owners':[owner_ref],'tags':[tag(m['term'])],'domains':[policy['domain']],'assets':[ref(table,'table')]}) for m in policy['metrics']]
        product=put('dataProducts',{'name':policy['product'],'description':'Owned federated view and metric metadata. No Marketplace, SLO enforcement or approval automation.','domains':[policy['domain']],'owners':[owner_ref],'assets':[ref(table,'table')]+[ref(v,'metric') for v in metrics]})
        api('dataProducts/'+quote(policy['product'],safe='')+'/assets/add','PUT',{'assets':[ref(table,'table')]+[ref(v,'metric') for v in metrics]})
    if mode=='fault':
        entity=named('metrics','NetRevenue','owners');api('metrics/'+entity['id'],'PATCH',[{'op':'replace','path':'/owners','value':[]}],patch=True);print('Local metric owner removed; data and models unchanged.');sys.exit(0)
    if mode=='restore':print('Governance metadata restored.');sys.exit(0)
    table=named('tables',table_fqn,'owners,tags,columns,dataProducts');fact=named('tables','RM9Trino.models.dwh.fact_sales','owners')
    states['om_catalog']='passed' if {(c['name'],c['dataType']) for c in table.get('columns',[])}=={(c['name'],c['dataType']) for c in actual['models','dwh','v_sales_detail']['columns']} else 'failed'
    metrics=[named('metrics',m['name'],'owners,tags,assets,dataProducts') for m in policy['metrics']]
    states['om_owner']='passed' if owned(table,owner['id']) and all(owned(v,owner['id']) for v in metrics) else 'failed'
    terms=[named('glossaryTerms',policy['glossary']+'.'+m['term']) for m in policy['metrics']]
    states['om_glossary']='passed' if all(v.get('description')==m['description'] and any(t.get('tagFQN')==policy['glossary']+'.'+m['term'] for t in metric.get('tags',[]) or []) for m,v,metric in zip(policy['metrics'],terms,metrics)) else 'failed'
    lineage=api('lineage/table/'+table['id']+'?upstreamDepth=3&downstreamDepth=1');upstream=lineage.get('upstreamEdges',[])
    sales=named('tables','RM9Sales.komtas_rm9.raw.sales_line');reference=named('tables','RM9Reference.komtas_rm9_reference.raw.dim_product')
    sources={e.get('fromEntity') for e in upstream};states['om_lineage']='passed' if sales['id'] in sources and reference['id'] in sources else 'failed'
    model=Path('/cube-model/Sales.js').read_text();checks=[]
    for m,metric in zip(policy['metrics'],metrics):
        match=re.search(re.escape(m['cubeName'])+r':\s*\{sql:\s*`([^`]+)`',model);checks.append(bool(match) and normalize(match[1])==normalize(m['cubeSql']) and normalize(metric.get('metricExpression',{}).get('code'))==normalize(m['sql']) and any(v.get('id')==table['id'] for v in metric.get('assets',[]) or []))
    states['om_metric']='passed' if all(checks) else 'failed';states['om_quality']='passed' if quality(fact,owner) else 'failed'
    product=named('dataProducts',policy['product'],'owners,domains');states['om_product']='passed' if owned(product,owner['id']) and all(any(v.get('id')==product['id'] for v in entity.get('dataProducts',[]) or []) for entity in [table]+metrics) else 'failed'
    evidence.update(catalog={'tableFQN':table_fqn,'tableId':table['id'],'tableCount':len(actual)},metrics=metrics,terms=terms,lineage=lineage,product=product)
except SystemExit:raise
except Exception as error:states['om_catalog']='failed';evidence['error']=str(error);print(type(error).__name__+': '+str(error),file=sys.stderr)
finally:
    if mode in ('sync','verify'):save()
print(json.dumps(states));sys.exit(0 if mode=='verify' or all(v=='passed' for v in states.values()) else 1)

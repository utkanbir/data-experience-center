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
def database_metadata():
    with connect() as connection:
        rows=connection.execute("SELECT n.nspname,c.relname,c.relkind,a.attname,format_type(a.atttypid,a.atttypmod),a.attnum FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_attribute a ON a.attrelid=c.oid WHERE n.nspname IN ('raw','dwh') AND c.relkind IN ('r','v') AND a.attnum>0 AND NOT a.attisdropped ORDER BY n.nspname,c.relname,a.attnum").fetchall()
    tables={}
    for schema,name,kind,column,datatype,ordinal in rows:
        k=(schema,name);entry=tables.setdefault(k,{'name':name,'databaseSchema':policy['service']+'.komtas_rm10.'+schema,'tableType':'View' if kind=='v' else 'Regular','columns':[]})
        dtype='TIMESTAMP' if datatype.startswith('timestamp') else 'DATE' if datatype=='date' else 'BIGINT' if datatype=='bigint' else 'INT' if datatype in ('integer','smallint') else 'NUMERIC' if datatype.startswith('numeric') else 'BOOLEAN' if datatype=='boolean' else 'STRING'
        entry['columns'].append({'name':column,'dataType':dtype,'dataTypeDisplay':datatype,'ordinalPosition':ordinal})
    return tables
def quality(table,owner):
    with connect() as connection:count=connection.execute('SELECT count(*) FROM dwh.fact_sales').fetchone()[0]
    case=put('dataQuality/testCases',{'name':'rm10_fact_row_count','description':'External lab SQL result: actual fact row count compared with fixed 2016-row reference. Not a scheduled OpenMetadata profiler.','testDefinition':'tableRowCountToEqual','entityLink':'<#E::table::'+table['fullyQualifiedName']+'>','parameterValues':[{'name':'value','value':'2016'}],'owners':[ref(owner,'team')]})
    result={'timestamp':int(time.time()*1000),'testCaseStatus':'Success' if count==2016 else 'Failed','result':'Lab SQL SELECT count(*) = '+str(count),'testResultValue':[{'name':'rowCount','value':str(count)}]}
    api('dataQuality/testCases/testCaseResults/'+quote(case['fullyQualifiedName'],safe=''),'POST',result)
    fetched=named('dataQuality/testCases',case['fullyQualifiedName'],'testCaseResult').get('testCaseResult',{})
    evidence['quality']={'count':count,'testCaseFQN':case['fullyQualifiedName'],'result':fetched}
    return count==2016 and fetched.get('testCaseStatus')=='Success'

try:
    if mode in ('sync','verify'):
        for name in ['governance-checks.json','governance-status.txt']:(out/name).unlink(missing_ok=True)
        save()
    desired=os.environ['OM_ADMIN_PASSWORD']
    try:access_token=login(desired)
    except RuntimeError:
        if mode!='sync':raise
        access_token=login('admin')
        api('users/changePassword','PUT',{'username':'admin','oldPassword':'admin','newPassword':desired,'confirmPassword':desired,'requestType':'SELF'})
        access_token=login(desired)
    owner=put('teams',{'name':policy['ownerTeam'],'displayName':'Beverage Sales Stewards','teamType':'Group','description':'Demo stewardship team; owner registration is not a completed approval workflow.'}) if mode in ('sync','restore') else named('teams',policy['ownerTeam'])
    owner_ref=ref(owner,'team')
    dbname=policy['service']+'.komtas_rm10'
    table_fqn=dbname+'.dwh.v_sales_detail'
    if mode in ('sync','restore'):
        put('services/databaseServices',{'name':policy['service'],'serviceType':'Postgres','description':'Metadata pushed from PostgreSQL catalog and dbt manifest by this explicit lab Job; no scheduled native connector or Airflow is installed.','owners':[owner_ref]})
        put('databases',{'name':'komtas_rm10','service':policy['service'],'owners':[owner_ref]})
        put('domains',{'name':policy['domain'],'domainType':'Source-aligned','description':'Beverage sales laboratory domain.','owners':[owner_ref]})
        put('glossaries',{'name':policy['glossary'],'description':'Shared business definitions for the reference scenario.','owners':[owner_ref]})
        for m in policy['metrics']:put('glossaryTerms',{'name':m['term'],'glossary':policy['glossary'],'description':m['description'],'owners':[owner_ref]})
        for schema in ['raw','dwh']:put('databaseSchemas',{'name':schema,'database':dbname,'owners':[owner_ref]})
        tables=database_metadata();registered={}
        for key,payload in tables.items():
            payload.update(owners=[owner_ref],domains=[policy['domain']])
            if key==('dwh','v_sales_detail'):payload.update(description='Semantic consumption view. Cube REST /cubejs-api/v1/load is the demo output interface.',tags=[tag(m['term']) for m in policy['metrics']])
            registered[key]=put('tables',payload)
        manifest=json.loads((out/'manifest.json').read_text());entities={}
        for node in list(manifest.get('nodes',{}).values())+list(manifest.get('sources',{}).values()):
            k=(node.get('schema'),node.get('alias') or node.get('identifier') or node.get('name'))
            if k in registered:entities[node['unique_id']]=registered[k]
        edges=[]
        for node in manifest.get('nodes',{}).values():
            target=entities.get(node['unique_id'])
            if not target:continue
            for dependency in node.get('depends_on',{}).get('nodes',[]):
                source=entities.get(dependency)
                if source:
                    api('lineage','PUT',{'edge':{'fromEntity':ref(source,'table'),'toEntity':ref(target,'table'),'lineageDetails':{'description':'Derived from dbt manifest dependency; pushed by RM10 lab Job.','source':'DbtLineage'}}})
                    edges.append([source['fullyQualifiedName'],target['fullyQualifiedName']])
        (out/'catalog-lineage-map.json').write_text(json.dumps(edges,indent=2))
        table=registered['dwh','v_sales_detail']
        metrics=[]
        for m in policy['metrics']:
            metrics.append(put('metrics',{'name':m['name'],'description':m['description'],'metricType':m['type'],'metricExpression':{'language':'SQL','code':m['sql']},'owners':[owner_ref],'tags':[tag(m['term'])],'domains':[policy['domain']],'assets':[ref(table,'table')]}))
        product=put('dataProducts',{'name':policy['product'],'description':'Demo data product registration: owned sales view + three metric definitions + Cube REST output interface. Contract/SLO enforcement, access approval and lifecycle automation are not implemented.','domains':[policy['domain']],'owners':[owner_ref],'assets':[ref(table,'table')]+[ref(v,'metric') for v in metrics]})
        api('dataProducts/'+quote(policy['product'],safe='')+'/assets/add','PUT',{'assets':[ref(table,'table')]+[ref(v,'metric') for v in metrics]})
    if mode=='fault':
        entity=named('metrics','NetRevenue','owners')
        api('metrics/'+entity['id'],'PATCH',[{'op':'replace','path':'/owners','value':[]}],patch=True)
        print('Injected governance fault: NetRevenue owners cleared. Data and Cube model unchanged.');sys.exit(0)
    if mode=='restore':print('Governance metadata restored.');sys.exit(0)
    table=named('tables',table_fqn,'owners,tags,columns,dataProducts')
    fact=named('tables',dbname+'.dwh.fact_sales','owners')
    actual_tables=database_metadata()
    states['om_catalog']='passed' if {(c['name'],c['dataType']) for c in table.get('columns',[])}=={(c['name'],c['dataType']) for c in actual_tables['dwh','v_sales_detail']['columns']} and table.get('fullyQualifiedName')==table_fqn else 'failed'
    metrics=[named('metrics',m['name'],'owners,tags,assets,dataProducts') for m in policy['metrics']]
    states['om_owner']='passed' if owned(table,owner['id']) and all(owned(v,owner['id']) for v in metrics) else 'failed'
    terms=[named('glossaryTerms',policy['glossary']+'.'+m['term']) for m in policy['metrics']]
    states['om_glossary']='passed' if all(v.get('description')==m['description'] and any(t.get('tagFQN')==policy['glossary']+'.'+m['term'] for t in metric.get('tags',[]) or []) for m,v,metric in zip(policy['metrics'],terms,metrics)) else 'failed'
    lineage=api('lineage/table/'+table['id']+'?upstreamDepth=3&downstreamDepth=1')
    upstream=lineage.get('upstreamEdges',[])
    states['om_lineage']='passed' if any(v.get('fromEntity')==fact['id'] and v.get('toEntity')==table['id'] for v in upstream) else 'failed'
    model=Path('/cube-model/Sales.js').read_text()
    checks=[]
    for m,metric in zip(policy['metrics'],metrics):
        match=re.search(re.escape(m['cubeName'])+r':\s*\{sql:\s*`([^`]+)`',model)
        checks.append(bool(match) and normalize(match[1])==normalize(m['cubeSql']) and normalize(metric.get('metricExpression',{}).get('code'))==normalize(m['sql']) and any(v.get('id')==table['id'] for v in metric.get('assets',[]) or []))
    states['om_metric']='passed' if all(checks) else 'failed'
    states['om_quality']='passed' if quality(fact,owner) else 'failed'
    product=named('dataProducts',policy['product'],'owners,domains')
    states['om_product']='passed' if owned(product,owner['id']) and all(any(v.get('id')==product['id'] for v in entity.get('dataProducts',[]) or []) for entity in [table]+metrics) else 'failed'
    evidence.update(catalog={'tableFQN':table_fqn,'tableId':table['id'],'columnCount':len(table.get('columns',[])),'tableCount':len(actual_tables)},metrics=metrics,terms=terms,lineage=lineage,product=product)
except SystemExit:raise
except Exception as error:
    evidence['error']=str(error)
    print(type(error).__name__+': '+str(error),file=sys.stderr)
finally:
    if mode in ('sync','verify'):save()
print(json.dumps(states));sys.exit(0 if all(v=='passed' for v in states.values()) else 1)

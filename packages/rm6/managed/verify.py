import csv,json,os,sys
from pathlib import Path
from client import Client,ManagedError,read_reference,reference_match
out=Path('/artifacts');out.mkdir(exist_ok=True)
keys=['sl_metadata','sl_query','sl_sql','sl_match','sl_powerbi'];states=dict.fromkeys(keys,'not_tested')
evidence={'source':'managed_dbt_api','remoteConfigured':False,'powerBiEvidence':'manual_csv_export; not an automated connector execution','checks':[]}
def save():
    evidence['checks']=[{'id':k,'status':v} for k,v in states.items()]
    (out/'managed-checks.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2))
    (out/'managed-status.txt').write_text('\n'.join(states.values())+'\n')
for name in ['managed-checks.json','managed-status.txt','managed-results.json','managed-sql.txt','powerbi-results.json']:(out/name).unlink(missing_ok=True)
save()
token=os.environ.get('DBT_SL_TOKEN','');host=os.environ.get('DBT_SL_HOST','');env=os.environ.get('DBT_SL_ENVIRONMENT_ID','')
if not token or not host or not env:
    evidence['reason']='External dbt Semantic Layer credentials are not configured. Local dbt is not used as a substitute.'
    save();print('Managed checks: not_tested. Configure the real external service with Set-DbtConnection.');sys.exit(0)
try:
    evidence['remoteConfigured']=True
    client=Client(host,env,token);evidence['host']=client.url.split('/')[2];evidence['environmentId']=client.env
    names=client.metrics();definition=json.loads(Path('/managed/query.json').read_text())
    states['sl_metadata']='passed' if set(definition['metrics']).issubset(names) else 'failed'
    if states['sl_metadata']=='failed':raise ManagedError('The three expected metrics are missing in the managed deployment environment.')
    states['sl_query']='failed'
    result=client.query(definition);rows=result['rows'];states['sl_query']='passed' if len(rows)==6 else 'failed'
    (out/'managed-results.json').write_text(json.dumps(rows,indent=2));(out/'managed-sql.txt').write_text(result['sql'])
    states['sl_sql']='passed' if result['sql'].strip() else 'failed'
    reference=read_reference('/managed/expected-results.csv');states['sl_match']='passed' if reference_match(rows,reference) else 'failed'
    evidence['queryId']=result['queryId'];evidence['rowCount']=len(rows)
    export=Path('/powerbi/result.csv')
    if export.exists():
        with export.open(newline='',encoding='utf-8-sig') as stream:bi=list(csv.DictReader(stream))
        states['sl_powerbi']='passed' if reference_match(bi,rows) and reference_match(bi,reference) else 'failed'
        (out/'powerbi-results.json').write_text(json.dumps(bi,indent=2))
except Exception as error:
    evidence['error']=str(error).replace(token,'[redacted]')
    if states['sl_metadata']=='not_tested':states['sl_metadata']='failed'
    print(evidence['error'],file=sys.stderr)
finally:save()
print(json.dumps(states));sys.exit(1 if 'failed' in states.values() else 0)

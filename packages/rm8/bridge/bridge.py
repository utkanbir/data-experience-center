import base64,hashlib,json,os,re,sys
from datetime import datetime,timezone
from pathlib import Path
from urllib.request import Request,build_opener
from urllib.parse import quote,urlencode
sys.path.insert(0,'/cdgc')
from client import Client,GovernanceError,NoRedirect,pointer

KEYS=['dual_identity','dual_definition','dual_owner','dual_revision']

def digest(text):return hashlib.sha256(text.encode()).hexdigest()
def plain(text):
    from html import unescape
    return re.sub(r'\s+',' ',unescape(re.sub(r'<[^>]*>',' ',str(text or '')))).strip().casefold()
def sql(text):return re.sub(r'\s+','',text or '').lower()

def validate_copy_source(settings,assets):
    publication=settings.get('publication',{})
    if not publication.get('pointer') or not publication.get('expected'):raise GovernanceError('Configure the source lifecycle state before copying business definitions.')
    for cfg in settings['metrics']:
        asset=assets.get(cfg['assetId'],{});description=plain(asset.get('summary',{}).get('core.description'));terms=cfg.get('descriptionContains',[])
        if pointer(asset,publication['pointer'])!=publication['expected'] or not isinstance(terms,list) or not terms or not all(isinstance(term,str) and term.strip() and plain(term) in description for term in terms):raise GovernanceError('Source lifecycle or expected business definition differs. Review CDGC before copying to the local catalog; this is not an approval action.')

def evaluate(mapping,settings,assets,objects,team_id,contract,model,snapshot=None):
    states=dict.fromkeys(KEYS,'not_tested');records=[];configured={m['metricId']:m for m in settings['metrics']}
    if len(mapping['metrics'])!=3 or len({m['metricId'] for m in mapping['metrics']})!=3 or set(configured)!={m['metricId'] for m in mapping['metrics']}:raise GovernanceError('Map exactly three unique metric identities.')
    for m in mapping['metrics']:
        cfg=configured[m['metricId']];asset=assets.get(cfg['assetId']);pair=objects.get(m['metricId'],{});metric=pair.get('metric',{});term=pair.get('term',{});local=next((v for v in contract['metrics'] if 'Sales.'+v['cubeName']==m['metricId']),None)
        identity=bool(asset and metric.get('id') and term.get('id') and local and metric.get('name')==m['omMetricName'] and term.get('fullyQualifiedName')==m['omTermFqn'] and plain(asset.get('summary',{}).get('core.name'))==plain(cfg['expectedName']) and local['cubeName']+':' in model and any(t.get('tagFQN')==m['omTermFqn'] for t in metric.get('tags',[]) or []))
        description=asset.get('summary',{}).get('core.description','') if asset else ''
        found=re.search(re.escape(local['cubeName'])+r':\s*\{sql:\s*`([^`]+)`',model) if local else None
        definition=bool(identity and plain(description) and plain(metric.get('description'))==plain(description) and plain(term.get('description'))==plain(description) and found and sql(found[1])==sql(local['cubeSql']) and sql(metric.get('metricExpression',{}).get('code'))==sql(local['sql']))
        owner=settings.get('owner',{});owner_configured=bool(owner.get('expectedId') and owner.get('expectedRoleId') and team_id)
        owned=owner_configured and pointer(asset,owner['idPointer'])==owner['expectedId'] and pointer(asset,owner['rolePointer'])==owner['expectedRoleId'] and all(any(o.get('id')==team_id for o in v.get('owners',[]) or []) for v in [metric,term])
        records.append({'metricId':m['metricId'],'assetId':cfg['assetId'],'assetModifiedOn':asset.get('systemAttributes',{}).get('core.modifiedOn') if asset else None,'omMetricId':metric.get('id'),'omTermId':term.get('id'),'description':description,'descriptionSha256':digest(plain(description)),'ownerId':owner.get('expectedId'),'ownerRoleId':owner.get('expectedRoleId'),'omTeamId':team_id,'identity':identity,'definition':definition,'owner':bool(owned),'ownerConfigured':owner_configured})
    states['dual_identity']='passed' if all(v['identity'] for v in records) else 'failed'
    states['dual_definition']='passed' if all(v['definition'] for v in records) else 'failed'
    if all(v['ownerConfigured'] for v in records):states['dual_owner']='passed' if all(v['owner'] for v in records) else 'failed'
    if snapshot is not None:
        old=snapshot.get('records',[]) if isinstance(snapshot,dict) else []
        valid=isinstance(snapshot,dict) and snapshot.get('source')=='live_cdgc_to_local_om' and len(old)==3 and len({v.get('metricId') for v in old})==3
        for row in records:
            previous=next((v for v in old if v.get('metricId')==row['metricId']),{})
            valid=valid and isinstance(row['assetModifiedOn'],int) and row['assetModifiedOn']>0 and all(previous.get(k)==row[k] for k in ['assetId','assetModifiedOn','omMetricId','omTermId','descriptionSha256','ownerId','ownerRoleId','omTeamId'])
        states['dual_revision']='passed' if valid else 'failed'
    return states,records

class OpenMetadata:
    def __init__(self,password):
        self.token=None
        response=self.api('users/login','POST',{'email':'admin@open-metadata.org','password':base64.b64encode(password.encode()).decode()})
        self.token=response['accessToken']
    def api(self,path,method='GET',data=None):
        headers={'Content-Type':'application/json-patch+json' if method=='PATCH' else 'application/json'}
        if self.token:headers['Authorization']='Bearer '+self.token
        req=Request('http://openmetadata:8585/api/v1/'+path,data=None if data is None else json.dumps(data).encode(),headers=headers,method=method)
        try:
            with build_opener(NoRedirect()).open(req,timeout=40) as response:raw=response.read(8_000_001)
            if len(raw)>8_000_000:raise GovernanceError('OpenMetadata response limit exceeded.')
            return json.loads(raw) if raw else {}
        except Exception:raise GovernanceError('OpenMetadata request failed; check local catalog readiness and credentials.') from None
    def named(self,kind,name,fields=''):
        return self.api(kind+'/name/'+quote(name,safe='')+('?' + urlencode({'fields':fields}) if fields else ''))
    def describe(self,kind,entity,description,team_id):
        self.api(kind+'/'+entity['id'],'PATCH',[{'op':'replace' if 'description' in entity else 'add','path':'/description','value':description},{'op':'replace' if 'owners' in entity else 'add','path':'/owners','value':[{'id':team_id,'type':'team'}]}])

def main():
    out=Path('/artifacts');mode=sys.argv[1] if len(sys.argv)>1 else 'verify';states=dict.fromkeys(KEYS,'not_tested');evidence={'source':'live_cdgc_and_local_openmetadata','mode':mode,'externalWritePerformed':False,'automaticApproval':False,'observedAt':datetime.now(timezone.utc).isoformat()}
    def save():
        evidence['checks']=[{'id':k,'status':states[k]} for k in KEYS];(out/'dual-checks.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2));(out/'dual-status.txt').write_text('\n'.join(states.values())+'\n')
    if mode=='verify':
        for name in ['dual-status.txt','dual-checks.json']:(out/name).unlink(missing_ok=True)
        save()
    token=os.environ.get('INFA_TOKEN','');host=os.environ.get('INFA_HOST','');org=os.environ.get('INFA_ORG','')
    try:
        settings=json.loads(Path('/cdgc/settings.json').read_text());mapping=json.loads(Path('/bridge/settings.json').read_text());contract=json.loads(Path('/catalog/metric-contract.json').read_text());model=Path('/cube-model/Sales.js').read_text()
        if not token or not host or not org or len(settings['metrics'])!=3 or any(not m.get('assetId') for m in settings['metrics']):
            evidence['reason']='External CDGC connection or metric identities missing. Local OM registration does not prove cross-catalog integration.'
            if mode=='verify':save();print(evidence['reason']);return 0
            raise GovernanceError('Provide external CDGC credentials and all three real metric asset IDs before explicit synchronization.')
        assets=Client(host,org,token).assets([m['assetId'] for m in settings['metrics']]);om=OpenMetadata(os.environ['OM_ADMIN_PASSWORD']);team=om.named('teams',mapping['ownerTeam']);team_id=team['id'];objects={}
        def fetch():
            for m in mapping['metrics']:objects[m['metricId']]={'metric':om.named('metrics',m['omMetricName'],'owners,tags,assets'),'term':om.named('glossaryTerms',m['omTermFqn'],'owners')}
        fetch();snapshot_path=out/'business-sync.json';snapshot=json.loads(snapshot_path.read_text()) if snapshot_path.exists() else None
        states,records=evaluate(mapping,settings,assets,objects,team_id,contract,model,snapshot)
        if mode=='sync':
            owner=settings.get('owner',{})
            if states['dual_identity']!='passed' or not owner.get('expectedId') or not owner.get('expectedRoleId'):raise GovernanceError('Review identities and explicit CDGC owner/role to OM team mapping before synchronization.')
            validate_copy_source(settings,assets)
            for row in records:
                asset=assets[row['assetId']]
                if pointer(asset,owner['idPointer'])!=owner['expectedId'] or pointer(asset,owner['rolePointer'])!=owner['expectedRoleId'] or not row['description'].strip() or not isinstance(row['assetModifiedOn'],int):raise GovernanceError('Actual CDGC owner/role, business description or source revision is missing or differs from configured mapping.')
            for row in records:
                pair=objects[row['metricId']];om.describe('metrics',pair['metric'],row['description'],team_id);om.describe('glossaryTerms',pair['term'],row['description'],team_id)
            fetch();states,records=evaluate(mapping,settings,assets,objects,team_id,contract,model)
            if any(states[k]!='passed' for k in ['dual_identity','dual_definition','dual_owner']):raise GovernanceError('Local copy verification failed. No successful synchronization checkpoint was written.')
            snapshot={'source':'live_cdgc_to_local_om','syncedAt':datetime.now(timezone.utc).isoformat(),'direction':'CDGC -> lab OpenMetadata only','records':[{k:v for k,v in row.items() if k not in ['identity','definition','owner','ownerConfigured']} for row in records]}
            temp=out/'business-sync.tmp';temp.write_text(json.dumps(snapshot,ensure_ascii=False,indent=2));temp.replace(snapshot_path);print('Actual CDGC definitions copied to local OM. No external write or approval was performed.');return 0
        evidence['records']=[{k:v for k,v in row.items() if k!='description'} for row in records]
        evidence['mappingNotice']='Owner mapping is user-declared. This is version/definition consistency, not automatic approval, enterprise identity reconciliation or continuous synchronization.'
    except Exception as error:
        states['dual_identity']='failed';evidence['error']=str(error).replace(token,'[redacted]') if token else str(error);print(evidence['error'],file=sys.stderr)
        if mode=='sync':return 1
    save();return 0

if __name__=='__main__':sys.exit(main())

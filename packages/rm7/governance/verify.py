import json,os,re,hashlib,sys
from datetime import datetime,timezone,timedelta
from pathlib import Path
from html import unescape
from client import Client,GovernanceError,pointer

KEYS=['cdgc_assets','cdgc_definition','cdgc_owner','cdgc_published','cdgc_binding','cdgc_product','cdgc_approval']
def plain(v):return re.sub(r'\s+',' ',unescape(re.sub(r'<[^>]*>',' ',str(v or '')))).strip().casefold()
def assess(settings,assets,cube_model,approval=None,now=None):
    states=dict.fromkeys(KEYS,'not_tested');details={};metrics=settings['metrics'];rows=[assets.get(m['assetId']) for m in metrics]
    states['cdgc_assets']='passed' if all(row and plain(row.get('summary',{}).get('core.name'))==plain(m['expectedName']) for m,row in zip(metrics,rows)) else 'failed'
    if states['cdgc_assets']!='passed':return states,{'reason':'Expected metric IDs/names were not all returned. No local catalog substitute was used.'}
    definitions=all(isinstance(m.get('descriptionContains'),list) and m['descriptionContains'] and all(isinstance(term,str) and term.strip() and plain(term) in plain(row.get('summary',{}).get('core.description')) for term in m['descriptionContains']) for m,row in zip(metrics,rows))
    states['cdgc_definition']='passed' if definitions else 'failed'
    owner=settings.get('owner',{})
    if owner.get('expectedId') and owner.get('expectedRoleId'):
        states['cdgc_owner']='passed' if all(pointer(row,owner['idPointer'])==owner['expectedId'] and pointer(row,owner['rolePointer'])==owner['expectedRoleId'] for row in rows) else 'failed'
    pub=settings.get('publication',{})
    if pub.get('pointer') and pub.get('expected'):states['cdgc_published']='passed' if all(pointer(row,pub['pointer'])==pub['expected'] for row in rows) else 'failed'
    tech=settings.get('technical',{});tech_row=assets.get(tech.get('assetId'))
    if tech.get('assetId') and tech.get('expectedExternalId'):
        glossary=pointer(tech_row,tech.get('glossaryPointer','/glossary')) if tech_row else None
        term_ids={row.get('core.identity') for row in glossary if isinstance(row,dict) and row.get('core.curationStatus')=='ACCEPTED'} if isinstance(glossary,list) else set()
        states['cdgc_binding']='passed' if tech_row and tech_row.get('core.externalId')==tech['expectedExternalId'] and all(m['assetId'] in term_ids for m in metrics) and 'FROM dwh.v_sales_detail' in cube_model and all(m['metricId'].split('.')[1]+':' in cube_model for m in metrics) else 'failed'
    product=settings.get('product',{});product_row=assets.get(product.get('assetId'))
    if all(product.get(k) for k in ['assetId','expectedName','expectedClass']):
        states['cdgc_product']='passed' if product_row and plain(product_row.get('summary',{}).get('core.name'))==plain(product['expectedName']) and product_row.get('systemAttributes',{}).get('core.classType')==product['expectedClass'] and len(plain(product_row.get('summary',{}).get('core.description')))>=20 else 'failed'
    if approval is not None:
        now=now or datetime.now(timezone.utc);records=approval.get('records',[]) if isinstance(approval,dict) else [];valid=isinstance(approval,dict) and approval.get('source')=='manual_workflow_record' and isinstance(records,list) and len(records)==3
        ids=[rec.get('assetId') for rec in records if isinstance(rec,dict)] if isinstance(records,list) else []
        valid=valid and all(isinstance(v,str) for v in ids) and len(set(ids))==3 and set(ids)=={m['assetId'] for m in metrics}
        for record in records if valid else []:
            try:
                asset=assets[record['assetId']];version=asset['systemAttributes']['core.modifiedOn'];observed=datetime.fromisoformat(record['observedAt'].replace('Z','+00:00'))
                valid=valid and isinstance(version,int) and version>0 and record['assetModifiedOn']==version and observed.tzinfo is not None and datetime.fromtimestamp(version/1000,timezone.utc)<=observed<=now+timedelta(minutes=5) and record.get('decision')=='approved' and bool(str(record.get('ticketId','')).strip()) and bool(str(record.get('reviewer','')).strip())
            except (KeyError,ValueError,TypeError,OverflowError):valid=False
        states['cdgc_approval']='passed' if valid and states['cdgc_published']=='passed' else 'failed'
    details['approvalEvidence']='manual record consistency only; not independent workflow execution or approver-authority verification'
    details['publicationEvidence']='published state only; not proof of human approval'
    details['bindingEvidence']='declared identity/glossary binding to the local Cube view; not automatic source ingestion or complete lineage validation'
    details['assetObservations']=[{'assetId':m['assetId'],'metricId':m['metricId'],'name':row.get('summary',{}).get('core.name'),'assetModifiedOn':row.get('systemAttributes',{}).get('core.modifiedOn'),'responseSha256':hashlib.sha256(json.dumps(row,sort_keys=True).encode()).hexdigest()} for m,row in zip(metrics,rows)]
    return states,details

def main():
    out=Path('/artifacts');out.mkdir(exist_ok=True);states=dict.fromkeys(KEYS,'not_tested');evidence={'source':'live_cdgc_read_only_api','remoteRequestPerformed':False,'workflowVerified':False}
    for name in ['cdgc-checks.json','cdgc-status.txt','cdgc-approval-template.json']:(out/name).unlink(missing_ok=True)
    def save():
        evidence['checks']=[{'id':k,'status':states[k]} for k in KEYS];(out/'cdgc-checks.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2));(out/'cdgc-status.txt').write_text('\n'.join(states[k] for k in KEYS)+'\n')
    save();token=os.environ.get('INFA_TOKEN','');host=os.environ.get('INFA_HOST','');org=os.environ.get('INFA_ORG','')
    try:
        settings=json.loads(Path('/governance/settings.json').read_text());metrics=settings.get('metrics',[])
        if len(metrics)!=3 or {m.get('metricId') for m in metrics}!={'Sales.netRevenue','Sales.netLiters','Sales.averagePrice'}:raise GovernanceError('Scope must map exactly the three Cube metrics.')
        if not token or not host or not org or any(not m.get('assetId') or not m.get('expectedName') for m in metrics):
            evidence['reason']='External org/JWT or metric asset scope is missing. Local metrics are not a substitute for CDGC governance.';save();print(evidence['reason']);return 0
        ids=[m['assetId'] for m in metrics]+[settings.get(k,{}).get('assetId') for k in ['technical','product'] if settings.get(k,{}).get('assetId')]
        client=Client(host,org,token);evidence.update(remoteRequestPerformed=True,apiHost=client.origin,orgId=org,observedAt=datetime.now(timezone.utc).isoformat());assets=client.assets(ids)
        approval_path=Path('/approval/approval.json');approval=json.loads(approval_path.read_text()) if approval_path.exists() else None
        states,details=assess(settings,assets,Path('/cube-model/Sales.js').read_text(),approval);evidence.update(details)
        scaffold={'source':'manual_workflow_record','notice':'Fill only from actual workflow tickets. This file does not approve anything.','records':[{'assetId':m['assetId'],'assetModifiedOn':assets.get(m['assetId'],{}).get('systemAttributes',{}).get('core.modifiedOn'),'decision':'','ticketId':'','reviewer':'','observedAt':''} for m in metrics]}
        (out/'cdgc-approval-template.json').write_text(json.dumps(scaffold,indent=2))
    except Exception as error:
        states['cdgc_assets']='failed';evidence['error']=str(error).replace(token,'[redacted]') if token else str(error);print(evidence['error'],file=sys.stderr)
    save();print(json.dumps(states));return 0
if __name__=='__main__':sys.exit(main())

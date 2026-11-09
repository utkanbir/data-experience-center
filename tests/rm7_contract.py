import sys,json,unittest,copy
from pathlib import Path
from datetime import datetime,timezone
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'packages/rm7/governance'))
from client import Client,GovernanceError,api_origin,pointer
from verify import assess

class GovernanceContract(unittest.TestCase):
    def setUp(self):
        root=Path(__file__).resolve().parents[1]/'packages/rm7'
        self.settings=json.loads((root/'governance/settings.json').read_text(encoding='utf-8'))
        self.model=(root/'cube/schema/Sales.js').read_text()
        self.assets={}
        for i,m in enumerate(self.settings['metrics']):
            m['assetId']='term'+str(i)
            self.assets[m['assetId']]={'core.identity':m['assetId'],'summary':{'core.name':m['expectedName'],'core.description':' '.join(m['descriptionContains'])},'stakeholdership':[{'core.identity':'owner','core.role':'role'}],'selfAttributes':{'core.assetLifecycle':'Published'},'systemAttributes':{'core.modifiedOn':1700000000000}}
        self.settings['owner'].update(expectedId='owner',expectedRoleId='role')
        self.settings['technical'].update(assetId='table',expectedExternalId='postgres/dwh/v_sales_detail')
        self.assets['table']={'core.externalId':'postgres/dwh/v_sales_detail','glossary':[{'core.identity':m['assetId'],'core.curationStatus':'ACCEPTED'} for m in self.settings['metrics']]}
        self.settings['product'].update(assetId='product',expectedName='Beverage',expectedClass='Product')
        self.assets['product']={'summary':{'core.name':'Beverage','core.description':'Beverage distribution trusted metrics product'},'systemAttributes':{'core.classType':'Product'}}
        self.approval={'source':'manual_workflow_record','records':[{'assetId':m['assetId'],'assetModifiedOn':1700000000000,'decision':'approved','ticketId':'TEST-TICKET','reviewer':'contract-fixture','observedAt':'2025-01-01T00:00:00Z'} for m in self.settings['metrics']]}
    def test_explicit_contract_and_manual_record(self):
        states,details=assess(self.settings,self.assets,self.model,self.approval)
        self.assertEqual(set(states.values()),{'passed'})
        self.assertIn('not independent',details['approvalEvidence'])
    def test_published_does_not_prove_approval(self):
        states,_=assess(self.settings,self.assets,self.model)
        self.assertEqual(states['cdgc_published'],'passed');self.assertEqual(states['cdgc_approval'],'not_tested')
    def test_wrong_owner_fails_even_when_metrics_valid(self):
        self.settings['owner']['expectedId']='wrong'
        states,_=assess(self.settings,self.assets,self.model)
        self.assertEqual(states['cdgc_owner'],'failed');self.assertEqual(states['cdgc_definition'],'passed')
    def test_rejected_binding_fails(self):
        self.assets['table']['glossary'][0]['core.curationStatus']='REJECTED'
        self.assertEqual(assess(self.settings,self.assets,self.model)[0]['cdgc_binding'],'failed')
    def test_stale_or_duplicate_manual_record_fails(self):
        self.approval['records'][0]['assetModifiedOn']=1
        self.assertEqual(assess(self.settings,self.assets,self.model,self.approval)[0]['cdgc_approval'],'failed')
        self.approval['records'][0]=copy.deepcopy(self.approval['records'][1])
        self.assertEqual(assess(self.settings,self.assets,self.model,self.approval)[0]['cdgc_approval'],'failed')
    def test_asset_schema_and_host_are_not_silently_substituted(self):
        for host in ['http://idmc-api.dm-us.informaticacloud.com','evil.example','idmc-api.dm-us.informaticacloud.com.evil.test','https://idmc-api.dm-us.informaticacloud.com/path']:
            with self.assertRaises(GovernanceError):api_origin(host)
        client=Client('idmc-api.dm-us.informaticacloud.com','org','token',transport=lambda ids:{'assets':[]})
        with self.assertRaises(GovernanceError):client.assets(['term'])
        with self.assertRaises(GovernanceError):client.assets([{}])
        self.assertIsNone(pointer({},'/stakeholdership/0/core.identity'))

if __name__=='__main__':unittest.main()

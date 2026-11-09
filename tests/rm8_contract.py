import sys,json,unittest,copy
from pathlib import Path
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'packages/rm8/cdgc'))
sys.path.insert(0,str(root/'packages/rm8/bridge'))
from bridge import evaluate,validate_copy_source

class DualCatalogContract(unittest.TestCase):
    def setUp(self):
        p=root/'packages/rm8';self.settings=json.loads((p/'cdgc/settings.json').read_text());self.mapping=json.loads((p/'bridge/settings.json').read_text());self.contract=json.loads((p/'governance/metric-contract.json').read_text(encoding='utf-8'));self.model=(p/'cube/schema/Sales.js').read_text();self.assets={};self.objects={}
        self.settings['owner'].update(expectedId='business-owner',expectedRoleId='steward-role')
        for i,(cfg,m,local) in enumerate(zip(self.settings['metrics'],self.mapping['metrics'],self.contract['metrics'])):
            cfg['assetId']='asset'+str(i);desc='Actual business definition '+cfg['expectedName'];self.assets[cfg['assetId']]={'summary':{'core.name':cfg['expectedName'],'core.description':desc},'stakeholdership':[{'core.identity':'business-owner','core.role':'steward-role'}],'systemAttributes':{'core.modifiedOn':1700000000000}}
            self.objects[m['metricId']]={'metric':{'id':'metric'+str(i),'name':m['omMetricName'],'description':desc,'owners':[{'id':'team'}],'tags':[{'tagFQN':m['omTermFqn']}],'metricExpression':{'code':local['sql']}},'term':{'id':'term'+str(i),'fullyQualifiedName':m['omTermFqn'],'description':desc,'owners':[{'id':'team'}]}}
    def run_check(self,snapshot=None):return evaluate(self.mapping,self.settings,self.assets,self.objects,'team',self.contract,self.model,snapshot)
    def checkpoint(self):return {'source':'live_cdgc_to_local_om','records':self.run_check()[1]}
    def test_declared_mapping_and_actual_copy_are_separate_from_checkpoint(self):
        states,_=self.run_check();self.assertEqual(states['dual_identity'],'passed');self.assertEqual(states['dual_revision'],'not_tested')
        self.assertEqual(set(self.run_check(self.checkpoint())[0].values()),{'passed'})
    def test_definition_conflict_does_not_change_cube_calculation(self):
        self.objects['Sales.netRevenue']['metric']['description']='different'
        states,_=self.run_check();self.assertEqual(states['dual_definition'],'failed');self.assertEqual(states['dual_identity'],'passed')
    def test_changed_source_version_fails_until_reviewed_sync(self):
        snapshot=self.checkpoint();self.assets['asset0']['systemAttributes']['core.modifiedOn']+=1
        self.assertEqual(self.run_check(snapshot)[0]['dual_revision'],'failed')
    def test_owner_mismatch_or_unmapped_owner_cannot_pass(self):
        self.objects['Sales.netRevenue']['term']['owners']=[]
        self.assertEqual(self.run_check()[0]['dual_owner'],'failed')
        self.settings['owner']['expectedId']=''
        self.assertEqual(self.run_check()[0]['dual_owner'],'not_tested')
    def test_duplicate_identity_or_wrong_checkpoint_is_rejected(self):
        snapshot=self.checkpoint();snapshot['records'][1]=copy.deepcopy(snapshot['records'][0])
        self.assertEqual(self.run_check(snapshot)[0]['dual_revision'],'failed')
        self.mapping['metrics'][1]['metricId']=self.mapping['metrics'][0]['metricId']
        with self.assertRaises(Exception):self.run_check()
    def test_sql_expression_drift_is_not_hidden_by_matching_description(self):
        self.objects['Sales.netRevenue']['metric']['metricExpression']['code']='SUM(gross_revenue_eur)'
        self.assertEqual(self.run_check()[0]['dual_definition'],'failed')
    def test_copy_requires_expected_source_lifecycle_and_business_definition(self):
        for cfg in self.settings['metrics']:
            self.assets[cfg['assetId']]['selfAttributes']={'core.assetLifecycle':'Published'}
            self.assets[cfg['assetId']]['summary']['core.description']=' '.join(cfg['descriptionContains'])
        validate_copy_source(self.settings,self.assets)
        self.assets['asset0']['selfAttributes']['core.assetLifecycle']='Draft'
        with self.assertRaises(Exception):validate_copy_source(self.settings,self.assets)

if __name__=='__main__':unittest.main()

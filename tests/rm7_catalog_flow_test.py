import copy, json, sys, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'packages/rm7/consumers'))
from catalog_flow import catalog, execute_selected, GovernanceError

class CatalogFlowTest(unittest.TestCase):
    def setUp(self):
        self.settings = json.loads((Path(__file__).resolve().parents[1] / 'packages/rm7/governance/settings.json').read_text())
        self.assets = {}
        for i, m in enumerate(self.settings['metrics']):
            m['assetId'] = 'metric-'+str(i)
            self.assets[m['assetId']] = {'core.identity': m['assetId'], 'summary': {'core.name': m['expectedName'], 'core.description': ' '.join(m['descriptionContains'])}, 'stakeholdership': [{'core.identity': 'owner-real', 'core.role': 'role-real'}], 'selfAttributes': {'core.assetLifecycle': 'Published'}}
        self.settings['technical'].update(assetId='view-real', expectedExternalId='source://db/dwh/v_sales_detail')
        self.assets['view-real'] = {'core.identity': 'view-real', 'core.externalId': 'source://db/dwh/v_sales_detail', 'glossary': [{'core.identity': m['assetId'], 'core.curationStatus': 'ACCEPTED'} for m in self.settings['metrics']]}
    def load(self):
        class FixtureClient:
            def __init__(self, assets): self.value = assets
            def assets(self, ids): return {k:v for k,v in self.value.items() if k in ids}
        return catalog(self.settings, FixtureClient(self.assets))
    def test_live_catalog_choice_controls_the_exact_cube_measure(self):
        calls = []
        def cube(endpoint, query):
            calls.append((endpoint, query))
            return {'data': [{'Sales.month': '2026-01-01', 'Sales.netRevenue': '8164.8'}]}
        result = execute_selected('metric-0', 'Sales.netRevenue', self.load, cube)
        self.assertEqual(calls[0][1]['measures'], ['Sales.netRevenue'])
        self.assertEqual(result['catalog']['ownerId'], 'owner-real')
        self.assertFalse(result['humanApprovalVerified'])
    def test_unavailable_catalog_never_calls_cube(self):
        calls = []
        def unavailable(): raise GovernanceError('unavailable')
        with self.assertRaises(GovernanceError): execute_selected('metric-0', 'Sales.netRevenue', unavailable, lambda *a: calls.append(a))
        self.assertEqual(calls, [])
    def test_draft_missing_owner_wrong_definition_and_declined_binding_block(self):
        original = copy.deepcopy(self.assets)
        changes = [lambda: self.assets['metric-0']['selfAttributes'].update({'core.assetLifecycle': 'Draft'}), lambda: self.assets['metric-0'].update(stakeholdership=[]), lambda: self.assets['metric-0']['summary'].update({'core.description': 'gross revenue'}), lambda: self.assets['view-real']['glossary'][0].update({'core.curationStatus': 'DECLINED'}), lambda: self.assets['view-real'].update({'core.externalId': 'other-source'})]
        for change in changes:
            self.assets = copy.deepcopy(original)
            change()
            calls = []
            with self.assertRaises(GovernanceError): execute_selected('metric-0', 'Sales.netRevenue', self.load, lambda *a: calls.append(a))
            self.assertFalse(calls)
    def test_rechecks_changed_catalog_and_rejects_forged_selection(self):
        self.assertTrue(self.load()[0]['queryable'])
        self.assets['metric-0']['stakeholdership'] = []
        with self.assertRaises(GovernanceError): execute_selected('metric-0', 'Sales.netRevenue', self.load, lambda *a: self.fail('Cube must not run'))
        with self.assertRaises(GovernanceError): execute_selected('metric-0', 'Sales.averagePrice', self.load, lambda *a: self.fail('Cube must not run'))
    def test_expected_owner_mismatch_and_no_technical_mapping_block(self):
        self.settings['owner']['expectedId'] = 'different-person'
        self.assertFalse(self.load()[0]['queryable'])
        self.settings['owner']['expectedId'] = ''
        self.settings['technical']['expectedExternalId'] = ''
        self.assertFalse(self.load()[0]['queryable'])

if __name__ == '__main__': unittest.main()

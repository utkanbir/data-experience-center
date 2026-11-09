import importlib.util,json,os,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import Mock,patch

root=Path(__file__).resolve().parents[1]
def module(path,name):
    sys.path.insert(0,str(path.parent));sys.modules.pop('client',None)
    spec=importlib.util.spec_from_file_location(name,path);value=importlib.util.module_from_spec(spec);spec.loader.exec_module(value);return value
def write(base,path,text):
    target=base/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text,encoding='utf-8')

class LocalOnly(unittest.TestCase):
    def test_cdgc_existing_credentials_are_not_used_in_local_only_mode(self):
        for n in [7,8]:
            folder='governance' if n==7 else 'cdgc';p=root/f'packages/rm{n}';v=module(p/folder/'verify.py','cdgc_mode_'+str(n))
            with tempfile.TemporaryDirectory(dir=root/'.checks') as temp:
                base=Path(temp);self.assertTrue(base.resolve().is_relative_to((root/'.checks').resolve()));write(base,folder+'/settings.json',(p/folder/'settings.json').read_text(encoding='utf-8'));write(base,folder+'/connection-mode.txt','later\n');v.Path=lambda name:base/str(name).lstrip('/');v.Client=Mock(side_effect=AssertionError('No external request allowed'))
                with patch.dict(os.environ,{'INFA_HOST':'idmc-api.dm-us.informaticacloud.com','INFA_ORG':'test-org','INFA_TOKEN':'placeholder'}):self.assertEqual(v.main(),0)
                v.Client.assert_not_called();e=json.loads((base/'artifacts/cdgc-checks.json').read_text());self.assertFalse(e['remoteRequestPerformed']);self.assertEqual({c['status'] for c in e['checks']},{'not_tested'})
    def test_dual_catalog_verification_and_copy_do_not_use_credentials_when_local_only(self):
        p=root/'packages/rm8';sys.path.insert(0,str(p/'cdgc'));v=module(p/'bridge/bridge.py','dual_mode')
        with tempfile.TemporaryDirectory(dir=root/'.checks') as temp:
            base=Path(temp);self.assertTrue(base.resolve().is_relative_to((root/'.checks').resolve()));(base/'artifacts').mkdir()
            for source,target in [('cdgc/settings.json','cdgc/settings.json'),('bridge/settings.json','bridge/settings.json'),('governance/metric-contract.json','catalog/metric-contract.json'),('cube/schema/Sales.js','cube-model/Sales.js')]:write(base,target,(p/source).read_text(encoding='utf-8'))
            write(base,'cdgc/connection-mode.txt','later\n');v.Path=lambda name:base/str(name).lstrip('/');v.Client=Mock(side_effect=AssertionError('No external request allowed'))
            with patch.dict(os.environ,{'INFA_HOST':'idmc-api.dm-us.informaticacloud.com','INFA_ORG':'test-org','INFA_TOKEN':'placeholder'}):
                with patch.object(sys,'argv',['bridge.py','verify']):self.assertEqual(v.main(),0)
                with patch.object(sys,'argv',['bridge.py','sync']):self.assertEqual(v.main(),1)
            v.Client.assert_not_called();self.assertFalse((base/'artifacts/business-sync.json').exists())
    def test_managed_dbt_existing_credentials_are_not_used_when_local_only(self):
        p=root/'packages/rm6/managed';client=module(p/'client.py','client');sys.modules['client']=client;client.Client=Mock(side_effect=AssertionError('No external request allowed'))
        with tempfile.TemporaryDirectory(dir=root/'.checks') as temp:
            base=Path(temp);self.assertTrue(base.resolve().is_relative_to((root/'.checks').resolve()));write(base,'managed/connection-mode.txt','later\n')
            source=(p/'verify.py').read_text().replace('from pathlib import Path','from pathlib import Path as _RealPath\nPath=lambda name: _RealPath(TEST_ROOT)/str(name).lstrip("/")')
            with patch.dict(os.environ,{'DBT_SL_HOST':'semantic-layer.cloud.getdbt.com','DBT_SL_ENVIRONMENT_ID':'123','DBT_SL_TOKEN':'placeholder'}):
                with self.assertRaises(SystemExit) as result:exec(compile(source,str(p/'verify.py'),'exec'),{'TEST_ROOT':temp})
            self.assertEqual(result.exception.code,0);client.Client.assert_not_called();e=json.loads((base/'artifacts/managed-checks.json').read_text());self.assertEqual({c['status'] for c in e['checks']},{'not_tested'})

if __name__=='__main__':unittest.main()

import ast,json,unittest
from pathlib import Path
root=Path(__file__).resolve().parents[1]
tree=ast.parse((root/'packages/rm10/graph/graph.py').read_text(encoding='utf-8'))
selected=ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ('digest','identity','ontology_valid')],type_ignores=[])
import hashlib
scope={'hashlib':hashlib,'json':json,'CLASSES':{'Customer','Outlet','Distributor','Product','Promotion','Sale','Metric'},'RELATIONS':{'OWNS_OUTLET':('Customer','Outlet'),'SERVED_BY':('Outlet','Distributor'),'AT_OUTLET':('Sale','Outlet'),'OF_PRODUCT':('Sale','Product'),'WITH_PROMOTION':('Sale','Promotion')}}
exec(compile(selected,'graph-functions','exec'),scope)
class GraphModelTest(unittest.TestCase):
    def model(self):return json.loads((root/'packages/rm10/graph/ontology.json').read_text(encoding='utf-8'))
    def test_defined_model(self):self.assertTrue(scope['ontology_valid'](self.model()))
    def test_missing_class(self):
        model=self.model();model['classes'].pop();self.assertFalse(scope['ontology_valid'](model))
    def test_wrong_relation_range(self):
        model=self.model();model['relations'][0]['range']='Product';self.assertFalse(scope['ontology_valid'](model))
    def test_missing_source_binding(self):
        model=self.model();model['classes'][0]['source']='';self.assertFalse(scope['ontology_valid'](model))
    def test_wrong_source_binding(self):
        model=self.model();model['classes'][0]['source']='raw.dim_outlet';self.assertFalse(scope['ontology_valid'](model))
    def test_identity_is_type_scoped(self):self.assertNotEqual(scope['identity']('Outlet',1),scope['identity']('Product',1))
    def test_hash_is_order_independent_and_change_sensitive(self):
        digest=scope['digest'];self.assertEqual(digest({'a':1,'b':2}),digest({'b':2,'a':1}));self.assertNotEqual(digest({'a':1}),digest({'a':2}))
if __name__=='__main__':unittest.main()

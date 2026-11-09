import sys,json,unittest,base64
from pathlib import Path
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'packages/rm6/managed'))
from client import Client,ManagedError,endpoint,environment_id,read_reference,reference_match,decode_result,NoRedirect
rows=read_reference(root/'packages/rm6/data/expected-results.csv') if (root/'packages/rm6/data/expected-results.csv').exists() else read_reference(root/'packages/rm6/managed/expected-results.csv')
class Checks(unittest.TestCase):
 def test_endpoint(self):
  self.assertEqual(endpoint('semantic-layer.cloud.getdbt.com'),'https://semantic-layer.cloud.getdbt.com/api/graphql')
  for h in ['http://semantic-layer.cloud.getdbt.com','semantic-layer.cloud.getdbt.com.evil.test','127.0.0.1','https://token@semantic-layer.cloud.getdbt.com','https://semantic-layer.cloud.getdbt.com/?token=x']:
   with self.assertRaises(ManagedError):endpoint(h)
 def test_environment(self):
  for x in ['0','-1','abc','1\n2']:
   with self.assertRaises(ManagedError):environment_id(x)
 def test_reference(self):
  self.assertTrue(reference_match(rows,rows));wrong=[dict(r) for r in rows];wrong[0]['net_revenue']='0';self.assertFalse(reference_match(wrong,rows))
  with self.assertRaises(ManagedError):reference_match(rows+[rows[0]],rows)
 def test_decode(self):
  value=json.dumps({'data':rows});self.assertEqual(decode_result(value),decode_result(base64.b64encode(value.encode()).decode()))
  with self.assertRaises(ManagedError):decode_result('bad')
 def test_real_protocol_contract(self):
  def transport(p):
   if 'metricsPaginated' in p['query']:return {'data':{'metricsPaginated':{'items':[{'name':x} for x in ['net_revenue','net_liters','average_price']]}}}
   if 'createQuery' in p['query']:return {'data':{'createQuery':{'queryId':'test-id'}}}
   return {'data':{'query':{'status':'SUCCESSFUL','sql':'select metrics','totalPages':1,'jsonResult':json.dumps({'data':rows})}}}
  c=Client('semantic-layer.cloud.getdbt.com','123','fake-test-token',transport);self.assertEqual(len(c.metrics()),3);result=c.query({'metrics':['net_revenue','net_liters','average_price'],'groupBy':[]},wait=lambda _:None);self.assertTrue(reference_match(result['rows'],rows))
 def test_bad_remote(self):
  c=Client('semantic-layer.cloud.getdbt.com','123','fake-test-token',lambda p:{'errors':[{'message':'bad'}]})
  with self.assertRaises(ManagedError):c.metrics()
 def test_timeout(self):
  c=Client('semantic-layer.cloud.getdbt.com','123','fake-test-token',lambda p:{'data':{'createQuery':{'queryId':'x'}}} if 'createQuery' in p['query'] else {'data':{'query':{'status':'PENDING'}}})
  with self.assertRaises(ManagedError):c.query({'metrics':[],'groupBy':[]},poll_limit=1,wait=lambda _:None)
 def test_redirect(self):
  with self.assertRaises(ManagedError):NoRedirect().redirect_request(None,None,None,None,None,None)
if __name__=='__main__':unittest.main()

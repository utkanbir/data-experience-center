import base64,csv,json,os,re,time
from decimal import Decimal
from urllib.request import Request,build_opener,HTTPRedirectHandler
from urllib.error import HTTPError
from urllib.parse import urlsplit

class ManagedError(Exception):pass
class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self,*args,**kwargs):raise ManagedError('Semantic endpoint redirected; check the official host.')

def endpoint(host):
    if not isinstance(host,str) or not host.strip():raise ManagedError('Semantic Layer host missing.')
    raw=host.strip();url=urlsplit(raw if '://' in raw else 'https://'+raw)
    name=(url.hostname or '').lower()
    if url.scheme!='https' or url.username or url.password or url.port not in (None,443) or url.path not in ('','/','/api/graphql') or url.query or url.fragment:raise ManagedError('Use an HTTPS dbt Semantic Layer host, without credentials or query parameters.')
    if not re.fullmatch(r'[a-z0-9.-]+',name) or not any(name.endswith('.'+d) for d in ['getdbt.com','dbt.com']) or 'semantic-layer' not in name.split('.'):raise ManagedError('Host must be an official dbt Semantic Layer hostname.')
    return 'https://'+name+'/api/graphql'

def environment_id(value):
    value=str(value).strip()
    if not re.fullmatch(r'[0-9]{1,20}',value) or int(value)<1:raise ManagedError('A positive dbt environment ID is required.')
    return value

def normalize_rows(rows):
    if not isinstance(rows,list):raise ManagedError('Remote data must be a row list.')
    result=[];seen=set()
    for row in rows:
        values={str(k).lower():v for k,v in row.items()}
        month=next((values[k] for k in ['metric_time__month','metric_time','month'] if k in values),None)
        channel=next((values[k] for k in ['sales_line__channel','channel'] if k in values),None)
        month=str(month)[:7]
        if not re.fullmatch(r'\d{4}-\d{2}',month) or not isinstance(channel,str):raise ManagedError('Missing month or channel in metric result.')
        key=(month,channel)
        if key in seen:raise ManagedError('Duplicate month/channel metric row.')
        seen.add(key);entry={'month':month,'channel':channel}
        for name in ['net_revenue','net_liters','average_price']:
            try:number=Decimal(str(values[name]))
            except Exception:raise ManagedError('Missing or invalid metric: '+name) from None
            if not number.is_finite():raise ManagedError('Non-finite metric result.')
            entry[name]=str(number)
        result.append(entry)
    return sorted(result,key=lambda r:(r['month'],r['channel']))

def reference_match(rows,expected):
    actual=normalize_rows(rows);reference=normalize_rows(expected)
    if len(actual)!=6 or len(reference)!=6:return False
    return all(a['month']==b['month'] and a['channel']==b['channel'] and all(abs(Decimal(a[k])-Decimal(b[k]))<Decimal('0.0001') for k in ['net_revenue','net_liters','average_price']) for a,b in zip(actual,reference))

def read_reference(path):
    with open(path,newline='') as stream:
        return [{'month':r['month'],'channel':r['channel'],'net_revenue':r['net_revenue_eur'],'net_liters':r['volume_liters'],'average_price':r['average_price_eur_per_liter']} for r in csv.DictReader(stream)]

def decode_result(value):
    if not isinstance(value,str):raise ManagedError('Missing JSON metric result.')
    try:decoded=json.loads(value)
    except (ValueError,TypeError):
        try:decoded=json.loads(base64.b64decode(value,validate=True))
        except Exception:raise ManagedError('Invalid JSON metric response.') from None
    rows=decoded.get('data') if isinstance(decoded,dict) else decoded
    return normalize_rows(rows)

class Client:
    def __init__(self,host,env_id,token,transport=None):
        self.url=endpoint(host);self.env=environment_id(env_id);self.token=token;self.transport=transport or self._post
        if not isinstance(token,str) or not token.strip():raise ManagedError('Semantic service token missing.')
    def _post(self,payload):
        request=Request(self.url,data=json.dumps(payload).encode(),headers={'Authorization':'Bearer '+self.token,'Content-Type':'application/json'},method='POST')
        try:
            with build_opener(NoRedirect()).open(request,timeout=45) as response:return json.load(response)
        except HTTPError as error:raise ManagedError('Semantic API HTTP '+str(error.code)+'. Check token, environment, plan and host.') from None
        except ManagedError:raise
        except Exception:raise ManagedError('Semantic API connection or response failed.') from None
    def call(self,query,variables=None):
        value=self.transport({'query':query,'variables':variables or {}})
        if not isinstance(value,dict) or value.get('errors') or not isinstance(value.get('data'),dict):raise ManagedError('GraphQL returned errors or missing data; inspect host, permissions and deployed semantic model.')
        return value['data']
    def metrics(self):
        data=self.call('query($environmentId: BigInt!) { metricsPaginated(environmentId:$environmentId,pageSize:100,pageNum:1) { items { name } } }',{'environmentId':self.env})
        return {m['name'] for m in data.get('metricsPaginated',{}).get('items',[])}
    def query(self,definition,poll_limit=90,wait=time.sleep):
        variables={'environmentId':self.env,'metrics':[{'name':name,'alias':name} for name in definition['metrics']],'groupBy':definition['groupBy']}
        created=self.call('mutation($environmentId: BigInt!, $metrics: [MetricInput!]!, $groupBy: [GroupByInput!]) { createQuery(environmentId:$environmentId,metrics:$metrics,groupBy:$groupBy,limit:100) { queryId } }',variables)
        query_id=created.get('createQuery',{}).get('queryId')
        if not query_id:raise ManagedError('Managed query ID missing.')
        for _ in range(poll_limit):
            data=self.call('query($environmentId: BigInt!, $queryId: String!) { query(environmentId:$environmentId,queryId:$queryId) { status error sql totalPages jsonResult(orient:TABLE,encoded:false) } }',{'environmentId':self.env,'queryId':str(query_id)})
            result=data.get('query') or {};status=result.get('status')
            if status=='FAILED' or result.get('error'):raise ManagedError('Managed metric query failed; check deployed models and database access.')
            if status=='SUCCESSFUL':
                if int(result.get('totalPages') or 1)>1:raise ManagedError('Unexpected pagination; this reference query expects six rows.')
                return {'queryId':str(query_id),'sql':result.get('sql') or '', 'rows':decode_result(result.get('jsonResult'))}
            wait(2)
        raise ManagedError('Managed query polling timed out.')

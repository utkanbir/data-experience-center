import base64,hashlib,hmac,json,os,time
from urllib.request import Request,urlopen
from urllib.parse import urlencode
from urllib.error import HTTPError
from pathlib import Path

def token():
    encode=lambda v:base64.urlsafe_b64encode(json.dumps(v,separators=(',',':')).encode()).decode().rstrip('=')
    raw=encode({'alg':'HS256','typ':'JWT'})+'.'+encode({'iat':int(time.time()),'exp':int(time.time())+300,'sub':'rm8-lab'})
    sig=base64.urlsafe_b64encode(hmac.new(os.environ['CUBEJS_API_SECRET'].encode(),raw.encode(),hashlib.sha256).digest()).decode().rstrip('=')
    return raw+'.'+sig

def request(endpoint,query=None,authenticated=True):
    url=os.environ.get('CUBE_URL','http://cube:4000')+'/cubejs-api/v1/'+endpoint
    if query is not None:url+='?'+urlencode({'query':json.dumps(query)})
    headers={'Authorization':token()} if authenticated else {}
    for attempt in range(90):
        try:
            with urlopen(Request(url,headers=headers),timeout=30) as response:value=json.load(response)
            if value.get('error')=='Continue wait':time.sleep(1);continue
            if value.get('error'):raise RuntimeError(str(value['error']))
            return value
        except HTTPError as error:
            if error.code==502 and attempt<89:time.sleep(1);continue
            if not authenticated:raise
            detail=error.read().decode(errors='replace')[:2000]
            raise RuntimeError(f'Cube HTTP {error.code}: {detail}') from error
    raise TimeoutError('Cube query timeout')

def run_query():
    query=json.loads((Path(__file__).parent/'query.json').read_text())
    value=request('load',query)
    return sorted(value['data'],key=lambda x:(x['Sales.month'],x['Sales.channel']))

if __name__=='__main__':print(json.dumps(run_query(),ensure_ascii=False,indent=2))

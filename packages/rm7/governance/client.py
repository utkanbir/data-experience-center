import json,re
from urllib.parse import urlsplit
from urllib.request import Request,build_opener,HTTPRedirectHandler
from urllib.error import HTTPError

class GovernanceError(Exception):pass
class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self,*args,**kwargs):raise GovernanceError('CDGC endpoint redirected; check the official API host.')

def api_origin(host):
    if not isinstance(host,str) or not host.strip():raise GovernanceError('CDGC API host missing.')
    try:u=urlsplit(host.strip() if '://' in host else 'https://'+host.strip());port=u.port
    except ValueError:raise GovernanceError('Invalid API host.') from None
    name=(u.hostname or '').lower()
    if u.scheme!='https' or u.username or u.password or port not in (None,443) or u.path not in ('','/') or u.query or u.fragment or not re.fullmatch(r'idmc-api(?:\.[a-z0-9-]+)+\.informaticacloud\.com',name):raise GovernanceError('Use the official HTTPS idmc-api host, without a path, credentials or query.')
    return 'https://'+name

def pointer(value,path):
    if not isinstance(path,str) or not path.startswith('/') or len(path)>500:raise GovernanceError('JSON pointer must start with / and be at most 500 characters.')
    for part in path[1:].split('/'):
        part=part.replace('~1','/').replace('~0','~')
        try:value=value[int(part)] if isinstance(value,list) else value[part]
        except (KeyError,IndexError,TypeError,ValueError):return None
    return value

class Client:
    def __init__(self,host,org,token,transport=None):
        self.origin=api_origin(host)
        if not isinstance(org,str) or not re.fullmatch(r'[A-Za-z0-9_-]{1,100}',org):raise GovernanceError('Org ID missing or invalid.')
        if not isinstance(token,str) or not token.strip() or len(token)>16000 or '\r' in token or '\n' in token:raise GovernanceError('JWT token missing or invalid.')
        self.org=org;self.token=token;self.transport=transport or self._request
    def _request(self,ids):
        request=Request(self.origin+'/data360/search/v1/assets/details?scheme=internal&segments=all',data=json.dumps(ids).encode(),headers={'Authorization':'Bearer '+self.token,'X-INFA-ORG-ID':self.org,'Content-Type':'application/json'},method='POST')
        try:
            with build_opener(NoRedirect()).open(request,timeout=40) as response:raw=response.read(8_000_001)
            if len(raw)>8_000_000:raise GovernanceError('CDGC response exceeded the 8 MB reference limit.')
            return json.loads(raw)
        except HTTPError as e:raise GovernanceError('CDGC HTTP '+str(e.code)+'. Check JWT expiry, org, pod and asset read permissions.') from None
        except GovernanceError:raise
        except Exception:raise GovernanceError('CDGC request or JSON response failed.') from None
    def assets(self,ids):
        if not isinstance(ids,list) or not ids or len(ids)>8 or any(not isinstance(v,str) or not re.fullmatch(r'[A-Za-z0-9_-]{1,200}',v) for v in ids) or len(set(ids))!=len(ids):raise GovernanceError('Provide 1–8 unique internal asset IDs.')
        rows=self.transport(ids)
        if not isinstance(rows,list) or any(not isinstance(row,dict) or not isinstance(row.get('core.identity'),str) for row in rows):raise GovernanceError('Unsupported asset response schema; review the org response and configured JSON pointers.')
        result={}
        for row in rows:
            key=row['core.identity']
            if key not in ids or key in result:raise GovernanceError('CDGC returned an unexpected or duplicate asset identity.')
            result[key]=row
        return result

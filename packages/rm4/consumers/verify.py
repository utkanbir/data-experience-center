import csv,json,sys
from decimal import Decimal
from pathlib import Path
from urllib.error import HTTPError
from client import run_query,request
out=Path('/artifacts');out.mkdir(exist_ok=True)
keys=['cube_api','cube_sql','cube_match','two_consumers','api_auth']
states=dict.fromkeys(keys,'not_tested')
for name in ['cube-results.json','cube-sql.json','python-results.json','dashboard-results.json','cube-checks.json','cube-status.txt']:(out/name).unlink(missing_ok=True)
def save():
    (out/'cube-checks.json').write_text(json.dumps({'checks':[{'id':k,'status':v} for k,v in states.items()]}))
    (out/'cube-status.txt').write_text('\n'.join(states.values())+'\n')
save()
try:
    states['api_auth']='failed'
    try:request('meta',authenticated=False)
    except HTTPError as error:
        if error.code in (401,403):states['api_auth']='passed'
    rows=run_query();states['cube_api']='passed' if len(rows)==6 else 'failed'
    (out/'cube-results.json').write_text(json.dumps(rows,indent=2))
    query=json.loads(Path('/consumer/query.json').read_text())
    sql=request('sql',query);(out/'cube-sql.json').write_text(json.dumps(sql,indent=2))
    states['cube_sql']='passed' if sql.get('sql',{}).get('sql') else 'failed'
    expected=list(csv.DictReader(Path('/consumer/expected-results.csv').open()))
    actual={(x['Sales.month'],x['Sales.channel']):x for x in rows}
    pairs=[('Sales.netRevenue','net_revenue_eur'),('Sales.netLiters','volume_liters'),('Sales.averagePrice','average_price_eur_per_liter')]
    states['cube_match']='passed' if len(actual)==len(expected) and all((e['month'],e['channel']) in actual and all(abs(Decimal(str(actual[e['month'],e['channel']][a]))-Decimal(e[b]))<Decimal('0.0001') for a,b in pairs) for e in expected) else 'failed'
    import subprocess
    raw=subprocess.check_output([sys.executable,'/consumer/client.py'],text=True)
    python_rows=json.loads(raw);(out/'python-results.json').write_text(raw)
    import importlib.util
    spec=importlib.util.spec_from_file_location('rm4_dashboard','/consumer/dashboard.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    dashboard_rows=module.fetch_rows();(out/'dashboard-results.json').write_text(json.dumps(dashboard_rows,indent=2))
    from urllib.request import urlopen
    with urlopen('http://dashboard:8501/_stcore/health',timeout=30) as response:healthy=response.status==200
    states['two_consumers']='passed' if healthy and python_rows==dashboard_rows==rows else 'failed'
except Exception as error:
    print(type(error).__name__+': '+str(error),file=sys.stderr)
finally:save()
print(json.dumps(states))
sys.exit(0 if all(x=='passed' for x in states.values()) else 1)

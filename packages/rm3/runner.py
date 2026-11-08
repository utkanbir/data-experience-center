import json,os,subprocess,sys,shutil
from pathlib import Path
from datetime import datetime,timezone
out=Path('/artifacts');out.mkdir(exist_ok=True)
keys=['dbt_models','dbt_tests','dbt_docs','mf_query','mf_sql','mf_match'];states=dict.fromkeys(keys,'not_tested')
def save():
    (out/'dbt-checks.json').write_text(json.dumps({'generatedAt':datetime.now(timezone.utc).isoformat(),'checks':[{'id':k,'status':v} for k,v in states.items()]}))
    (out/'dbt-status.txt').write_text('\n'.join(states.values())+'\n')
for name in ['manifest.json','catalog.json','build_results.json','static_index.html','dbt-checks.json','dbt-status.txt','semantic_manifest.json','metricflow-output.txt','metricflow-sql.txt','metricflow-results.csv','metricflow-results.json']:
    (out/name).unlink(missing_ok=True)
save()
try:
    subprocess.run([sys.executable,'-m','pip','install','--disable-pip-version-check','--no-cache-dir','dbt-core==1.10.15','dbt-postgres==1.9.1','dbt-metricflow==0.11.0'],check=True)
    workspace=Path('/workspace');workspace.mkdir(exist_ok=True)
    for name,text in json.loads(Path('/runner/project.json').read_text()).items():
        target=workspace/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text)
    command=['dbt','--no-use-colors'];common=['--project-dir',str(workspace),'--profiles-dir',str(workspace)]
    built=subprocess.run(command+['build']+common,cwd=workspace).returncode
    result=workspace/'target/run_results.json'
    if result.exists():
        shutil.copyfile(result,out/'build_results.json')
        records=json.loads(result.read_text()).get('results',[])
        for key,prefix,success in [('dbt_models','model.','success'),('dbt_tests','test.','pass')]:
            group=[v for v in records if v.get('unique_id','').startswith(prefix)]
            states[key]='passed' if group and all(v.get('status')==success for v in group) else 'failed'
    else:
        states['dbt_models']='failed';states['dbt_tests']='not_tested'
    docs=subprocess.run(command+['docs','generate','--static']+common,cwd=workspace).returncode
    states['dbt_docs']='passed' if docs==0 and (workspace/'target/static_index.html').exists() else 'failed'
    for name in ['manifest.json','catalog.json','static_index.html']:
        source=workspace/'target'/name
        if source.exists():shutil.copyfile(source,out/name)
    for name in ['semantic_manifest.json']:
        source=workspace/'target'/name
        if source.exists():shutil.copyfile(source,out/name)
    os.environ['DBT_PROFILES_DIR']=str(workspace)
    subprocess.run(['mf','query','--help'],cwd=workspace)
    import csv
    query=['mf','query','--metrics','net_revenue,net_liters,average_price','--group-by','metric_time__month,sales_line__channel']
    with (out/'metricflow-output.txt').open('w') as stream:
        queried=subprocess.run(query+['--csv',str(out/'metricflow-results.csv')],cwd=workspace,stdout=stream,stderr=subprocess.STDOUT).returncode
    states['mf_query']='passed' if queried==0 else 'failed'
    with (out/'metricflow-sql.txt').open('w') as stream:
        explained=subprocess.run(query+['--explain'],cwd=workspace,stdout=stream,stderr=subprocess.STDOUT).returncode
    states['mf_sql']='passed' if explained==0 else 'failed'
    states['mf_match']='not_tested'
    if queried==0:
        with (out/'metricflow-results.csv').open() as stream:rows=list(csv.DictReader(stream))
        (out/'metricflow-results.json').write_text(json.dumps(rows))
        expected={('2025-01','HoReCa'):(8164.8,1844.64),('2025-02','HoReCa'):(3628.8,819.84),('2025-01','Retail'):(9576,2049.6),('2025-02','Retail'):(9576,2049.6),('2025-01','Online'):(10080,2049.6),('2025-02','Online'):(10080,2049.6)}
        matched=len(rows)==6
        for row in rows:
            time=next((str(v)[:7] for k,v in row.items() if 'metric_time' in k),'')
            channel=next((v for k,v in row.items() if 'channel' in k),'')
            target=expected.get((time,channel))
            if target is None:matched=False;continue
            values={k:float(v) for k,v in row.items() if k in ['net_revenue','net_liters','average_price']}
            matched=matched and abs(values.get('net_revenue',-1)-target[0])<0.0001 and abs(values.get('net_liters',-1)-target[1])<0.0001 and abs(values.get('average_price',-1)-target[0]/target[1])<0.0001
        states['mf_match']='passed' if matched else 'failed'
    save()
    sys.exit(0 if built==0 and all(v=='passed' for v in states.values()) else 1)
except Exception as error:
    print(type(error).__name__+': dbt run failed; inspect job logs',file=sys.stderr)
    save();sys.exit(1)

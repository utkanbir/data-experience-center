import json,os,subprocess,sys,shutil
from pathlib import Path
from datetime import datetime,timezone
out=Path('/artifacts');out.mkdir(exist_ok=True)
keys=['dbt_models','dbt_tests','dbt_docs'];states=dict.fromkeys(keys,'not_tested')
def save():
    (out/'dbt-checks.json').write_text(json.dumps({'generatedAt':datetime.now(timezone.utc).isoformat(),'checks':[{'id':k,'status':v} for k,v in states.items()]}))
    (out/'dbt-status.txt').write_text('\n'.join(states.values())+'\n')
for name in ['manifest.json','catalog.json','build_results.json','static_index.html','dbt-checks.json','dbt-status.txt']:
    (out/name).unlink(missing_ok=True)
save()
try:
    subprocess.run([sys.executable,'-m','pip','install','--disable-pip-version-check','--no-cache-dir','dbt-core==1.9.10','dbt-postgres==1.9.1'],check=True)
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
    save()
    sys.exit(0 if built==0 and all(v=='passed' for v in states.values()) else 1)
except Exception as error:
    print(type(error).__name__+': dbt run failed; inspect job logs',file=sys.stderr)
    save();sys.exit(1)

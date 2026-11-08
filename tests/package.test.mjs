import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const template=JSON.parse(fs.readFileSync('src/lib/rm1-template.json','utf8'));
const bash=process.platform==='win32'?'C:/Program Files/Git/bin/bash.exe':'/bin/bash';
test('Linux removal requires matching lab ownership and typed confirmation',{skip:!fs.existsSync(bash)},()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'komtas-removal-test-'));
 try{
  for(const name of ['common.sh','remove-environment.sh'])fs.writeFileSync(path.join(root,name),template[name]);
  const wrapper='kubectl(){ printf "%s\\n" "$*" >> "$CALLS"; case "$*" in *--ignore-not-found*) echo namespace/komtas-rm1;; *jsonpath=*) echo "$MOCK_OWNER";; esac; }; export -f kubectl; bash "$1"';
  for(const [owner,answer,deleted]of [['komtas-rm1','wrong\n',false],['other','komtas-rm1\n',false],['komtas-rm1','komtas-rm1\n',true]]){
   const calls=path.join(root,'calls.txt');fs.writeFileSync(calls,'');
   const r=spawnSync(bash,['-c',wrapper,'--',path.join(root,'remove-environment.sh')],{input:answer,encoding:'utf8',timeout:10000,windowsHide:true,env:{...process.env,CALLS:calls,MOCK_OWNER:owner}});
   assert.equal(fs.readFileSync(calls,'utf8').includes('delete namespace'),deleted,r.stderr);
   if(deleted)assert.equal(r.status,0,r.stderr);
   if(owner==='other')assert.notEqual(r.status,0);
  }
 }finally{assert.equal(path.dirname(path.resolve(root)),path.resolve(os.tmpdir()));fs.rmSync(root,{recursive:true,force:true});}
});

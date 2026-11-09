import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/deployment.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/connections.mjs'});
const {buildPackageFiles}=await import('../.checks/connections.mjs');
test('all ten packages expose one connection session and one credentials summary',()=>{
 const counts=[1,2,2,4,5,2,4,5,7,7];
 for(let id=1;id<=10;id++){
  const f=buildPackageFiles(id,'komtas-unified-test',15500),r='rm'+id+'-kubernetes/',p=JSON.parse(f[r+'connections.json']);
  assert.equal(p.namespace,'komtas-unified-test');assert.equal(p.services.length,counts[id-1]);
  assert.equal(p.services[0].localPort,15500);
  assert(f[r+'Connect.ps1'].includes('FileShare]::None'));assert(f[r+'Connect.ps1'].includes('finally'));
  assert(f[r+'connect.sh'].includes('trap cleanup EXIT'));assert(f[r+'connect.sh'].includes('flock -n'));
  assert(f[r+'Get-Connections.ps1'].includes('NoSecrets'));assert(f[r+'get-connections.sh']);
  assert.equal(f[r+'connections.tsv'].trim().split('\n').length,p.services.length);
  assert(f[r+'Show-Access.ps1'].includes('Get-Connections.ps1'));assert(f[r+'BAGLANTILAR.md']);
  assert(!p.services.some(s=>['metadata-postgres','elasticsearch','cubestore'].includes(s.service)));
 }
});
test('external services are described without attempting a local tunnel or printing external tokens',()=>{
 for(const id of [6,7,8]){
  const f=buildPackageFiles(id,'komtas-external-summary',15455),r='rm'+id+'-kubernetes/',p=JSON.parse(f[r+'connections.json']);
  assert.equal(p.external.length,1);assert(!p.services.some(s=>/infa|dbt-service|cdgc/.test(s.service)));
  assert(p.external[0].settings);assert(!p.credentials.some(c=>/token|jwt|dbt-service|cdgc/.test(c.key+c.secret)));
 }
});
test('port fallback is loopback-only and stopping validates process identity',()=>{
 const f=buildPackageFiles(9,'komtas-owned-tunnels',15440),r='rm9-kubernetes/';
 assert(f[r+'Connect.ps1'].includes('--address=127.0.0.1'));assert(f[r+'connect.sh'].includes('--address=127.0.0.1'));
 assert(f[r+'Connect.ps1'].includes("ProcessName -match '^kubectl"));assert(f[r+'Connect.ps1'].includes('StartTime.ToUniversalTime().Ticks'));
 assert(f[r+'Connect.ps1'].includes('$taskBase+30'));assert(f[r+'connect.sh'].includes('task_base+task_attempt'));
 assert(f[r+'trino/properties/reference.properties'].includes('postgres-reference'));
 assert(f[r+'trino/properties/jvm.config'].includes('-Xmx1536M'));
});

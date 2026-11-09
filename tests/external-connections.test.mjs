import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import {execFileSync} from 'node:child_process';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/external-connections.ts','src/lib/deployment.ts','src/lib/domain.ts'],bundle:true,platform:'node',format:'esm',outdir:'.checks/external'});
const {emptyExternalSetup,externalPlan}=await import('../.checks/external/external-connections.js');
const {buildPackageFiles}=await import('../.checks/external/deployment.js');
const {architectures}=await import('../.checks/external/domain.js');
const architecture=id=>architectures.find(a=>a.id===id);
function setup(id,mode='connect') {const s=emptyExternalSetup();if(id===6)s.paid={mode,values:{host:'semantic-layer.cloud.getdbt.com',environmentId:'123'}};else s.infa={mode,values:{apiHost:'https://idmc-api.dm-us.informaticacloud.com/',orgId:'example-org',netRevenueAssetId:'revenue-id',netLitersAssetId:'liters-id',averagePriceAssetId:'price-id',ownerId:'owner-id',ownerRoleId:'role-id'}};return s;}
test('external settings reach RM7 and RM8 config files without including unknown credential fields',()=>{
 for(const id of [7,8]){const s=setup(id);s.infa.values.password='DO-NOT-PACK';s.infa.values.token='DO-NOT-PACK';const f=buildPackageFiles(id,'komtas-external-test',15507,undefined,s),root='rm'+id+'-kubernetes/';const conf=JSON.parse(f[root+(id===8?'cdgc':'governance')+'/settings.json']);assert.equal(conf.apiHost,'idmc-api.dm-us.informaticacloud.com');assert.equal(conf.metrics[0].assetId,'revenue-id');assert.equal(conf.owner.expectedId,'owner-id');assert.equal(f[root+'external/mode.txt'],'connect\n');assert(!Object.values(f).join('').includes('DO-NOT-PACK'));assert(f[root+'Deploy.ps1'].indexOf('namespace.yaml')<f[root+'Deploy.ps1'].indexOf('Initialize-ExternalConnection.ps1'));}
});
test('connection validation rejects lookalike hosts, incomplete connect mode and duplicate identities',()=>{
 const s=setup(7);s.infa.values.apiHost='idmc-api.dm-us.informaticacloud.com.evil.test';assert.throws(()=>externalPlan(architecture(7),s));s.infa.values.apiHost='idmc-api.dm-us.informaticacloud.com';s.infa.values.orgId='';assert.throws(()=>externalPlan(architecture(7),s));s.infa.mode='later';assert.doesNotThrow(()=>externalPlan(architecture(7),s));s.infa.mode='connect';s.infa.values.orgId='org';s.infa.values.netLitersAssetId='revenue-id';assert.throws(()=>externalPlan(architecture(7),s));
});
test('managed dbt and cloud definitions preserve external-service boundaries',()=>{
 const f=buildPackageFiles(6,'komtas-external-test',15506,undefined,setup(6));assert.equal(JSON.parse(f['rm6-kubernetes/managed/settings.json']).environmentId,'123');const s=emptyExternalSetup();s.snow={mode:'connect',values:{account:'company-account',warehouse:'DEMO',database:'BEVERAGE',schema:'PUBLIC',password:'DO-NOT-PACK'}};const plan=externalPlan(architecture(12),s);assert.equal(plan.services.find(s=>s.id==='snow').automaticDeployment,false);assert(!JSON.stringify(plan).includes('DO-NOT-PACK'));assert.equal(plan.services.find(s=>s.id==='snow').settings.authMethod,'key-pair');assert(externalPlan(architecture(1)).desktopPrerequisites.length);
});
test('PowerShell initialization prompts locally once, skips later/existing and rejects identity changes',async()=>{
 if(process.platform!=='win32')return;
 const pwsh=process.env.CODEX_PRIMARY_RUNTIME_ROOT?path.join(process.env.CODEX_PRIMARY_RUNTIME_ROOT,'dependencies/native/powershell/pwsh.exe'):'C:/Users/Tolga EVREN/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe';
 const temp=await fs.mkdtemp(path.join(os.tmpdir(),'dec-external-init-'));
 try{for(const id of [6,7,8])for(const scenario of ['new','later','existing','mismatch']){const target=path.join(temp,'rm'+id+'-'+scenario);const files=buildPackageFiles(id,'komtas-external-test',15500+id,undefined,setup(id,scenario==='later'?'later':'connect'));for(const [name,text]of Object.entries(files)){if(!/\/(Common.ps1|Initialize-ExternalConnection.ps1|Set-InformaticaConnection.ps1|Set-DbtConnection.ps1|external-connections.json|(?:managed|governance|cdgc)\/settings.json)$/.test(name))continue;const rel=name.slice(name.indexOf('/')+1),dest=path.join(target,rel);await fs.mkdir(path.dirname(dest),{recursive:true});await fs.writeFile(dest,text);}const output=execFileSync(pwsh,['-NoProfile','-File',path.resolve('tests/external-init-fixture.ps1'),'-PackagePath',target,'-Case',scenario,'-Architecture',String(id)],{encoding:'utf8',windowsHide:true,timeout:20000});assert(output.includes('PASS '+id+' '+scenario));}}
 finally{assert.equal(path.dirname(temp),os.tmpdir());await fs.rm(temp,{recursive:true,force:true});}
});

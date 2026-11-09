import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/deployment.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/deployment-rm8.mjs'});
await build({entryPoints:['src/lib/experience.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/experience-rm8.mjs'});
const {buildPackageFiles}=await import('../.checks/deployment-rm8.mjs');
const {getExperienceProfile,validateExperience,experienceSummary}=await import('../.checks/experience-rm8.mjs');
test('RM8 isolates both catalogs, uses a distinct local UI port and has explicit one-way sync',()=>{
 const f=buildPackageFiles(8,'komtas-rm8-test',15459),r='rm8-kubernetes/';
 assert(f[r+'Connect-Catalog.ps1'].includes('$Port=18588'));assert(f[r+'Connect.ps1'].includes('15459'));
 assert(f[r+'k8s/governance-server.yaml']);assert(f[r+'cdgc/client.py'].includes('NoRedirect'));
 assert(f[r+'Sync-BusinessDefinitions.ps1']);assert(f[r+'bridge/bridge.py'].includes('externalWritePerformed'));assert(f[r+'Run-Scenario.ps1'].includes('RequireComplete'));
 const manifest=JSON.parse(f[r+'k8s/dual-verify-job.yaml']);assert.equal(manifest.metadata.namespace,'komtas-rm8-test');
 assert.equal(manifest.spec.template.spec.containers[0].command.at(-1),'verify');
 const profile=JSON.parse(f[r+'report-template.html'].match(/const profile=(.+);\n/)[1]);assert.equal(profile.architecture,'rm-8');assert.equal(profile.checks.length,34);assert.equal(new Set(profile.layers.map(l=>l.name)).size,profile.layers.length);
});
test('RM8 local catalog success never substitutes for eleven external and cross-catalog controls',()=>{
 const p=getExperienceProfile('rm-8');const r={schemaVersion:1,architecture:p.architecture,architectureVersion:p.architectureVersion,scenario:p.scenario,namespace:'komtas-rm8',generatedAt:new Date().toISOString(),executions:['01-kanal-geliri.sql','02-horeca-degisim.sql','03-distributor-urun.sql','verify.sql'].map(file=>({file,status:'passed'})),observation:{checks:p.checks.map(([id])=>({id,status:/^(cdgc_|dual_)/.test(id)?'not_tested':'passed'})),metrics:{janRevenue:8164.8,febRevenue:3628.8,janLiters:1844.64,febLiters:819.84,change:-4536}}};
 assert.deepEqual(experienceSummary(validateExperience(r)),{passed:27,failed:0,pending:11,total:38});
 r.observation.checks.find(c=>c.id==='om_owner').status='failed';assert.deepEqual(experienceSummary(validateExperience(r)),{passed:26,failed:1,pending:11,total:38});
});

import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/deployment.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/deployment-rm7.mjs'});
await build({entryPoints:['src/lib/experience.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/experience-rm7.mjs'});
const {buildPackageFiles}=await import('../.checks/deployment-rm7.mjs');
const {getExperienceProfile,validateExperience,experienceSummary}=await import('../.checks/experience-rm7.mjs');
test('RM7 isolates local services and uses external read-only CDGC without bundled credentials',()=>{
 const f=buildPackageFiles(7,'komtas-rm7-test',15458),r='rm7-kubernetes/';
 assert(f[r+'Common.ps1'].includes('komtas-rm7-test'));assert(f[r+'Connect.ps1'].includes('15458'));
 assert(f[r+'Connect-Docs.ps1'].includes('18107'));assert(f[r+'Set-InformaticaConnection.ps1'].includes('AsSecureString'));
 assert(f[r+'governance/client.py'].includes('NoRedirect'));assert(f[r+'governance/client.py'].includes('/data360/search/v1/assets/details'));
 assert(f[r+'k8s/governance-job.yaml'].includes('"optional": true'));assert(f[r+'Run-Scenario.ps1'].includes('RequireComplete'));
 assert(f[r+'run-scenario.sh'].includes('"architecture":"rm-7"'));assert.equal(JSON.parse(f[r+'governance/settings.json']).metrics.length,3);
 assert(!Object.keys(f).some(k=>k.includes('openmetadata')));assert(!f[r+'governance/settings.json'].includes('api-token'));
 const embedded=JSON.parse(f[r+'report-template.html'].match(/const profile=(.+);\n/)[1]);assert.equal(embedded.architecture,'rm-7');assert.equal(embedded.checks.length,23);
});
test('RM7 keeps seven external governance controls pending despite passing local metric evidence',()=>{
 const p=getExperienceProfile('rm-7');assert.equal(p.checks.length,23);
 const r={schemaVersion:1,architecture:p.architecture,architectureVersion:p.architectureVersion,scenario:p.scenario,namespace:'komtas-rm7',generatedAt:new Date().toISOString(),executions:['01-kanal-geliri.sql','02-horeca-degisim.sql','03-distributor-urun.sql','verify.sql'].map(file=>({file,status:'passed'})),observation:{checks:p.checks.map(([id])=>({id,status:id.startsWith('cdgc_')?'not_tested':'passed'})),metrics:{janRevenue:8164.8,febRevenue:3628.8,janLiters:1844.64,febLiters:819.84,change:-4536}}};
 assert.deepEqual(experienceSummary(validateExperience(r)),{passed:20,failed:0,pending:7,total:27});
 r.observation.checks.find(c=>c.id==='cdgc_owner').status='failed';assert.equal(experienceSummary(validateExperience(r)).failed,1);
});

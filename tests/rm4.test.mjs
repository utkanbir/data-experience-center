import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/deployment.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/deployment-rm4.mjs'});
await build({entryPoints:['src/lib/experience.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/experience-rm4.mjs'});
const {buildPackageFiles}=await import('../.checks/deployment-rm4.mjs');
const {getExperienceProfile,validateExperience,experienceSummary,executionFiles,layerStatus}=await import('../.checks/experience-rm4.mjs');
function report(){const p=getExperienceProfile('rm-4');return {schemaVersion:1,architecture:'rm-4',architectureVersion:p.architectureVersion,scenario:p.scenario,namespace:'komtas-rm4',generatedAt:'2026-11-08T23:00:00Z',executions:executionFiles.map(file=>({file,status:'passed'})),observation:{checks:p.checks.map(([id])=>({id,status:'passed'})),metrics:{janRevenue:8164.8,febRevenue:3628.8,janLiters:1844.64,febLiters:819.84,change:-4536}}};}
test('RM4 package isolates environment and includes authenticated Cube with two API consumers',()=>{
 const f=buildPackageFiles(4,'komtas-rm4-test',15446),r='rm4-kubernetes/';
 assert(f[r+'Common.ps1'].includes('komtas-rm4-test'));assert(f[r+'Connect.ps1'].includes('15446'));assert(f[r+'Connect-Docs.ps1'].includes('18095'));
 assert(f[r+'k8s/cube.yaml'].includes("CUBEJS_DEV_MODE, value: 'false'"));assert(!f[r+'k8s/cube.yaml'].includes('NodePort'));assert(f[r+'consumers/client.py'].includes("'Authorization':token()"));
 assert(f[r+'cube/schema/Sales.js'].includes('discount_amount_eur - return_amount_eur'));assert(f[r+'consumers/dashboard.py'].includes('from client import run_query'));assert(f[r+'consumers/verify.py'].includes('module.fetch_rows()'));
 assert(f[r+'Remove-Environment.ps1']);assert(f[r+'connect-dashboard.sh']);assert(f[r+'Run-Scenario.ps1'].includes('__CUBE_MATCH__'));assert(f[r+'run-scenario.sh'].includes('"architecture":"rm-4"'));
 assert(f[r+'report-template.html'].includes('REFERANS MİMARİ 4'));assert(f[r+'report-template.html'].includes('Python ve dashboard aynı API tanımını kullandı'));assert(!f[r+'powerbi/README.md']);assert(!f[r+'Connect.ps1'].includes('Power BI'));
});
test('RM4 requires consumer evidence and does not award governance on a green run',()=>{
 const p=getExperienceProfile('rm-4'),r=report();assert.equal(experienceSummary(validateExperience(r)).passed,20);
 const semantic=p.layers.find(l=>l.name==='Ortak executable semantic katman');assert.equal(layerStatus(semantic,r),'passed');
 r.observation.checks.find(c=>c.id==='two_consumers').status='failed';assert.equal(layerStatus(semantic,validateExperience(r)),'failed');assert.equal(experienceSummary(r).failed,1);
 assert.equal(layerStatus(p.layers.find(l=>l.name==='Governance ve metrik sahipliği'),r),'absent');r.observation.checks=r.observation.checks.filter(c=>c.id!=='api_auth');assert.throws(()=>validateExperience(r));
});
test('RM3 SQL access and report no longer advertise a Power BI component',()=>{
 const f=buildPackageFiles(3,'komtas-rm3',15434),r='rm3-kubernetes/';assert(!f[r+'Connect.ps1'].includes('Power BI'));assert(!f[r+'Show-Access.ps1'].includes('Power BI'));assert(!f[r+'show-access.sh'].includes('Power BI'));assert(f[r+'report-template.html'].includes('REFERANS MİMARİ 3'));assert(!f[r+'powerbi/README.md']);
 assert(!getExperienceProfile('rm-3').layers.some(l=>l.name.includes('Power BI')));
});

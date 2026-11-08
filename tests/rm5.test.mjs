import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/deployment.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/deployment-rm5.mjs'});
await build({entryPoints:['src/lib/experience.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/experience-rm5.mjs'});
await build({entryPoints:['src/lib/value-proposition.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/value-rm5.mjs'});
const {getValueMapping}=await import('../.checks/value-rm5.mjs');
const {buildPackageFiles}=await import('../.checks/deployment-rm5.mjs');
const {getExperienceProfile,validateExperience,experienceSummary,executionFiles,layerStatus}=await import('../.checks/experience-rm5.mjs');
function report(){const p=getExperienceProfile('rm-5');return {schemaVersion:1,architecture:'rm-5',architectureVersion:p.architectureVersion,scenario:p.scenario,namespace:'komtas-rm5',generatedAt:'2026-11-09T00:00:00Z',executions:executionFiles.map(file=>({file,status:'passed'})),observation:{checks:p.checks.map(([id])=>({id,status:'passed'})),metrics:{janRevenue:8164.8,febRevenue:3628.8,janLiters:1844.64,febLiters:819.84,change:-4536}}};}
test('RM5 contains independent metadata services, lifecycle and explicit API bridge',()=>{
 const f=buildPackageFiles(5,'komtas-rm5-test',15447),r='rm5-kubernetes/';assert(f[r+'Common.ps1'].includes('komtas-rm5-test'));assert(f[r+'Connect.ps1'].includes('15447'));assert(f[r+'Connect-Docs.ps1'].includes('18096'));
 const deps=JSON.parse(f[r+'k8s/governance-dependencies.yaml']);assert(deps.items.some(v=>v.kind==='StatefulSet'&&v.metadata.name==='metadata-postgres'));assert(deps.items.some(v=>v.kind==='StatefulSet'&&v.metadata.name==='elasticsearch'));
 const server=JSON.parse(f[r+'k8s/governance-server.yaml']);assert(server.items.find(v=>v.kind==='Service').spec.type==='ClusterIP');assert(f[r+'Connect-Catalog.ps1'].includes('--address=127.0.0.1'));assert(f[r+'Deploy.ps1'].includes('New-Rm5Password'));
 for(const name of ['sync-catalog.sh','verify-catalog.sh','restore-governance.sh','inject-governance-fault.sh','Remove-Environment.ps1'])assert(f[r+name]);
 assert(f[r+'governance/catalog.py'].includes("mode in ('sync','restore')"));assert(f[r+'governance/catalog.py'].includes("model=Path('/cube-model/Sales.js')"));assert(f[r+'Run-Scenario.ps1'].includes('Verify-Catalog.ps1'));assert(!f[r+'Run-Scenario.ps1'].includes('Sync-Catalog.ps1'));
 assert(f[r+'Stop.ps1'].includes('deployment/openmetadata'));assert(f[r+'Stop.ps1'].includes('statefulset/metadata-postgres'));assert(f[r+'Run-Scenario.ps1'].includes('__OM_OWNER__'));assert(f[r+'run-scenario.sh'].includes('"architecture":"rm-5"'));
});
test('RM5 separates successful metrics from failed governance and keeps lifecycle partial',()=>{
 const p=getExperienceProfile('rm-5'),r=report();assert.equal(experienceSummary(validateExperience(r)).passed,27);
 const governance=p.layers.find(l=>l.name==='Governance ve metrik sahipliği');assert.equal(layerStatus(governance,r),'partial');assert.equal(layerStatus(p.layers.find(l=>l.name==='Güvenilir data product'),r),'partial');
 r.observation.checks.find(c=>c.id==='om_owner').status='failed';assert.equal(experienceSummary(validateExperience(r)).failed,1);assert.equal(layerStatus(governance,r),'failed');assert.equal(layerStatus(p.layers.find(l=>l.name==='Ortak executable semantic katman'),r),'passed');
 r.observation.checks=r.observation.checks.filter(c=>c.id!=='om_lineage');assert.throws(()=>validateExperience(r));
});
test('RM5 governance evidence is measured separately rather than inferred from installation',()=>{
 const p=getExperienceProfile('rm-5'),r=report();for(const c of r.observation.checks)if(c.id.startsWith('om_'))c.status='not_tested';
 assert.equal(experienceSummary(validateExperience(r)).pending,7);assert.equal(layerStatus(p.layers.find(l=>l.name==='Governance ve metrik sahipliği'),r),'not_tested');assert.equal(p.designGrade,43.3);
 const f=buildPackageFiles(5,'komtas-rm5',15436),root='rm5-kubernetes/';assert(f[root+'report-template.html'].includes('REFERANS MİMARİ 5'));assert(f[root+'governance/catalog.py'].includes("connection.execute('SELECT count(*) FROM dwh.fact_sales')"));assert(f[root+'governance/catalog.py'].includes("access_token=login(desired)"));
});

test('Business360 reports missing ownership even when the shared metric API passes',()=>{
 const r=report(),components=['pg','core','cube','om','py','cli'];
 const healthy=getValueMapping({components},r).find(v=>v.id==='business');assert(healthy.evidence.includes('owner'));
 r.observation.checks.find(c=>c.id==='om_owner').status='failed';
 const broken=getValueMapping({components},r).find(v=>v.id==='business');assert(broken.evidence.includes('governance eksikliğini kapatmaz'));assert(broken.evidence.includes('referansla eşleşti'));
});

test('Windows evidence copying uses a relative target to avoid kubectl drive-letter ambiguity',()=>{
 for(const id of [2,3,4,5]){
  const f=buildPackageFiles(id,'komtas-evidence-test',15440),script=f['rm'+id+'-kubernetes/Run-Scenario.ps1'];
  assert(script.includes('Push-Location -LiteralPath $taskEvidenceDir'));assert(script.includes('("./" + $taskArtifact)'));assert(script.includes('Pop-Location'));assert(!script.includes('cp "rm'+id+'-artifacts:/artifacts/$taskArtifact" (Join-Path'));
 }
});

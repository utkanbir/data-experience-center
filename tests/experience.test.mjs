import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/experience.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/experience.mjs'});
const {profile,validateExperience,experienceSummary,layerStatus,executionFiles}=await import('../.checks/experience.mjs');
const fixture=()=>({schemaVersion:1,architecture:profile.architecture,architectureVersion:profile.architectureVersion,scenario:profile.scenario,generatedAt:'2026-11-08T22:00:00Z',namespace:'komtas-test',executions:executionFiles.map(file=>({file,status:'passed'})),observation:{checks:profile.checks.map(([id])=>({id,status:'passed'})),metrics:{janRevenue:8164.8,febRevenue:3628.8,janLiters:1844.64,febLiters:819.84,change:-4536}}});
test('passing checks never award governance or Power BI verification',()=>{
 const r=validateExperience(fixture());assert.equal(experienceSummary(r).passed,12);
 assert.equal(layerStatus(profile.layers.find(l=>l.name==='Governance ve metrik sahipliği'),r),'absent');
 assert.equal(layerStatus(profile.layers.find(l=>l.name==='BI tüketimi · Power BI'),r),'not_tested');
 assert.equal(layerStatus(profile.layers.find(l=>l.name==='Kalite ve değişim yönetimi'),r),'partial');
});
test('database failure leaves observations untested and executions failed',()=>{
 const r=fixture();r.observation=null;r.executions.forEach(e=>e.status='failed');const summary=experienceSummary(validateExperience(r));assert.equal(summary.failed,4);assert.equal(summary.pending,8);assert.equal(summary.passed,0);
 assert.equal(layerStatus(profile.layers[0],r),'not_tested');
});
test('failed evidence marks the related layer failed',()=>{
 const r=fixture();r.observation.checks.find(c=>c.id==='horeca').status='failed';assert.equal(layerStatus(profile.layers.find(l=>l.name==='Raporlama hesapları'),r),'failed');
});
test('incomplete and duplicate evidence cannot appear as a successful run',()=>{
 for(const mutate of [r=>r.executions.pop(),r=>r.observation.checks.pop(),r=>r.observation.checks[0].id=r.observation.checks[1].id,r=>r.observation.checks[0].status='whatever',r=>r.architectureVersion='unknown',r=>r.observation.metrics.change='-4536']){const r=fixture();mutate(r);assert.throws(()=>validateExperience(r));}
});

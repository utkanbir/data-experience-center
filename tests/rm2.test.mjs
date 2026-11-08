import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/deployment.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/deployment.mjs'});
const {buildPackageFiles}=await import('../.checks/deployment.mjs');
await build({entryPoints:['src/lib/experience.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/experience-rm2.mjs'});
const {getExperienceProfile,validateExperience,experienceSummary,executionFiles,layerStatus}=await import('../.checks/experience-rm2.mjs');
test('RM2 package is isolated and contains actual dbt models and lifecycle scripts',()=>{
 const files=buildPackageFiles(2,'komtas-rm2-test',15444),root='rm2-kubernetes/';
 assert(files[root+'Common.ps1'].includes("'komtas-rm2-test'"));assert(files[root+'Connect.ps1'].includes('15444'));
 assert(files[root+'Deploy.ps1'].includes('Build-Models.ps1'));
 assert(files[root+'sql/seed.sql'].includes('raw.sales_line'));assert(!files[root+'sql/seed.sql'].includes('CREATE TABLE IF NOT EXISTS dwh.fact_sales'));
 assert(files[root+'dbt/models/marts/fact_sales.sql'].includes("ref('stg_sales')"));
 assert(files[root+'k8s/dbt-job.yaml'].includes('rm2_dbt'));assert(files[root+'Remove-Environment.ps1']);assert(files[root+'remove-environment.sh']);
 assert(files[root+'Run-Scenario.ps1'].includes('__DBT_MODELS__'));
 assert(buildPackageFiles(1,'komtas-rm1',15432)['rm1-kubernetes/Common.ps1'].includes("'komtas-rm1'"));
 assert.throws(()=>buildPackageFiles(3,'komtas-test',15444));
});
test('RM2 report requires dbt evidence and keeps governance out of scope',()=>{
 const p=getExperienceProfile('rm-2');const r={schemaVersion:1,architecture:'rm-2',architectureVersion:p.architectureVersion,scenario:p.scenario,namespace:'komtas-rm2',generatedAt:'2026-11-08T22:00:00Z',executions:executionFiles.map(file=>({file,status:'passed'})),observation:{checks:p.checks.map(([id])=>({id,status:'passed'})),metrics:{janRevenue:8164.8,febRevenue:3628.8,janLiters:1844.64,febLiters:819.84,change:-4536}}};
 assert.equal(experienceSummary(validateExperience(r)).passed,15);
 assert.equal(layerStatus(p.layers.find(l=>l.name==='Governance ve metrik sahipliği'),r),'absent');
 r.observation.checks.find(c=>c.id==='dbt_tests').status='failed';assert.equal(layerStatus(p.layers[1],validateExperience(r)),'failed');
 r.observation.checks=r.observation.checks.filter(c=>c.id!=='dbt_tests');assert.throws(()=>validateExperience(r));
});

test('RM2 preserves failed dbt evidence when the serving view is unavailable',()=>{
 const p=getExperienceProfile('rm-2');const r={schemaVersion:1,architecture:'rm-2',architectureVersion:p.architectureVersion,scenario:p.scenario,namespace:'komtas-rm2',generatedAt:'2026-11-08T22:00:00Z',executions:executionFiles.map(file=>({file,status:'failed'})),observation:{checks:p.checks.map(([id])=>({id,status:id==='dbt_tests'?'failed':'not_tested'})),metrics:{janRevenue:null,febRevenue:null,janLiters:null,febLiters:null,change:null}}};
 const valid=validateExperience(r);assert.equal(experienceSummary(valid).failed,5);assert.equal(layerStatus(p.layers[1],valid),'failed');
});

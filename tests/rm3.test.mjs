import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/deployment.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/deployment-rm3.mjs'});
await build({entryPoints:['src/lib/experience.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/experience-rm3.mjs'});
const {buildPackageFiles}=await import('../.checks/deployment-rm3.mjs');
const {getExperienceProfile,validateExperience,experienceSummary,executionFiles,layerStatus}=await import('../.checks/experience-rm3.mjs');
test('RM3 package contains semantic definitions and keeps namespace and ports isolated',()=>{
 const f=buildPackageFiles(3,'komtas-rm3-test',15445),r='rm3-kubernetes/';assert(f[r+'Common.ps1'].includes('komtas-rm3-test'));assert(f[r+'Connect.ps1'].includes('15445'));assert(f[r+'Connect-Docs.ps1'].includes('18094'));assert(f[r+'dbt/models/metrics.yml'].includes('type: ratio'));assert(f[r+'runner.py'].includes('dbt-metricflow==0.11.0'));assert(f[r+'Set-MetricFault.ps1']);assert(f[r+'remove-environment.sh']);
});
test('semantic mismatch fails the semantic layer while model tests can pass',()=>{
 const p=getExperienceProfile('rm-3'),r={schemaVersion:1,architecture:'rm-3',architectureVersion:p.architectureVersion,scenario:p.scenario,namespace:'komtas-rm3',generatedAt:'2026-11-08T22:00:00Z',executions:executionFiles.map(file=>({file,status:'passed'})),observation:{checks:p.checks.map(([id])=>({id,status:id==='mf_match'?'failed':'passed'})),metrics:{janRevenue:8164.8,febRevenue:3628.8,janLiters:1844.64,febLiters:819.84,change:-4536}}};
 assert.equal(experienceSummary(validateExperience(r)).failed,1);assert.equal(layerStatus(p.layers.find(l=>l.name==='Ortak executable semantic katman'),r),'failed');r.observation.checks.find(c=>c.id==='mf_match').status='passed';assert.equal(experienceSummary(validateExperience(r)).passed,18);assert.equal(layerStatus(p.layers.find(l=>l.name==='Ortak executable semantic katman'),r),'partial');
});
test('MetricFlow reference check is required in imported evidence',()=>{
 const p=getExperienceProfile('rm-3');assert.equal(p.checks.length,14);const template=JSON.parse(fs.readFileSync('src/lib/rm3-template.json','utf8'));assert(template['Run-Scenario.ps1'].includes('__MF_MATCH__'));assert(template['run-scenario.sh'].includes('mf_match'));
});

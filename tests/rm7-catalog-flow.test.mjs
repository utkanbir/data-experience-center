import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/deployment.ts','src/lib/scenario-integration.ts'],bundle:true,platform:'node',format:'esm',outdir:'.checks/catalog-flow'});
const {buildPackageFiles}=await import('../.checks/catalog-flow/deployment.js');
const {scenarioIntegration}=await import('../.checks/catalog-flow/scenario-integration.js');
test('RM7 packages the catalog-first dashboard and live secret/config mounts',()=>{const f=buildPackageFiles(7,'komtas-flow-test',15550),r='rm7-kubernetes/';assert(f[r+'consumers/dashboard.py'].includes('execute_selected'));assert(f[r+'consumers/catalog_flow.py'].includes('records = loader()'));assert(f[r+'k8s/dashboard.yaml'].includes('secretName: rm7-informatica'));assert(f[r+'k8s/dashboard.yaml'].includes('configMap: {name: rm7-governance}'));assert(f[r+'Update-Experience.ps1'].includes('deployment/dashboard'));assert(!f[r+'Update-Experience.ps1'].includes('seed'));assert(f[r+'KATALOGDAN_ANALIZE.md'].includes('catalog-analysis.json'));assert(f[r+'VALIDATION.md'].includes('çalıştırılmadı'));});
test('ready architectures distinguish user flow from standalone catalog and graph checks',()=>{for(let id=1;id<=10;id++)assert(scenarioIntegration[id]);for(const id of [5,8,9,10])assert.equal(scenarioIntegration[id].state,'Kısmi entegrasyon');for(let id=1;id<=10;id++)assert(buildPackageFiles(id,'komtas-audit-test',15550)['rm'+id+'-kubernetes/SENARYO_BUTUNLUGU.md']);});

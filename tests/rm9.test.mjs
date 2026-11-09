import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/deployment.ts','src/lib/experience.ts','src/lib/component-story.ts','src/lib/domain.ts','src/lib/value-proposition.ts'],bundle:true,platform:'node',format:'esm',outdir:'.checks/rm9'});
const {buildPackageFiles}=await import('../.checks/rm9/deployment.js');
const {getExperienceProfile,validateExperience,experienceSummary}=await import('../.checks/rm9/experience.js');
const {componentStories}=await import('../.checks/rm9/component-story.js');
const {architectures}=await import('../.checks/rm9/domain.js');
const {getValueMapping}=await import('../.checks/rm9/value-proposition.js');
test('RM9 keeps two physical sources and all dbt models are Trino views',()=>{
 const f=buildPackageFiles(9,'komtas-federation-test',15440),r='rm9-kubernetes/';
 assert(/CREATE TABLE (IF NOT EXISTS )?raw.sales_line/.test(f[r+'sql/seed.sql']));
 assert(!/CREATE TABLE (IF NOT EXISTS )?raw.dim_/.test(f[r+'sql/seed.sql']));
 assert(/CREATE TABLE (IF NOT EXISTS )?raw.dim_outlet/.test(f[r+'sql/seed-reference.sql']));
 assert(!/CREATE TABLE (IF NOT EXISTS )?raw.sales_line/.test(f[r+'sql/seed-reference.sql']));
 assert(f[r+'dbt/dbt_project.yml'].includes('view'));assert(!f[r+'dbt/dbt_project.yml'].includes('table'));
 const catalogs=JSON.parse(f[r+'trino/config.json']);
 assert(catalogs['sales.properties'].includes('postgres:5432'));assert(catalogs['reference.properties'].includes('postgres-reference:5432'));
 assert(catalogs['models.properties'].includes('connector.name=memory'));
 assert(f[r+'cube/schema/Sales.js'].includes('models.dwh.v_sales_detail'));
 assert(f[r+'cube/schema/Sales.js'].includes('SELECT CAST(uuid() AS VARCHAR)'));
 assert.equal(JSON.parse(f[r+'consumers/query.json']).renewQuery,true);
 assert(f[r+'consumers/client.py'].includes("'cache':'must-revalidate'"));
 assert(f[r+'Break-Reference.ps1']);assert(f[r+'Restore-Reference.ps1']);assert(!f[r+'Set-DemoFault.ps1']);
 assert(f[r+'Show-Access.ps1'].includes('Get-Connections'));assert(JSON.parse(f[r+'connections.json']).services.some(s=>s.id==='reference'));
});
test('RM9 source and docs port substitutions do not alias each other at boundaries',()=>{
 for(const port of [16440,18089,65535]){
  const f=buildPackageFiles(9,'komtas-port-test',port),r='rm9-kubernetes/';
  assert(f[r+'Connect.ps1'].includes(String(port)));
  assert(f[r+'Connect-Reference.ps1'].includes(String(port<=64535?port+1000:port-1000)));
  assert(f[r+'Connect-Docs.ps1'].includes(String(port<=62886?port+2649:port-2649)));
  assert(!Object.values(f).some(t=>/__REFERENCE_PORT__|__DATABASE_PORT__|__DOCS_PORT__/.test(t)));
 }
});
test('RM9 reports 33 measured controls and cannot hide failed federation behind correct metrics',()=>{
 const p=getExperienceProfile('rm-9');assert.equal(p.checks.length,29);
 const result={schemaVersion:1,architecture:p.architecture,architectureVersion:p.architectureVersion,scenario:p.scenario,namespace:'komtas-rm9-test',generatedAt:new Date().toISOString(),executions:['01-kanal-geliri.sql','02-horeca-degisim.sql','03-distributor-urun.sql','verify.sql'].map(file=>({file,status:'passed'})),observation:{checks:p.checks.map(([id])=>({id,status:'passed'})),metrics:{janRevenue:8164.8,febRevenue:3628.8,janLiters:1844.64,febLiters:819.84,change:-4536}}};
 assert.deepEqual(experienceSummary(validateExperience(result)),{passed:33,failed:0,pending:0,total:33});
 result.observation.checks.find(c=>c.id==='federated_join').status='failed';
 assert.equal(experienceSummary(validateExperience(result)).failed,1);
 assert(getValueMapping(architectures.find(a=>a.id===9),result)[0].evidence.includes('1 başarısız'));
});
test('RM9 component guide describes actual cross-source work rather than a planned central warehouse',()=>{
 const stories=componentStories(architectures.find(a=>a.id===9));
 assert(stories.find(s=>s.id==='core').output.includes('Yedi VIEW'));
 assert(stories.find(s=>s.id==='trino').evidence.includes('federation_plan'));
 assert(stories.find(s=>s.id==='om').inspect.some(i=>i.look.includes('RM9Trino.models.dwh.v_sales_detail')));
 assert(!stories.some(s=>s.id==='infa'||s.id==='pb'));
});

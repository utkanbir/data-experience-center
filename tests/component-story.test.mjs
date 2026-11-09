import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/component-story.ts','src/lib/domain.ts','src/lib/experience.ts','src/lib/deployment.ts'],bundle:true,platform:'node',format:'esm',outdir:'.checks/component-story'});
const {architectures}=await import('../.checks/component-story/domain.js');
const {componentStories}=await import('../.checks/component-story/component-story.js');
const {getExperienceProfile}=await import('../.checks/component-story/experience.js');
const {buildPackageFiles}=await import('../.checks/component-story/deployment.js');
test('every reference component has scenario-specific work, inspection guidance and explicit limits',()=>{
 for(const a of architectures){const stories=componentStories(a);assert.deepEqual(stories.map(s=>s.id),a.components);for(const s of stories){assert(s.purpose&&s.input&&s.output&&s.example&&s.boundary);assert(s.work.length>=3);assert(s.inspect.length>0);if(a.ready){const ids=new Set(getExperienceProfile(a.key).checks.map(c=>c[0]));for(const id of s.evidence)assert(ids.has(id),a.key+' '+s.id+' '+id);}}}
});
test('RM5 explains dbt model preparation, Cube calculation and metadata ownership as separate jobs',()=>{
 const stories=componentStories(architectures.find(a=>a.id===5));const om=stories.find(s=>s.id==='om'),core=stories.find(s=>s.id==='core');
 assert(core.example.includes('net_volume_liters'));assert(core.boundary.includes('metric API değildir'));assert(om.example.includes('om_owner'));assert(om.boundary.includes('metrik motoru değildir'));assert(om.inspect.some(i=>i.where.includes('RM5Postgres.komtas_rm5.dwh.v_sales_detail')));
});
test('generated packages carry the same educational guide and RM6 preserves the external BI boundary',()=>{
 for(const a of architectures.filter(a=>a.ready)){const guide=buildPackageFiles(a.id,'komtas-guide-test',15500)['rm'+a.id+'-kubernetes/BILESENLER.md'];assert(guide);for(const s of componentStories(a))assert(guide.includes(s.purpose));}
 const pb=componentStories(architectures.find(a=>a.id===6)).find(s=>s.id==='pb');assert(pb.input.includes('dbt Semantic'));assert.deepEqual(pb.evidence,['sl_powerbi']);
});

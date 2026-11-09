import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/component-walkthrough.ts','src/lib/domain.ts','src/lib/deployment.ts'],bundle:true,platform:'node',format:'esm',outdir:'.checks/walkthrough'});
const {architectures}=await import('../.checks/walkthrough/domain.js');
const {componentWalkthroughs,walkthroughMarkdown}=await import('../.checks/walkthrough/component-walkthrough.js');
const {buildPackageFiles}=await import('../.checks/walkthrough/deployment.js');
test('every ready component has actionable steps, expected results, meaning and recovery',()=>{
 for(const a of architectures){const guides=componentWalkthroughs(a);if(!a.ready){assert.equal(guides.length,0);continue;}assert.deepEqual(guides.map(g=>g.id),a.components);for(const g of guides){assert(g.entry&&g.steps.length>=2,g.id);for(const s of g.steps)assert(s.title&&s.actions.length&&s.expected&&s.meaning&&s.missing);}}
});
test('RM9 starts Trino exploration with finished queries and preserves separate source connections',()=>{
 const a=architectures.find(a=>a.id===9),g=componentWalkthroughs(a,15550);assert.match(g.find(g=>g.id==='trino').steps[0].title,/FINISHED/);const md=walkthroughMarkdown(a,15550);assert.match(md,/15550/);assert.match(md,/rm9_reader/);assert.match(md,/komtas_rm9_reference/);assert.match(md,/models.dwh/);
});
test('all ready ZIP packages include their matching walkthrough',()=>{
 for(const a of architectures.filter(a=>a.ready)){const guide=buildPackageFiles(a.id,'komtas-explore-test',15550)['rm'+a.id+'-kubernetes/KESIF_REHBERI.md'];assert.equal(guide,walkthroughMarkdown(a,15550));for(const g of componentWalkthroughs(a,15550))assert(guide.includes(g.steps[0].title));}
});

import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await fs.mkdir('.checks',{recursive:true});
await build({entryPoints:['src/lib/domain.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/domain.mjs'});
await build({entryPoints:['src/lib/zip.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/zip.mjs'});
const {architectures,technologies,evaluate,recommend,validateDraft}=await import('../.checks/domain.mjs');
const {zipFiles}=await import('../.checks/zip.mjs');
assert.equal(architectures.length,14);assert.equal(technologies.length,15);assert.equal(architectures.filter(a=>a.ready).length,5);
for(const a of architectures){assert.equal(a.scores.length,11);assert.equal(a.scores[3],null);assert.equal(a.grade,Math.round(a.scores.reduce((s,n)=>s+(n??0),0)/30*1000)/10);for(const c of a.components)assert(technologies.some(t=>t.id===c));}
const base={components:['pg','core','pb'],pgCount:1,ontology:false};assert.equal(evaluate(base).scores[1],0);
assert.equal(evaluate({...base,components:['pg','mf','cli']}).scores[1],1);
assert.equal(evaluate({...base,components:['pg','trino']}).scores[2],0);
assert.equal(evaluate({...base,components:['pg','trino'],pgCount:2}).scores[2],3);
const graph=evaluate({...base,components:['pg','neo','py']});assert.equal(graph.scores[8],0);assert.equal(graph.scores[10],0);
const needs={text:'',shared:true,multi:false,keep:false,governance:true,graph:false,localOnly:true,openOnly:true};assert.equal(recommend(needs)[0].architecture.id,5);
assert.equal(recommend({...needs,multi:true,keep:true})[0].architecture.id,9);
assert.equal(recommend({...needs,graph:true})[0].architecture.id,10);
for(const r of recommend(needs))assert.equal(r.architecture.category,'local');
const draft=validateDraft({name:'Test',components:['pg'],pgCount:99,custom:[],notes:'',ontology:false});assert.equal(draft.pgCount,1);
assert.throws(()=>validateDraft({name:'Test',components:['missing']}));
const custom=validateDraft({name:'Test',components:['custom-x'],custom:[{id:'custom-x',name:'X',source:'https://example.com',docker:true,license:{unsafe:true}}]});assert.equal(custom.custom[0].docker,null);assert.equal(typeof custom.custom[0].license,'string');
const template=JSON.parse(await fs.readFile('src/lib/rm1-template.json','utf8')),files={};for(const [path,text]of Object.entries(template))files['rm1-kubernetes/'+path]=text.replaceAll('komtas-rm1','komtas-validation').replaceAll('15432','15433');
await fs.writeFile('.checks/generated.zip',zipFiles(files));
assert(files['rm1-kubernetes/Common.ps1'].includes("'komtas-validation'"));assert(files['rm1-kubernetes/Connect.ps1'].includes('15433'));assert(files['rm1-kubernetes/k8s/postgres.yaml'].includes('namespace: komtas-validation'));
console.log('PASS: catalog integrity, score formula, rule boundaries, constrained recommendation, imported draft sanitization, configurable RM1 ZIP');


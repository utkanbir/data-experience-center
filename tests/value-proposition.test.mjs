import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import vm from 'node:vm';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/value-proposition.ts'],bundle:true,platform:'node',format:'esm',outfile:'.checks/value-proposition.mjs'});
const {getValueMapping,roleMatchesValue}=await import('../.checks/value-proposition.mjs');
test('BI-local metrics do not become a shared Business360 service',()=>{
 const m=getValueMapping({components:['pg','pb']});assert.equal(m[1].status,'Başlangıç katkısı');assert.match(m[1].contribution,/ortak kurumsal metrik servisi değildir/);assert.equal(m[2].status,'Kapsam dışı');
});
test('dbt contributes engineering and does not prove enterprise context or agents',()=>{
 const result={observation:{checks:['schemas','rows','months','horeca','volume','price','bi_role','no_insert','dbt_models','dbt_tests','dbt_docs'].map(id=>({id,status:'passed'}))}};
 const m=getValueMapping({components:['pg','core','pb','py','cli']},result);assert.match(m[0].evidence,/11 geçti/);assert.match(m[1].evidence,/doğrulanmaz/);assert.equal(m[2].status,'Kapsam dışı');assert.equal(roleMatchesValue('ai','agent',false),false);assert.equal(roleMatchesValue('ai','agent',true),true);
});
test('failed and missing evidence stays distinct from planned contribution',()=>{
 const m=getValueMapping({components:['pg','core','pb']},{observation:{checks:[{id:'dbt_tests',status:'failed'}]}});assert.match(m[0].evidence,/0 geçti, 1 başarısız, 10 ölçülemedi/);assert.match(m[1].evidence,/ölçülemeyen/);
});
test('both packaged HTML reports contain the shared value mapping once',async()=>{
 const rm1=JSON.parse(await fs.readFile('src/lib/rm1-template.json','utf8'));for(const text of [rm1['report-template.html'],await fs.readFile('packages/rm2/report-template.html','utf8')]){assert.equal(text.split('id="komtas-value-cards"').length,2);assert.match(text,/KomtasValue.getValueMapping/);}
});
test('offline HTML renders three value cards from actual report checks',async()=>{
 const rm1=JSON.parse(await fs.readFile('src/lib/rm1-template.json','utf8'));
 const result={namespace:'komtas-test',generatedAt:'2026-11-08T22:00:00Z',architectureVersion:'1.0',executions:[],observation:{checks:['schemas','rows','months','horeca','volume','price','bi_role','no_insert'].map(id=>({id,status:'passed'})),metrics:{janRevenue:8164.8,febRevenue:3628.8}}};
 const html=rm1['report-template.html'].replace('__RESULT_BASE64__',Buffer.from(JSON.stringify(result)).toString('base64'));
 const nodes=new Map(),node=()=>({children:[],style:{},textContent:'',append(n){this.children.push(n);}});
 const document={getElementById(id){if(!nodes.has(id))nodes.set(id,node());return nodes.get(id);},createElement:node};
 const context=vm.createContext({document,window:{},TextDecoder,Uint8Array,atob});
 for(const match of html.matchAll(/<script>([\s\S]*?)<\/script>/g))new vm.Script(match[1]).runInContext(context);
 const cards=nodes.get('komtas-value-cards').children;assert.equal(cards.length,3);assert(cards[0].children.some(n=>n.textContent==='Data360'));assert(cards[2].children.some(n=>n.textContent==='Kapsam dışı'));
});

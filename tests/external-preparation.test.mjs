import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
await build({entryPoints:['src/lib/external-preparation.ts','src/lib/deployment.ts','src/lib/domain.ts','src/lib/external-connections.ts'],bundle:true,platform:'node',format:'esm',outdir:'.checks/preparation'});
const {preparations,preparationMarkdown}=await import('../.checks/preparation/external-preparation.js');
const {buildPackageFiles}=await import('../.checks/preparation/deployment.js');
const {architectures}=await import('../.checks/preparation/domain.js');
const {servicesFor,emptyExternalSetup}=await import('../.checks/preparation/external-connections.js');
test('every external service has explicit preparatory actions and expected results',()=>{for(const a of architectures)for(const s of servicesFor(a)){const p=preparations[s.id];assert(p&&p.steps.length>=2);for(const step of p.steps)assert(step.actions.length&&step.expected);}});
test('RM7 and RM8 include the same full governance prerequisites with or without form overrides',()=>{for(const id of [7,8])for(const external of [undefined,emptyExternalSetup()]){const files=buildPackageFiles(id,'komtas-prep-test',15500,undefined,external),md=files['rm'+id+'-kubernetes/DIS_SERVIS_ON_HAZIRLIK.md'];assert.equal(md,preparationMarkdown(['infa']));for(const phrase of ['Net Revenue','Net Liters','Average Price','View Only','Published','ACCEPTED','internal assetId','Run-Governance','currentOrgId'])assert(md.includes(phrase),phrase);}});
test('RM6 requires real external deployment and future cloud profiles remain plans',()=>{assert.match(buildPackageFiles(6,'komtas-prep-test',15500)['rm6-kubernetes/DIS_SERVIS_ON_HAZIRLIK.md'],/port-forward/);for(const id of ['snow','bq','dbx'])assert.match(preparations[id].intro,/otomatik deploy paketi henüz yok/);});

test('Informatica instructions name the observed menu path and distinguish Metric from Business Term',()=>{const md=preparationMarkdown(['infa']);for(const text of ['New → Business Glossary → Metric → Create','Business Term seçili','Name / ad','Description / açıklama','Üç adı tek kayıt içine yazma'])assert(md.includes(text),text);});

import profile from './experience-profile.json';
export {profile};
export const executionFiles=['01-kanal-geliri.sql','02-horeca-degisim.sql','03-distributor-urun.sql','verify.sql'];
export type ResultStatus='passed'|'failed'|'not_tested';
export type Experience={schemaVersion:1;architecture:string;architectureVersion:string;scenario:string;generatedAt:string;namespace:string;executions:{file:string;status:ResultStatus}[];observation:{checks:{id:string;status:ResultStatus}[];metrics:Record<string,number>}|null};
export function validateExperience(value:unknown):Experience{
 if(!value||typeof value!=='object')throw Error('Geçerli bir deney JSON dosyası seç.');
 const v=value as Experience;
 if(v.schemaVersion!==1||v.architecture!==profile.architecture||v.architectureVersion!==profile.architectureVersion||v.scenario!==profile.scenario)throw Error('Bu raporun mimari, senaryo veya sürümü desteklenmiyor. Güncel RM1 paketiyle yeniden üret.');
 if(typeof v.generatedAt!=='string'||!Number.isFinite(Date.parse(v.generatedAt))||typeof v.namespace!=='string'||!/^komtas-[a-z0-9-]{1,40}$/.test(v.namespace))throw Error('Rapor tarihi veya namespace geçersiz.');
 const statuses=['passed','failed','not_tested'];
 if(!Array.isArray(v.executions)||v.executions.length!==executionFiles.length||executionFiles.some(f=>v.executions.filter(e=>e?.file===f&&statuses.includes(e.status)).length!==1))throw Error('Sorgu çalıştırma kayıtları eksik veya geçersiz.');
 if(v.observation!==null){
  if(!v.observation||!Array.isArray(v.observation.checks)||v.observation.checks.length!==profile.checks.length||profile.checks.some(([id])=>v.observation!.checks.filter(c=>c?.id===id&&['passed','failed'].includes(c.status)).length!==1))throw Error('Kontrol kanıtları eksik veya geçersiz.');
  if(!v.observation.metrics||['janRevenue','febRevenue','janLiters','febLiters','change'].some(k=>typeof v.observation!.metrics[k]!=='number'||!Number.isFinite(v.observation!.metrics[k])))throw Error('Metrik çıktısı geçersiz.');
 }
 return {schemaVersion:1,architecture:v.architecture,architectureVersion:v.architectureVersion,scenario:v.scenario,generatedAt:v.generatedAt,namespace:v.namespace,executions:v.executions.map(e=>({file:e.file,status:e.status})),observation:v.observation?{checks:v.observation.checks.map(c=>({id:c.id,status:c.status})),metrics:Object.fromEntries(['janRevenue','febRevenue','janLiters','febLiters','change'].map(k=>[k,v.observation!.metrics[k]]))}:null};
}
export function experienceSummary(r:Experience){
 const checks=profile.checks.map(([id])=>r.observation?.checks.find(c=>c.id===id)?.status??'not_tested');
 const states=[...checks,...r.executions.map(e=>e.status)];
 return {passed:states.filter(s=>s==='passed').length,failed:states.filter(s=>s==='failed').length,pending:states.filter(s=>s==='not_tested').length,total:states.length};
}
export function layerStatus(layer:typeof profile.layers[number],r:Experience){
 if(layer.scope==='absent')return 'absent';
 if(layer.scope==='pending')return 'not_tested';
 const states=layer.checks.map(id=>r.observation?.checks.find(c=>c.id===id)?.status??'not_tested');
 if(states.includes('failed'))return 'failed';
 if(states.includes('not_tested'))return 'not_tested';
 return layer.scope==='partial'?'partial':'passed';
}

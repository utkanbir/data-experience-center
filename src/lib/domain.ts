import source from './catalog.json';
export type Technology={id:string;name:string;deployment:string;needs:string;layer:string;docker:boolean|null;access:string;edition:string;source:string;license:string;reviewed:string;evidence:string};
export type Architecture={id:number;key:string;title:string;engine:string;gov:string;backend:string;scores:(number|null)[];components:string[];goal:string;flow:string;plus:string[];minus:string[];decision:string;category:string;grade:number;ready:boolean;version:string;status:string;graph?:boolean};
export type Draft={id:string;name:string;components:string[];pgCount:number;ontology:boolean;notes:string;created:string;custom:Technology[]};
export const architectures=source.architectures as Architecture[];
export const technologies=source.technologies as Technology[];
export const requirements=[['S1','Doğru raporlama'],['S2','Ortak executable metrik'],['S3','Dağıtık veriyle hesap'],['S4','Veri yerleşimi seçeneği'],['S5','Governed metrik tanımı'],['S6','İş tanımı–hesap eşlemesi'],['S7','Güvenilir veri ürünü'],['S8','Kalite ve değişim yönetimi'],['S9','Ontology'],['S10','Knowledge graph'],['S11','Kanıta dayalı AI']];
export const layers:Record<string,string>={data:'Veri platformu',access:'Veri erişimi',engineering:'Modelleme ve test',semantic:'Ortak metrik',governance:'Governance',context:'Ontology ve graph',consumption:'Tüketim'};
export const categoryLabels:Record<string,string>={local:'Yerel mimari',hybrid:'Yerel + dış servis',cloud:'Gerçek bulut'};
export function grade(scores:(number|null)[]){return Math.round(scores.reduce<number>((s,n)=>s+(n??0),0)/30*1000)/10;}
export function evaluate(d:Pick<Draft,'components'|'pgCount'|'ontology'>){
 const has=(k:string)=>d.components.includes(k),data=['pg','bq','snow','dbx'].filter(has),consumers=['pb','py','cli'].some(has),metric=has('cube')||has('paid'),gov=has('om')||has('infa');
 const sources=data.length+(has('pg')?d.pgCount-1:0);
 const sharedConsumers=has('py')||['pb','cli'].filter(has).length>=2;
 const scores=[data.length&&consumers?3:0,metric?data.length&&sharedConsumers?3:1:has('mf')?1:0,has('trino')&&sources>=2?3:0,null,has('infa')?3:has('om')?2:0,gov&&metric?has('om')&&has('infa')?2:1:0,has('om')?2:has('infa')?1:0,has('om')?2:has('core')?1:0,d.ontology?1:0,has('neo')?1:0,0];
 const findings:{kind:'warning'|'info';text:string}[]=[];
 if(!data.length)findings.push({kind:'warning',text:'Bir veri platformu seçilmedi.'});
 if(!consumers)findings.push({kind:'warning',text:'BI, dashboard veya CLI tüketicisi seçilmedi.'});
 if(metric&&!sharedConsumers)findings.push({kind:'warning',text:'Ortak metrik servisinin yeniden kullanımını göstermek için iki bağımsız tüketici yolu tanımlanmalı.'});
 if(has('core')&&!metric&&!has('mf'))findings.push({kind:'info',text:'dbt Core modelleme/test sağlar. Ortak metric servisi bu taslakta yok.'});
 if(has('mf')&&!metric)findings.push({kind:'info',text:'Yerel MetricFlow için CLI/Python sorgusu hedeflenir. Yönetilen semantic API ayrıca gerekir.'});
 if(sources>=2&&!has('trino'))findings.push({kind:'warning',text:'Birden fazla kaynak var. Birleştirme için merkezi veri taşıma veya desteklenen federasyon yolu tanımlanmalı.'});
 if(has('trino')&&sources<2)findings.push({kind:'info',text:'Trino seçildi ancak iki bağımsız kaynak henüz tanımlı değil.'});
 if(has('cube')&&has('pb'))findings.push({kind:'warning',text:'Cube Core → Power BI bağlantısı bu katalogda doğrulanmış hazır yol değil. REST tüketicisi veya ayrı doğrulanmış bağlantı profili seç.'});
 if(has('paid')&&has('mf'))findings.push({kind:'info',text:'Yerel MetricFlow ve yönetilen dbt Semantic farklı erişim modelleridir; rollerini ayır.'});
 if(has('om')&&has('infa'))findings.push({kind:'warning',text:'İki katalog için asıl kaynak, kimlik/sürüm eşleme ve güncelleme yönü tasarlanmalı. Hazır senkronizasyon varsayılmaz.'});
 if(has('neo')&&!d.ontology)findings.push({kind:'warning',text:'Neo4j seçmek ontology tanımlamaz. Türler, ilişkiler ve kaynak eşlemelerini ayrıca belirt.'});
 if(d.ontology)findings.push({kind:'info',text:'Ontology beyanı taslak düzeyinde. Model, kimlik eşlemesi ve doğrulama kanıtları olmadan tam puan verilmez.'});
 if(!gov)findings.push({kind:'info',text:'Ortak owner/onay/glossary ve teknik metadata akışı tanımlı değil.'});
 findings.push({kind:'info',text:'Bu not bileşen beyanından üretilen tahmini kapsamdır. Connector uyumu ve çalışma testleri yapılmadı; LLM bağlantısı S11 puanı kazandırmaz.'});
 return {scores,grade:grade(scores),findings};
}
export type Needs={text:string;shared:boolean;multi:boolean;keep:boolean;governance:boolean;graph:boolean;localOnly:boolean;openOnly:boolean};
export function recommend(n:Needs){
 const targets=[0,...(n.shared?[1]:[]),...(n.multi&&n.keep?[2]:[]),...(n.governance?[4,5,6,7]:[]),...(n.graph?[8,9]:[])];
 return architectures.filter(a=>(!n.localOnly||a.category==='local')&&(!n.openOnly||!a.components.some(c=>['paid','infa','bq','snow','dbx','pb'].includes(c)))).map(a=>{const coverage=targets.reduce((s,i)=>s+(a.scores[i]??0),0)/(targets.length*3);return {architecture:a,coverage:Math.round(coverage*100),rank:coverage*100-a.components.length*1.2,missing:targets.filter(i=>(a.scores[i]??0)<3).map(i=>requirements[i][1])};}).sort((a,b)=>b.rank-a.rank).slice(0,3);
}
export function validateDraft(value:unknown):Draft{
 if(!value||typeof value!=='object')throw Error('Geçerli bir mimari JSON dosyası seç.');const d=value as Draft;
 if(typeof d.name!=='string'||!d.name.trim()||d.name.length>120||!Array.isArray(d.components)||d.components.length>40||!d.components.every(x=>typeof x==='string'&&x.length<100))throw Error('Mimari adı veya bileşen listesi geçersiz.');
 const custom:Technology[]=Array.isArray(d.custom)?d.custom.filter(t=>t&&typeof t.id==='string'&&t.id.startsWith('custom-')&&t.id.length<100&&typeof t.name==='string'&&typeof t.source==='string').slice(0,20).map(t=>({id:t.id,name:t.name.slice(0,100),source:t.source.slice(0,1500),docker:null,access:'unknown',layer:'unclassified',edition:'Kullanıcı ekledi',deployment:'Araştırma gerekli',needs:'Sürüm, edition, Docker ve connector uyumu doğrulanmalı.',license:'Doğrulanmadı',reviewed:'',evidence:'Kullanıcı beyanı; doğrulanmadı.'})):[];
 const allowed=new Set([...technologies,...custom].map(t=>t.id));if(d.components.some(c=>!allowed.has(c)))throw Error('JSON içinde katalogda veya özel bileşenlerde tanımlı olmayan teknoloji var.');
 return {...d,id:typeof d.id==='string'?d.id:crypto.randomUUID(),name:d.name.trim(),pgCount:d.pgCount===2?2:1,ontology:d.ontology===true,notes:typeof d.notes==='string'?d.notes.slice(0,4000):'',created:typeof d.created==='string'?d.created:new Date().toISOString(),custom};
}

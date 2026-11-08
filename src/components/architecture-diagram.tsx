'use client';
import {Info,ZoomIn} from 'lucide-react';
import {Technology,technologies} from '../lib/domain';
type Slot={id:string;name:string;body:string;x:number;y:number;w:number;h:number;layer:string;tech?:Technology;active:boolean};
export default function ArchitectureDiagram({components,custom=[],pgCount=1,onTechnology,referenceId}:{components:string[];custom?:Technology[];pgCount?:number;onTechnology?:(t:Technology)=>void;referenceId?:number|'all'}){
 const all=[...technologies,...custom],has=(id:string)=>components.includes(id),find=(id:string)=>all.find(t=>t.id===id);
 const allVisible=referenceId==='all',customDiagram=referenceId===undefined;
 const platform=find(has('trino')?'trino':has('pg')?'pg':has('bq')?'bq':has('snow')?'snow':'dbx');
 const source=find(has('pg')?'pg':has('bq')?'bq':has('snow')?'snow':'dbx');
 const semantic=find(has('cube')?'cube':has('mf')?'mf':has('paid')?'paid':'pb');
 const gov=find(has('infa')?'infa':'om'),om=find('om'),core=find('core');
 const sql:Technology={...find('pg')!,id:'sql-role',name:'SQL seed / modelleme',edition:'PostgreSQL SQL işleri',needs:'Seed, fact/dimension ve view işleri PostgreSQL üzerinde yürütülür. Ayrı bir veri platformu değildir.'};
 const knownTech=(t:Technology|undefined)=>!!t&&components.includes(t.id);
 function slot(id:string,name:string,body:string,x:number,y:number,w:number,h:number,layer:string,tech?:Technology,active=knownTech(tech)):Slot{return {id,name,body,x,y,w,h,layer,tech,active:allVisible||active};}
 const slots:Slot[]=[
 slot('gov1','İş anlamı ve metrik kaydı','Tanım · owner · onay · sürüm',50,137,227,78,'governance',gov,has('om')||has('infa')),
 slot('gov2','Kalite ve contract','Kurallar · eşikler · ihlal',288,137,227,78,'governance',has('om')?om:gov,has('om')||has('infa')),
 slot('gov3','Observability','Freshness · hacim · schema',526,137,227,78,'governance',has('om')?om:core,has('om')),
 slot('gov4','Ürün keşfi ve erişim','Yayın · erişim talebi · politika',764,137,227,78,'governance',gov,has('om')||has('infa')),
 slot('gov5','İş ve teknik metadata bağı','Kimlik · sürüm · lineage',1002,137,227,78,'governance',has('om')?om:gov,has('om')||has('infa')),
 slot('source1','Müşteri ve dağıtım','Customer · outlet · distributor',48,286,178,80,'data',source),
 slot('source2','Sipariş, fatura ve iade','Order · invoice · return',48,378,178,80,'data',has('pg')?find('pg'):find('snow'),has('pg')&&pgCount===2||has('bq')&&has('snow')),
 slot('source3','Ürün, fiyat ve promosyon','Product · price · promotion',48,470,178,90,'data',undefined,false),
 slot('batch','Batch / CDC','Veri taşıma ve senkronizasyon',273,286,178,80,'engineering',has('core')?core:sql,has('core')||has('pg')),
 slot('stream','Streaming','Olaylar ve güncel değişimler',273,378,178,80,'access',undefined,false),
 slot('federation','Federation','İhtiyaca göre kaynağında ortak sorgu',273,470,178,90,'access',find('trino')),
 slot('raw','Ham katman','',501,288,250,43,'data',source),
 slot('curated','Curated domain modelleri','Anahtar uyumu · iş kuralları',501,341,250,70,'data',has('core')?core:source,!!source&&knownTech(source)),
 slot('execution','Warehouse / lakehouse','Tablo · view · ortak execution',501,421,250,70,'data',platform),
 slot('products','Domain veri ürünleri','Sahiplik · output portları',501,501,250,58,'governance',gov,has('om')||has('infa')),
 slot('metric','Executable metrik','Ortak hesaplama · boyut · join',797,276,192,137,'semantic',semantic,!!semantic&&knownTech(semantic)),
 slot('graph','Ontology ve graph','Türler · ilişkiler · eşlemeler\nGraph: gerçek varlık örnekleri',797,431,192,139,'context',find('neo')),
 slot('bi','BI ve raporlama','Ortak metrikleri tüketir',1022,276,220,137,'consumption',has('pb')?find('pb'):has('py')?find('py'):find('cli')),
 slot('ai','AI agent ve API','Metrik + ilişki + kaynak kanıtı',1022,431,220,139,'consumption',has('py')?find('py'):find('cli'),has('py')||has('paid')&&has('cli')),
 slot('engineering','Veri modelleme','Logical / physical model',49,619,288,56,'engineering',has('core')?core:sql,has('pg')||has('core')),
 slot('git','Git ve CI/CD','Versiyon · test · deploy',348,619,288,56,'engineering',undefined,false),
 slot('contract','Data contract kontrolleri','Schema · compatibility · kalite',647,619,288,56,'engineering',has('om')?om:core,has('om')||has('core')),
 slot('ops','İş akışı ve operasyon','Onay · incident · audit',946,619,288,56,'engineering',undefined,false)
 ];
 const image=referenceId==='all'||referenceId===undefined?'/architectures/canonical.png':'/architectures/rm-'+referenceId+'.png';
 const inactiveStyle=(s:Slot)=>({left:((s.x-30)/1220*100)+'%',top:((s.y-102)/586*100)+'%',width:(s.w/1220*100)+'%',height:(s.h/586*100)+'%'});
 function inspect(s:Slot){if(!onTechnology)return;if(!allVisible&&s.tech){onTechnology(s.tech);return;}onTechnology({id:'role-'+s.id,name:s.name,needs:s.body||'Verinin kaynak hali ve teknik yapısı.',layer:s.layer,edition:'Kanonik mimari rolü',docker:null,access:'unknown',deployment:'Teknoloji seçimine göre belirlenir',source:'',license:'Seçilen teknoloji ve edition’a bağlı',reviewed:'2026-11-08',evidence:'Sunumdaki ortak mimari çerçevesi. Bu rolün görünmesi, çalışan bir kurulum veya eksiksiz ürün yeteneği kanıtı değildir.'});}
 return <div className={"canonical-diagram "+(customDiagram?"is-custom":"")}><div className="canonical-scroll"><div className="canonical-stage"><img className="canonical-image" src={image} alt={allVisible?'Sunumdaki en zengin kanonik mimari: üstte governance, ortada kaynak, entegrasyon, veri platformu, semantic ve ilişki bağlamı, sağda tüketim; altta mühendislik ve süreç.':referenceId?'Sunumdaki Referans Mimari '+referenceId+'. Kullanılan bileşenler renkli, kapsam dışı bileşenler gri.':'Kanonik mimari üzerinde özel çözüm taslağı. Seçilmemiş alanlar gri.'}/>{slots.map(s=><button key={s.id} className={'canonical-hotspot '+(customDiagram?(s.active?'custom-active':'custom-inactive'):'')} style={inactiveStyle(s)} disabled={!s.active&&!allVisible} title={s.name+(s.active?' — ayrıntıyı aç':' — bu mimaride kullanılmaz')} aria-label={s.name+(s.active?' ayrıntısı':' kapsam dışı')} onClick={()=>inspect(s)}>{customDiagram&&<><strong>{s.active&&s.tech?s.tech.name:s.name}{s.id==='source2'&&has('pg')&&pgCount===2?' · 2. instance':''}</strong><small>{s.active&&s.tech?s.tech.needs:s.body}</small>{s.active&&s.tech?.docker&&<img className="canonical-docker" src="/assets/docker.png" alt="Docker"/>}</>}</button>)}</div></div><div className="canonical-foot"><span><Info size={13}/>{allVisible?'Tam kapsam çerçevesi. Bütün katmanlar gösterilir; tek bir çalışır kurulum değildir.':customDiagram?'Özel taslak. Roller ve bağlantılar inceleme gerektirir; bileşen seçimi çalışma kanıtı değildir.':'Sunumdaki yerleşim korunur. Aktif alanlar renkli, kapsam dışı alanlar gridir.'}</span><a href={image} target="_blank" rel="noopener noreferrer"><ZoomIn size={14}/>Çizimi büyük aç</a></div></div>;
}


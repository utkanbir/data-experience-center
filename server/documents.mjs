import {createHash} from 'node:crypto';
import {Unzip,UnzipInflate} from 'fflate';
import {XMLParser} from 'fast-xml-parser';
import {RequestError} from './assist.mjs';
const xml=new XMLParser({ignoreAttributes:false,removeNSPrefix:true,parseTagValue:false,parseAttributeValue:false,processEntities:false});
const arr=x=>x===undefined?[]:Array.isArray(x)?x:[x];
const text=x=>x===undefined?'':typeof x==='object'?Object.entries(x).filter(([k])=>!k.startsWith('@_')).map(([,v])=>arr(v).map(text).join(' ')).join(' '):String(x);
const parse=b=>{const s=new TextDecoder().decode(b);if(/<!DOCTYPE|<!ENTITY/i.test(s))throw new RequestError(400,'XML entity / DTD desteklenmiyor.');return xml.parse(s);};
function unpack(bytes){const parts=new Map();let size=0,count=0;let failure;
 const unzip=new Unzip(file=>{if(!/^(word\/document\.xml|ppt\/(slides\/slide\d+\.xml|notesSlides\/notesSlide\d+\.xml)|xl\/(workbook\.xml|_rels\/workbook\.xml\.rels|sharedStrings\.xml|worksheets\/sheet\d+\.xml))$/.test(file.name))return;
 if(++count>300||file.originalSize>3_000_000)throw new RequestError(413,'Dokümanın XML parçaları sınırı aşıyor.');let total=0;const chunks=[];file.ondata=(err,data,final)=>{if(err){failure=err;return;}total+=data.length;size+=data.length;if(total>3_000_000||size>24_000_000)throw new RequestError(413,'Açılmış doküman boyutu sınırı aşıyor.');chunks.push(data);if(final)parts.set(file.name,Buffer.concat(chunks));};file.start();});
 unzip.register(UnzipInflate);try{for(let i=0;i<bytes.length;i+=4096)unzip.push(bytes.subarray(i,i+4096),i+4096>=bytes.length);}catch(e){if(e instanceof RequestError)throw e;throw new RequestError(400,'Office dosyası okunamadı; şifreli veya bozuk olabilir.');}if(failure)throw new RequestError(400,'Office arşivi okunamadı.');return parts;
}
export function extractDocument(name,bytes){
 if(bytes.length>12_000_000)throw new RequestError(413,'Dosya en fazla 12 MB olabilir.');
 const ext=name.split('.').pop().toLowerCase();if(!['txt','md','csv','tsv','docx','pptx','xlsx'].includes(ext))throw new RequestError(415,'TXT, MD, CSV, DOCX, PPTX veya XLSX kullan. Eski Office dosyalarını yeni biçime dönüştür.');
 const units=[],warnings=[];let chars=0,truncated=false;
 const add=(label,value)=>{const s=value.replace(/\s+/g,' ').trim();if(!s)return;if(units.length>=600||chars+s.length>100_000){truncated=true;return;}chars+=s.length;units.push({id:'u'+(units.length+1),label,text:s.slice(0,6000)});if(s.length>6000)truncated=true;};
 if(['txt','md','csv','tsv'].includes(ext)){
  let s;try{s=bytes[0]===255&&bytes[1]===254?new TextDecoder('utf-16le').decode(bytes):new TextDecoder('utf-8',{fatal:true}).decode(bytes);}catch{s=new TextDecoder('windows-1254').decode(bytes);warnings.push('UTF-8 yerine Windows-1254 kodlaması kullanıldı.');}if(s.includes('\0'))throw new RequestError(400,'Metin dosyası ikili veri içeriyor.');s.split(/\r?\n/).forEach((line,i)=>add('Satır '+(i+1),line));
 }else{
  const parts=unpack(bytes);const get=n=>parts.has(n)?parse(parts.get(n)):null;
  if(ext==='docx'){const doc=get('word/document.xml');if(!doc)throw new RequestError(400,'Word ana metni bulunamadı.');const walk=o=>{if(!o||typeof o!=='object')return;for(const [k,v]of Object.entries(o)){if(k==='p')arr(v).forEach(p=>add('Paragraf '+(units.length+1),text(p)));else if(!k.startsWith('@_'))arr(v).forEach(walk);}};walk(doc);}
  if(ext==='pptx'){const slides=[...parts.keys()].filter(n=>/^ppt\/slides\/slide\d+\.xml$/.test(n)).sort((a,b)=>Number(a.match(/slide(\d+)/)[1])-Number(b.match(/slide(\d+)/)[1]));for(const n of slides){const id=n.match(/slide(\d+)/)[1];add('Slayt dosyası '+id,text(get(n)));}warnings.push('Slayt dosya sırası kullanılır; özel gösteri sırası, görseller ve çizimler yorumlanmaz.');}
  if(ext==='xlsx'){const wb=get('xl/workbook.xml'),rel=get('xl/_rels/workbook.xml.rels');if(!wb)throw new RequestError(400,'Excel çalışma kitabı bulunamadı.');const shared=arr(get('xl/sharedStrings.xml')?.sst?.si).map(text);const rels=arr(rel?.Relationships?.Relationship);for(const sheet of arr(wb.workbook?.sheets?.sheet)){const target=rels.find(r=>r['@_Id']===sheet['@_id'])?.['@_Target'];const path=target?.startsWith('/')?target.slice(1):'xl/'+target;if(!/^xl\/worksheets\/sheet\d+\.xml$/.test(path))continue;const data=get(path);for(const row of arr(data?.worksheet?.sheetData?.row)){add(sheet['@_name']+'!Satır '+row['@_r'],arr(row.c).map(c=>{let value=c['@_t']==='s'?shared[Number(c.v)]||'':c['@_t']==='inlineStr'?text(c.is):text(c.v);if(c.f)value+=' [formülün kayıtlı sonucu]';return c['@_r']+': '+value;}).join(' | '));}}warnings.push('Formüller çalıştırılmaz; kayıtlı sonuçlar okunur. Tarihler Excel seri sayısı olabilir. Gizli sayfa/satırlar da okunur.');}
  warnings.push('Yalnız seçilebilir metin okunur; resim, gömülü nesne ve OCR kapsam dışıdır.');
 }
 if(!units.length)throw new RequestError(400,'Okunabilir metin bulunamadı.');if(truncated)warnings.push('Metin sınırı nedeniyle içerik kısaltıldı; eksik bölümleri ayrı dosya olarak ekle.');
 const hash=createHash('sha256').update(bytes).digest('hex');return {id:hash.slice(0,20),name:name.replace(/[\\/]/g,'_').slice(0,160),hash,units,warnings,truncated};
}

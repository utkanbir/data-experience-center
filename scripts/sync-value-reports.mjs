import fs from 'node:fs/promises';
import {build} from 'esbuild';
const bundle=await build({entryPoints:['src/lib/value-proposition.ts'],bundle:true,write:false,format:'iife',globalName:'KomtasValue',minify:true});
const library=bundle.outputFiles[0].text;
const catalog=JSON.parse(await fs.readFile('src/lib/catalog.json','utf8'));
function patch(html,id){
 html=html.replace(/<!-- KOMTAS_VALUE_SECTION -->[\s\S]*?<!-- END_KOMTAS_VALUE_SECTION -->/g,'').replace(/<!-- KOMTAS_VALUE_SCRIPT -->[\s\S]*?<!-- END_KOMTAS_VALUE_SCRIPT -->/g,'');
 const architecture=catalog.architectures.find(a=>a.id===id);
 const section='<!-- KOMTAS_VALUE_SECTION --><section id="komtas-values"><h2>Komtaş değer önerisiyle eşleme</h2><p>Data360 → Business360 → Agent360. Data & AI Strategy yönü belirler; Data & AI Governance tüm katmanlarda güven ve hesap verebilirliği kapsar.</p><p>Bu mimaride strateji eşlemesi ortak iş sorusu ve başarı ölçütü üzerinden yapılır. Yerel rol/SQL kontrolleri merkezi governance hizmetinin tamamını doğrulamaz.</p><div id="komtas-value-cards" class="layers"></div><small>Kaynak: Komtaş AI Innovation Day, 11.11.2026 · slayt 6–9. Laboratuvar eşlemesi; 360 kapsam yüzdesi üretilmez.</small></section><!-- END_KOMTAS_VALUE_SECTION -->';
 html=html.replace('<section><h2>Kontrol kanıtları</h2>',section+'<section><h2>Kontrol kanıtları</h2>');
 const source=JSON.stringify({components:architecture.components,graph:!!architecture.graph});
 const script='<!-- KOMTAS_VALUE_SCRIPT --><script>'+library+'\n(()=>{const target=document.getElementById("komtas-value-cards");function add(tag,text,parent){const n=document.createElement(tag);n.textContent=text;parent.append(n);return n;}for(const v of KomtasValue.getValueMapping('+source+',r)){const card=add("article","",target);card.style.borderTop="4px solid "+v.color;add("small",v.status,card);add("h3",v.name,card);add("small",v.subtitle,card);for(const [title,text]of [["Ne kazandırıyor?",v.contribution],["Deney kanıtı",v.evidence],["Sonraki adım",v.next]]){add("h4",title,card);add("p",text,card);}}})();</script><!-- END_KOMTAS_VALUE_SCRIPT -->';
 return html.replace('</html>',script+'</html>');
}
const rm1=JSON.parse(await fs.readFile('src/lib/rm1-template.json','utf8'));
rm1['report-template.html']=patch(rm1['report-template.html'],1);
await fs.writeFile('src/lib/rm1-template.json',JSON.stringify(rm1,null,2)+'\n');
const rm2Path='packages/rm2/report-template.html';
await fs.writeFile(rm2Path,patch(await fs.readFile(rm2Path,'utf8'),2));

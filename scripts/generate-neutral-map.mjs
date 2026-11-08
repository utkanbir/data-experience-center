import fs from 'node:fs/promises';
const roles=JSON.parse(await fs.readFile('src/lib/canonical-roles.json','utf8'));
const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
function lines(text,width){const result=[];let line='';for(const word of text.split(' ')){if((line+' '+word).length>width&&line){result.push(line);line=word;}else line+=(line?' ':'')+word;}if(line)result.push(line);return result;}
const text=(x,y,value,size=12,color='#334c47',weight=400)=>`<text x="${x}" y="${y}" font-size="${size}" fill="${color}" font-weight="${weight}">${escape(value)}</text>`;
const groups=[
 [40,125,1204,105,'#fff5eb','#eeb48e','GOVERNANCE VE METADATA',114],
 [40,274,202,314,'#edf4fb','#8eafd2','KAYNAK DOMAİNLERİ',260],
 [264,274,197,314,'#edf4fb','#8eafd2','ENTEGRASYON VE ERİŞİM',260],
 [486,274,282,314,'#eaf4ed','#91b8a1','VERİ PLATFORMU',260],
 [782,267,219,321,'#f2eef8','#b9a6d0','METRİK VE İLİŞKİ BAĞLAMI',253],
 [1010,267,240,321,'#f5f7f5','#c2d0c7','TÜKETİM',253],
 [40,610,1204,72,'#faf4e5','#cbbb88','MÜHENDİSLİK VE SÜREÇ',601]
];
let svg='<svg xmlns="http://www.w3.org/2000/svg" viewBox="30 102 1220 586" role="img" aria-label="Vendor agnostic kurumsal veri mimarisi"><defs><marker id="flow" markerWidth="7" markerHeight="7" refX="6" refY="3.5" orient="auto"><path d="M0 0L7 3.5L0 7Z" fill="#5b756d"/></marker></defs><rect x="30" y="102" width="1220" height="586" fill="#ffffff"/><g font-family="Segoe UI,Arial,sans-serif">';
for(const [x,y,w,h,fill,stroke,label,titleY]of groups)svg+=`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="9" fill="${fill}" stroke="${stroke}" stroke-width="1.4"/>`+text(x+4,titleY,label,10,'#6c8179',650);
for(const [x1,y1,x2,y2]of [[242,326,264,326],[461,326,486,326],[768,345,782,345],[1001,345,1010,345],[768,511,782,511],[1001,511,1010,511]])svg+=`<path d="M${x1} ${y1}L${x2} ${y2}" stroke="#5b756d" stroke-width="2" marker-end="url(#flow)"/>`;
for(const r of roles){
 svg+=`<rect x="${r.x}" y="${r.y}" width="${r.w}" height="${r.h}" rx="7" fill="#ffffff" stroke="#c9d7d1" stroke-width="1.1"/>`;
 const title=lines(r.name,Math.floor(r.w/7.7)),small=r.h<50;
 title.slice(0,small?1:2).forEach((line,i)=>svg+=text(r.x+11,r.y+(small?26:23)+i*17,line,small?13:13,'#2a4740',600));
 if(!small){const body=lines(r.body,Math.floor(r.w/5.9)),start=r.y+23+title.length*17+4;body.slice(0,Math.max(0,Math.floor((r.y+r.h-10-start)/14)+1)).forEach((line,i)=>svg+=text(r.x+11,start+i*14,line,10,'#7d8c85'));}
}
svg+='</g></svg>';
await fs.mkdir('public/architectures',{recursive:true});
await fs.writeFile('public/architectures/canonical-neutral.svg',svg);

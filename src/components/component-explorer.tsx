import {useId,useRef,useState} from 'react';
import {BookOpen,Compass,Info,X} from 'lucide-react';
import {Architecture,architectures} from '../lib/domain';
import {componentWalkthroughs} from '../lib/component-walkthrough';
import {productLogos} from '../lib/product-logos';

export function WalkthroughSteps({architecture,componentId,port}:{architecture:Architecture;componentId:string;port?:number}){
 const guide=componentWalkthroughs(architecture,port).find(g=>g.id===componentId);
 if(!guide)return <p>Bu bileşenin çalıştırılabilir keşif rehberi henüz hazır değil.</p>;
 return <section className="explore-steps" aria-label={guide.name+' adım adım keşif rehberi'}><div className="explore-entry"><Compass size={18}/><div><strong>Başlangıç noktası</strong><p>{guide.entry}</p></div></div><p className="explore-reference-note">Önce senaryoyu çalıştır. Buradaki değerler beklenen referans sonuçlarıdır; kendi çalışmanın durumunu rapordan kontrol et.</p>{guide.steps.map((step,i)=><details key={guide.id+'-'+i} className="explore-step" open={i===0}><summary><span className="explore-number">{String(i+1).padStart(2,'0')}</span><span>{step.title}</span></summary><div className="explore-step-content"><ol>{step.actions.map(action=><li key={action}>{action}</li>)}</ol>{step.code&&<div className="explore-code"><span>İnceleme komutu / sorgusu</span><pre><code>{step.code}</code></pre></div>}<div className="explore-expected"><strong>Ne görmeyi bekliyorum?</strong><p>{step.expected}</p></div><div className="explore-meaning"><strong>Bu neyi gösteriyor?</strong><p>{step.meaning}</p></div><div className="explore-missing"><Info size={16}/><div><strong>Göremiyorsam?</strong><p>{step.missing}</p></div></div></div></details>)}</section>;
}

function Explorer({architecture,port}:{architecture:Architecture;port?:number}){
 const guides=componentWalkthroughs(architecture,port);
 const [selected,setSelected]=useState(architecture.id===9?'trino':architecture.id===10?'neo':guides[0]?.id??'');
 return <><p className="explore-dialog-intro">Bir bileşen seç. Ekranda izleyeceğin yolu, kontrol edeceğin kaydı ve beklenen sonucu adım adım aç.</p><div className="component-pickers explore-pickers" role="group" aria-label="Keşfedilecek bileşen">{guides.map(g=><button type="button" key={g.id} aria-pressed={selected===g.id} onClick={()=>setSelected(g.id)}>{productLogos[g.id]&&<img src={'/assets/logos/'+productLogos[g.id].file+'.svg'} alt=""/>}{g.name}</button>)}</div><WalkthroughSteps key={selected} architecture={architecture} componentId={selected} port={port}/></>;
}

export default function ExploreLauncher({architecture,port}:{architecture:number;port?:number}){
 const a=architectures.find(a=>a.id===architecture),dialog=useRef<HTMLDialogElement>(null),title=useId();
 if(!a?.ready)return null;
 return <section className="explore-launcher"><BookOpen size={23}/><div><span className="eyebrow">SENARYODAN SONRA</span><h4>Bileşenleri adım adım keşfet</h4><p>{architecture===9?'Trino’da çalışan sorgu yok mu? Dashboard → Query details → State → FINISHED. Diğer bileşenlerde de nereye bakacağını rehberden takip et.':'Her bileşende nereye gideceğini, neyi kontrol edeceğini ve hangi sonucu bekleyeceğini gör.'}</p><button type="button" className="button primary" onClick={()=>dialog.current?.showModal()}><Compass size={16}/>Keşif rehberini aç</button><small>Aynı rehber referans mimarinin “Bileşenlerin görevi” ekranında ve ZIP içindeki KESIF_REHBERI.md dosyasında bulunur.</small></div><dialog ref={dialog} className="explore-dialog" aria-labelledby={title}><header><div><span className="eyebrow">RM {architecture} · KEŞİF REHBERİ</span><h2 id={title}>Bileşenleri adım adım keşfet</h2></div><button type="button" className="icon-button" aria-label="Keşif rehberini kapat" onClick={()=>dialog.current?.close()}><X size={20}/></button></header><div className="explore-dialog-body"><Explorer architecture={a} port={port}/></div></dialog></section>;
}

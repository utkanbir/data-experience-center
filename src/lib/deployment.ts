import {docsPortFor} from './ports';
import rm1 from './rm1-template.json';
import rm2 from './rm2-template.json';
import rm3 from './rm3-template.json';
import rm4 from './rm4-template.json';
import rm5 from './rm5-template.json';
import rm6 from './rm6-template.json';
import rm7 from './rm7-template.json';
import {managedSettings,ManagedSettings} from './managed';
export function buildPackageFiles(id:number,namespace:string,port:number,managed?:ManagedSettings):Record<string,string>{
 if(!/^komtas-[a-z0-9](?:[a-z0-9-]{0,38}[a-z0-9])?$/.test(namespace)||!Number.isInteger(port)||port<1024||port>65535)throw Error('Geçersiz paket ayarı.');
 const template=id===1?rm1:id===2?rm2:id===3?rm3:id===4?rm4:id===5?rm5:id===6?rm6:id===7?rm7:null;if(!template)throw Error('Bu mimarinin paketi henüz hazır değil.');
 const files:Record<string,string>={};
 for(const [path,text]of Object.entries(template))files['rm'+id+'-kubernetes/'+path]=text.replaceAll('komtas-rm'+id,namespace).replaceAll(String(15431+id),String(port)).replaceAll(String(18080+id),String(docsPortFor(port)));
 if(id===6)files['rm6-kubernetes/managed/settings.json']=JSON.stringify(managedSettings(managed),null,2);
 return files;
}

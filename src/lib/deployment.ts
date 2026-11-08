import {docsPortFor} from './ports';
import rm1 from './rm1-template.json';
import rm2 from './rm2-template.json';
export function buildPackageFiles(id:number,namespace:string,port:number):Record<string,string>{
 if(!/^komtas-[a-z0-9](?:[a-z0-9-]{0,38}[a-z0-9])?$/.test(namespace)||!Number.isInteger(port)||port<1024||port>65535)throw Error('Geçersiz paket ayarı.');
 const template=id===1?rm1:id===2?rm2:null;if(!template)throw Error('Bu mimarinin paketi henüz hazır değil.');
 const files:Record<string,string>={};
 for(const [path,text]of Object.entries(template))files['rm'+id+'-kubernetes/'+path]=text.replaceAll('komtas-rm'+id,namespace).replaceAll(String(15431+id),String(port)).replaceAll('18082',String(docsPortFor(port)));
 return files;
}

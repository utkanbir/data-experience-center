import {walkthroughMarkdown} from './component-walkthrough';
import {referencePortFor,docsPortFor} from './ports';
import {architectures} from './domain';
import {componentStoryMarkdown} from './component-story';
import rm1 from './rm1-template.json';
import rm2 from './rm2-template.json';
import rm3 from './rm3-template.json';
import rm4 from './rm4-template.json';
import rm5 from './rm5-template.json';
import rm6 from './rm6-template.json';
import rm7 from './rm7-template.json';
import rm8 from './rm8-template.json';
import rm9 from './rm9-template.json';
import rm10 from './rm10-template.json';
import {managedSettings,ManagedSettings} from './managed';
import {applyExternalFiles,ExternalSetup} from './external-connections';
export function buildPackageFiles(id:number,namespace:string,port:number,managed?:ManagedSettings,external?:ExternalSetup):Record<string,string>{
 if(!/^komtas-[a-z0-9](?:[a-z0-9-]{0,38}[a-z0-9])?$/.test(namespace)||!Number.isInteger(port)||port<1024||port>65535)throw Error('Geçersiz paket ayarı.');
 const template=id===1?rm1:id===2?rm2:id===3?rm3:id===4?rm4:id===5?rm5:id===6?rm6:id===7?rm7:id===8?rm8:id===9?rm9:id===10?rm10:null;if(!template)throw Error('Bu mimarinin paketi henüz hazır değil.');
 const files:Record<string,string>={};
 for(const [path,text]of Object.entries(template)){
  const source=id===9?text.replaceAll('16440','__REFERENCE_PORT__').replaceAll('15440','__DATABASE_PORT__').replaceAll('18089','__DOCS_PORT__'):text;
  files['rm'+id+'-kubernetes/'+path]=id===9?source.replaceAll('komtas-rm9',namespace).replaceAll('__REFERENCE_PORT__',String(referencePortFor(port))).replaceAll('__DATABASE_PORT__',String(port)).replaceAll('__DOCS_PORT__',String(docsPortFor(port))):source.replaceAll('komtas-rm'+id,namespace).replaceAll(String(15431+id),String(port)).replaceAll(String(18080+id),String(docsPortFor(port)));
 }
 if(id===6)files['rm6-kubernetes/managed/settings.json']=JSON.stringify(managedSettings(managed),null,2);
 const architecture=architectures.find(a=>a.id===id);if(architecture)files['rm'+id+'-kubernetes/BILESENLER.md']=componentStoryMarkdown(architecture);
 if(architecture)files['rm'+id+'-kubernetes/KESIF_REHBERI.md']=walkthroughMarkdown(architecture,port);
 if(external)applyExternalFiles(files,architectures.find(a=>a.id===id)!,external);
 return files;
}

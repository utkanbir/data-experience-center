import fs from 'node:fs/promises';
import path from 'node:path';
const root=path.resolve('packages/rm2'),files={};
async function collect(dir){
 for(const entry of await fs.readdir(dir,{withFileTypes:true})){
  if(entry.name==='reports')continue;
  const full=path.join(dir,entry.name);
  if(entry.isDirectory())await collect(full);
  else if(entry.isFile()&&['.ps1','.sh','.md','.html','.sql','.json','.yml','.yaml','.py','.csv'].includes(path.extname(entry.name)))files[path.relative(root,full).split(path.sep).join('/')]=await fs.readFile(full,'utf8');
 }
}
await collect(root);
await fs.writeFile('src/lib/rm2-template.json',JSON.stringify(files,null,2)+'\n');
await fs.writeFile('src/lib/experience-profile-rm2.json',files['report-profile.json']);

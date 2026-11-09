import fs from 'node:fs/promises';
import path from 'node:path';
let root,files;
async function collect(dir){
 for(const entry of await fs.readdir(dir,{withFileTypes:true})){
  if(entry.name==='reports'||entry.name==='.connections')continue;
  const full=path.join(dir,entry.name);
  if(entry.isDirectory())await collect(full);
  else if(entry.isFile()&&['.ps1','.sh','.md','.html','.sql','.json','.yml','.yaml','.py','.csv','.js','.txt','.tsv','.properties','.config'].includes(path.extname(entry.name)))files[path.relative(root,full).split(path.sep).join('/')]=await fs.readFile(full,'utf8');
 }
}
for(const id of [2,3,4,5,6,7,8,9]){
 root=path.resolve('packages/rm'+id);files={};await collect(root);
 await fs.writeFile('src/lib/rm'+id+'-template.json',JSON.stringify(files,null,2)+'\n');
 await fs.writeFile('src/lib/experience-profile-rm'+id+'.json',files['report-profile.json']);
}

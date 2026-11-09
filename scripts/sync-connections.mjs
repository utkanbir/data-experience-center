import fs from 'node:fs/promises';
const shared=Object.fromEntries(await Promise.all(['Connect.ps1','Get-Connections.ps1','connect.sh','get-connections.sh'].map(async name=>[name,await fs.readFile('packages/shared/'+name,'utf8')])));
const first=JSON.parse(await fs.readFile('src/lib/rm1-template.json','utf8'));
for(let id=1;id<=10;id++){
 const prefix='packages/rm'+id+'/',pg=15431+id;
 const services=[{id:'postgres',name:'PostgreSQL'+(id===9?' - satis kaynagi':''),service:'postgres',localPort:pg,remotePort:5432,kind:'tcp',path:'',database:'komtas_rm'+id,username:'rm'+id+'_bi'}];
 const http=(key,name,service,port,remote,path='/')=>services.push({id:key,name,service,localPort:port,remotePort:remote,kind:'http',path,database:'',username:''});
 if(id===9)services.push({id:'reference',name:'PostgreSQL - referans kaynagi',service:'postgres-reference',localPort:16440,remotePort:5432,kind:'tcp',path:'',database:'komtas_rm9_reference',username:'rm9_bi'});
 if(id>=2)http('docs','dbt dokumani','dbt-docs',18080+id,8080,'/static_index.html');
 const cube=[4,5,7,8,9,10].includes(id),om=[5,8,9,10].includes(id);
 if(cube){http('cube','Cube REST API','cube',4000+id,4000,'/cubejs-api/v1/meta');http('dashboard','Streamlit','dashboard',8500+id,8501);}
 if(om)http('catalog','OpenMetadata','openmetadata',id===10?18590:id===9?18589:id===8?18588:8585,8585);
 if(id===10){http('neo4j-browser','Neo4j Browser','neo4j',17484,7474,'/browser/');services.push({id:'neo4j-bolt',name:'Neo4j Bolt',service:'neo4j',localPort:17697,remotePort:7687,kind:'tcp',path:'',database:'neo4j',username:'neo4j'});}
 if(id===9)http('trino','Trino SQL','trino',18099,8080);
 const credentials=[{name:'PostgreSQL parola'+(id===9?' (iki is kaynagi)':''),secret:'rm'+id+'-credentials',key:'bi-password'}];
 if(om)credentials.push({name:'OpenMetadata admin@open-metadata.org parola',secret:'rm'+id+'-governance',key:'admin-password'});
 if(id===10)credentials.push({name:'Neo4j neo4j parola',secret:'rm10-graph',key:'password'});
 const external=id===6?[{name:'Yonetilen dbt Semantic',settings:'managed/settings.json',command:'Set-DbtConnection.ps1 / bash set-dbt-connection.sh; token yalniz yerelde girilir.'}]:[7,8].includes(id)?[{name:'Informatica CDGC',settings:id===8?'cdgc/settings.json':'governance/settings.json',command:'Set-InformaticaConnection.ps1 / bash set-informatica-connection.sh; JWT yalniz yerelde girilir.'}]:[];
 const notes=['Connect tum yerel tunelleri acar; dolu portta 30 sonraki port denenir. Gercek adresleri bu ozet gosterir.','Ctrl+C yalniz bu Connect oturumunun actigi tunelleri kapatir; Kubernetes servislerini silmez.'];
 if(id<=2||id===6)notes.push('Power BI Desktop haricten saglanir. PostgreSQL baglantisi yukaridadir; RM6 yonetilen semantic connector erisimi ayrica saglanir.');
 if(id===3)notes.push('MetricFlow CLI: Show-Metrics.ps1 / bash show-metrics.sh; ayri web servisi yoktur.');
 if(cube)notes.push('Cube API JWT ister. Cube Store kume ici destek servisidir, kullanici UI yoktur.');
 if(om)notes.push('OpenMetadata admin: admin@open-metadata.org. Metadata PostgreSQL ve Elasticsearch kume ici destek servisleridir, kullanici UI yoktur.');
 if(id===10)notes.push('Neo4j Browser icinde Bolt URI alanina ozetin Neo4j Bolt adresini girin. Kullanici neo4j; parola toplu ozette. Graph sync acik komutla yapilir; LLM/agent yoktur.');
 for(const e of external)notes.push(e.name+' harici servistir; Connect bu servisi kurmaz veya localhost tuneli acmaz. '+e.command);
 const plan={namespace:'komtas-rm'+id,context:'docker-desktop',services,credentials,external,cubeToken:cube,notes};
 const files={};
 for(const [name,text]of Object.entries(shared))files[name]=text.replaceAll('__N__',String(id)).replaceAll('__PGPORT__',String(pg));
 files['connections.json']=JSON.stringify(plan,null,2)+'\n';
 files['connections.tsv']=services.map(s=>[s.id,s.name,s.service,s.localPort,s.remotePort,s.kind,s.path,s.database,s.username].join('|')).join('\n')+'\n';
 files['connection-credentials.tsv']=credentials.map(c=>[c.name,c.secret,c.key].join('|')).join('\n')+'\n';
 files['connection-notes.txt']=notes.join('\n')+'\n';
 files['BAGLANTILAR.md']='# Tek komutla tüm bağlantılar\n\nDeploy tamamlandıktan sonra paket klasöründe bir terminal açın:\n\nWindows: `.\\Connect.ps1`\n\nLinux: `bash connect.sh` (Bash, kubectl, util-linux/flock gerekir).\n\nBu tek terminal bütün yerel servis tünellerini açar; açık kalsın. Port doluysa sonraki boş port seçilir. İkinci terminalde Windows `.\\Get-Connections.ps1`, Linux `bash get-connections.sh` çalıştırın. Adresler, veritabanı/kullanıcı ve yerel parola/Cube JWT tek özette gösterilir. Parolalar dosyaya yazılmaz. Gizli bilgi göstermeden özet: `Get-Connections.ps1 -NoSecrets` / `bash get-connections.sh --no-secrets`.\n\nCtrl+C bütün bu oturum tünellerini kapatır; servisler ve veri kalır. Windows’ta kaybolmuş oturumu kapatma: `Connect.ps1 -Disconnect`; yalnız PID ve başlangıç zamanı eşleşen kubectl çocuklarını durdurur. Connect aynı pakette eşzamanlı ikinci oturumu reddeder. Açılışta bir servis başarısızsa başlatılan tüneller de kapatılır; Deploy/pod durumunu düzeltip tekrar deneyin.\n\nHarici dbt/Informatica erişimi localhost tüneli değildir; özette host/org/environment ve ilgili yerel kimlik bilgisi komutu gösterilir. Harici tokenlar ekrana dökülmez. Eski tek servis Connect-* ve Get-Connection yardımcıları uyumluluk için pakette bulunur; günlük kullanımda bu iki komut yeterlidir. Gerçek tünel portları `.connections/` altında saklanır; bu dosyalarda parola/token yoktur.\n';
 files['Show-Access.ps1']="[CmdletBinding()]\nparam()\nWrite-Host 'Tum yerel baglantilari ac: .\\Connect.ps1'\nWrite-Host 'Tum adresler ve giris bilgileri: .\\Get-Connections.ps1'\nWrite-Host 'Tek Connect terminali acik kalsin; Ctrl+C tum oturum tunellerini kapatir.'\n& (Join-Path $PSScriptRoot 'Get-Connections.ps1') -NoSecrets\n";
 files['show-access.sh']="#!/usr/bin/env bash\nset -euo pipefail\necho 'Tum yerel baglantilari ac: bash connect.sh'\necho 'Tum adresler ve giris bilgileri: bash get-connections.sh'\nbash \"$(dirname -- \"${BASH_SOURCE[0]}\")/get-connections.sh\" --no-secrets\n";
 if(id===1){
  first['Connect-Postgres.ps1']??=first['Connect.ps1'];first['connect-postgres.sh']??=first['connect.sh'];Object.assign(first,files);
 }else{
  for(const [old,copy]of [['Connect.ps1','Connect-Postgres.ps1'],['connect.sh','connect-postgres.sh']]){try{await fs.access(prefix+copy);}catch{await fs.copyFile(prefix+old,prefix+copy);}}
  for(const [name,text]of Object.entries(files))await fs.writeFile(prefix+name,text);
 }
}
await fs.writeFile('src/lib/rm1-template.json',JSON.stringify(first,null,2)+'\n');

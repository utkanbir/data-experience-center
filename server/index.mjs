import http from 'node:http';
import {createReadStream,existsSync,statSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {extractDocument} from './documents.mjs';
import {analyzeScenario} from './scenario-analysis.mjs';
import {assist,RequestError} from './assist.mjs';
const defaultRoot=fileURLToPath(new URL('../dist/',import.meta.url));
const mime={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json; charset=utf-8','.png':'image/png','.svg':'image/svg+xml','.jpg':'image/jpeg','.zip':'application/zip','.pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation'};
const rates=new Map();
export function createApp({fetcher=fetch,allowedOrigins=process.env.ALLOWED_ORIGINS||'',staticRoot=defaultRoot}={}){
 const root=path.resolve(staticRoot);
 const allowed=new Set(allowedOrigins.split(',').map(x=>x.trim()).filter(Boolean));
 return http.createServer(async(req,res)=>{
  res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Referrer-Policy','strict-origin-when-cross-origin');
  const json=(status,data)=>{res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});res.end(JSON.stringify(data));};
  let url;try{url=new URL(req.url,'http://localhost');}catch{return json(400,{error:'Geçersiz adres.'});}
  if(url.pathname==='/api/health')return json(200,{status:'ok',authentication:'none'});
  if(['/api/assist','/api/documents/extract','/api/scenarios/analyze'].includes(url.pathname)){
   const isDocument=url.pathname==='/api/documents/extract',isScenario=url.pathname==='/api/scenarios/analyze';
   if(req.method==='GET'&&!isDocument&&!isScenario)return json(200,{connected:false,mode:'byok',providers:['openai','groq','openrouter']});
   if(req.method!=='POST')return json(405,{error:'POST kullan.'});
   const origin=req.headers.origin,host=req.headers.host;
   if(origin&&!allowed.has(origin)&&origin!=='http://'+host&&origin!=='https://'+host)return json(403,{error:'İstek kaynağına izin verilmiyor.'});
   if(req.headers['sec-fetch-site']==='cross-site')return json(403,{error:'Çapraz site isteği reddedildi.'});
   if(!req.headers['content-type']?.startsWith(isDocument?'application/octet-stream':'application/json'))return json(415,{error:'JSON gerekli.'});
   const ip=req.socket.remoteAddress||'local',now=Date.now();
   if(rates.size>10000)for(const [key,rate]of rates)if(now-rate.start>60000)rates.delete(key);
   const rate=rates.get(ip);if(rate&&now-rate.start<60000){if(rate.count>=20)return json(429,{error:'Bir dakika içinde çok fazla istek.'});rate.count++;}else rates.set(ip,{start:now,count:1});
   let length=0;const chunks=[];
   try{for await(const chunk of req){length+=chunk.length;if(length>(isDocument?12_000_000:isScenario?180_000:24000)){json(413,{error:'İstek çok büyük.'});return;}chunks.push(chunk);}if(isDocument){let name;try{name=decodeURIComponent(req.headers['x-file-name']||'');}catch{return json(400,{error:'Dosya adı geçersiz.'});}return json(200,extractDocument(name,Buffer.concat(chunks)));}let body;try{body=JSON.parse(Buffer.concat(chunks).toString('utf8'));}catch{return json(400,{error:'Geçersiz JSON.'});}return json(200,isScenario?await analyzeScenario(body,fetcher):await assist(body,fetcher));}catch(error){if(!res.headersSent)json(error instanceof RequestError?error.status:500,{error:error instanceof RequestError?error.message:'İstek tamamlanamadı.'});}return;
  }
  if(req.method!=='GET'&&req.method!=='HEAD')return json(405,{error:'Yöntem desteklenmiyor.'});
  let decoded;try{decoded=decodeURIComponent(url.pathname);}catch{return json(400,{error:'Geçersiz adres.'});}
  const file=path.resolve(root,'.'+decoded);if(file!==root&&!file.startsWith(root+path.sep))return json(403,{error:'Erişim reddedildi.'});
  const target=existsSync(file)&&statSync(file).isFile()?file:path.join(root,'index.html');if(!existsSync(target))return json(404,{error:'Önce npm run build çalıştır.'});
  res.setHeader('Content-Type',mime[path.extname(target)]||'application/octet-stream');res.setHeader('Cache-Control',target.endsWith('index.html')?'no-cache':'public, max-age=3600');if(req.method==='HEAD')return res.end();const stream=createReadStream(target);stream.on('error',()=>res.destroy());stream.pipe(res);
 });
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const port=Number(process.env.PORT||3001),host=process.env.HOST||'127.0.0.1',server=createApp();server.headersTimeout=15000;server.requestTimeout=45000;server.listen(port,host,()=>console.log('Data Experience Center: http://'+host+':'+port));
}

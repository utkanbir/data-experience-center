export function zipFiles(files:Record<string,string>):Uint8Array{
 const encoder=new TextEncoder(),parts:Uint8Array[]=[],central:Uint8Array[]=[];let offset=0;
 const crc=(bytes:Uint8Array)=>{let c=0xffffffff;for(const b of bytes){c^=b;for(let k=0;k<8;k++)c=(c>>>1)^((c&1)?0xedb88320:0);}return(c^0xffffffff)>>>0;};
 for(const [path,text]of Object.entries(files)){
  const name=encoder.encode(path),body=encoder.encode(text),sum=crc(body),local=new Uint8Array(30+name.length),v=new DataView(local.buffer);
  v.setUint32(0,0x04034b50,true);v.setUint16(4,20,true);v.setUint16(6,0x800,true);v.setUint16(12,33,true);v.setUint32(14,sum,true);v.setUint32(18,body.length,true);v.setUint32(22,body.length,true);v.setUint16(26,name.length,true);local.set(name,30);
  const dir=new Uint8Array(46+name.length),c=new DataView(dir.buffer);c.setUint32(0,0x02014b50,true);c.setUint16(4,20,true);c.setUint16(6,20,true);c.setUint16(8,0x800,true);c.setUint16(14,33,true);c.setUint32(16,sum,true);c.setUint32(20,body.length,true);c.setUint32(24,body.length,true);c.setUint16(28,name.length,true);c.setUint32(42,offset,true);dir.set(name,46);parts.push(local,body);central.push(dir);offset+=local.length+body.length;
 }
 const start=offset;for(const d of central){parts.push(d);offset+=d.length;}const end=new Uint8Array(22),e=new DataView(end.buffer);e.setUint32(0,0x06054b50,true);e.setUint16(8,central.length,true);e.setUint16(10,central.length,true);e.setUint32(12,offset-start,true);e.setUint32(16,start,true);parts.push(end);
 const result=new Uint8Array(offset+22);let cursor=0;for(const p of parts){result.set(p,cursor);cursor+=p.length;}return result;
}
export function download(name:string,value:string|Uint8Array,type='application/json'){
 const bytes=typeof value==='string'?value:new Uint8Array(value).buffer;const url=URL.createObjectURL(new Blob([bytes],{type}));const a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
}

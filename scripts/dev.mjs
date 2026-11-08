import {spawn} from 'node:child_process';
const server=spawn(process.execPath,['server/index.mjs'],{stdio:'inherit'});
const client=spawn(process.execPath,['node_modules/vite/bin/vite.js'],{stdio:'inherit'});
let stopping=false;
function stop(code=0){if(stopping)return;stopping=true;server.kill();client.kill();process.exitCode=code;}
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>stop());
server.on('exit',code=>stop(code??1));client.on('exit',code=>stop(code??1));

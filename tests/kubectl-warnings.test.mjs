import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
const execute=promisify(execFile);
test('native kubectl warnings do not corrupt JSON, transient failures retry, real failures stop',{skip:os.platform()!=='win32',timeout:60000},async()=>{
 const root=path.resolve('.checks/kubectl-warning');await fs.mkdir(root,{recursive:true});
 const mock=path.join(root,'mock.ps1'),command=path.join(root,'kubectl.cmd'),fixture=path.join(root,'fixture.ps1');
 await fs.writeFile(mock,`$m=$env:KUBE_TEST_MODE
if($m -eq 'retry'){$n=if(Test-Path $env:KUBE_TEST_STATE){[int][IO.File]::ReadAllText($env:KUBE_TEST_STATE)}else{0};$n++;[IO.File]::WriteAllText($env:KUBE_TEST_STATE,[string]$n);if($n -lt 3){[Console]::Error.WriteLine('TLS handshake timeout');exit 1}}
if($m -eq 'fail'){[Console]::Error.WriteLine('Forbidden: permission denied');exit 2}
if($m -eq 'input'){$v=[Console]::In.ReadToEnd() | ConvertFrom-Json;if($v.kind -ne 'ConfigMap'){exit 3}}
[Console]::Error.WriteLine('I1109 Warning: watch ended client connection lost')
Write-Output '{"ok":true}'
exit 0
`);
 const windows=path.join(process.env.SystemRoot??'C:/Windows','System32/WindowsPowerShell/v1.0/powershell.exe');
 await fs.writeFile(command,`@echo off\r\n"${windows}" -NoProfile -ExecutionPolicy Bypass -File "${mock}"\r\nexit /b %errorlevel%\r\n`);
 await fs.writeFile(fixture,`$ErrorActionPreference='Stop'
$env:Path='${root.replaceAll("'","''")}';$env:PATHEXT='.COM;.EXE;.BAT;.CMD'
. '${path.resolve('packages/rm9/Common.ps1').replaceAll("'","''")}'
if($env:KUBE_TEST_MODE -eq 'input'){$v=Invoke-Rm9Kubectl -Arguments @('apply','-f','-') -InputText '{"kind":"ConfigMap"}'}else{$v=Invoke-Rm9Kubectl -Arguments @('get','test','-o','json')}
$j=($v|Out-String)|ConvertFrom-Json
if(-not $j.ok){throw 'JSON corrupted'}
Write-Host 'NATIVE_CHECK_PASSED'
`);
 const env={...process.env,PATH:root+';'+process.env.PATH,KUBE_TEST_STATE:path.join(root,'attempt.txt')};
 for(const mode of ['warn','retry','input']){
  await fs.rm(env.KUBE_TEST_STATE,{force:true});
  const result=await execute(windows,['-NoProfile','-File',fixture],{env:{...env,KUBE_TEST_MODE:mode},windowsHide:true});
  assert(result.stdout.includes('NATIVE_CHECK_PASSED'));
  if(mode==='retry')assert.equal(await fs.readFile(env.KUBE_TEST_STATE,'utf8'),'3');
 }
 await assert.rejects(execute(windows,['-NoProfile','-File',fixture],{env:{...env,KUBE_TEST_MODE:'fail'},windowsHide:true}),e=>String(e.stdout)+String(e.stderr)&&/Forbidden/.test(e.stdout+e.stderr));
});

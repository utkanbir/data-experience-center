[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port='15440',[string]$Service='all',[switch]$Disconnect)
$ErrorActionPreference='Stop'
$taskPlan=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'connections.json') -Raw | ConvertFrom-Json
$taskDir=Join-Path $PSScriptRoot '.connections'
$taskState=Join-Path $taskDir 'runtime.json'
if($Disconnect){
 if(Test-Path -LiteralPath $taskState){
  $taskSaved=Get-Content -LiteralPath $taskState -Raw | ConvertFrom-Json
  foreach($taskEntry in $taskSaved.services){
   if(-not $taskEntry.pid){continue}
   $taskProcess=Get-Process -Id $taskEntry.pid -ErrorAction SilentlyContinue
   if($taskProcess -and $taskProcess.ProcessName -match '^kubectl(\.exe)?$' -and $taskProcess.StartTime.ToUniversalTime().Ticks -eq ([datetime]$taskEntry.processStartedAt).ToUniversalTime().Ticks){$taskProcess.Kill();Write-Host ('Durduruldu: '+$taskEntry.name)}
  }
 }
 return
}
$taskKubectl=(Get-Command kubectl -ErrorAction Stop).Source
New-Item -ItemType Directory -Path $taskDir -Force | Out-Null
try{$taskLock=[IO.File]::Open((Join-Path $taskDir 'session.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)}catch{throw 'Bu paket icin Connect zaten acik. Ayni terminali kullanin veya Connect.ps1 -Disconnect calistirin.'}
$taskChildren=@();$taskEntries=@()
try{
 $taskSelected=@($taskPlan.services | Where-Object {$Service -eq 'all' -or $_.id -eq $Service})
 if(-not $taskSelected.Count){throw 'Bilinmeyen servis. connections.json dosyasini inceleyin.'}
 foreach($taskItem in $taskSelected){
  $taskBase=if($taskItem.id -eq 'postgres'){$Port}else{[int]$taskItem.localPort}
  $taskLocal=0
  foreach($taskCandidate in $taskBase..([Math]::Min(65535,$taskBase+30))){
   $taskListener=New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback,$taskCandidate)
   try{$taskListener.Start();$taskLocal=$taskCandidate;break}catch{}finally{$taskListener.Stop()}
  }
  if(-not $taskLocal){throw ('Bos yerel port bulunamadi: '+$taskItem.name)}
  $taskLog=Join-Path $taskDir ($taskItem.id+'-'+[Guid]::NewGuid().ToString('N'))
  $taskArgs=@('--context',$taskPlan.context,'-n',$taskPlan.namespace,'port-forward','--address=127.0.0.1',('service/'+$taskItem.service),($taskLocal.ToString()+':'+$taskItem.remotePort))
  $taskOptions=@{FilePath=$taskKubectl;ArgumentList=$taskArgs;PassThru=$true;RedirectStandardOutput=($taskLog+'.out');RedirectStandardError=($taskLog+'.err')}
  if($env:OS -eq 'Windows_NT'){$taskOptions.WindowStyle='Hidden'}
  $taskProcess=Start-Process @taskOptions
  $taskChildren+= $taskProcess
  $taskEntries+= [pscustomobject]@{id=$taskItem.id;name=$taskItem.name;localPort=$taskLocal;pid=$taskProcess.Id;processStartedAt=$taskProcess.StartTime.ToUniversalTime().ToString('o');status='starting';log=$taskLog}
 }
 $taskDeadline=[DateTime]::UtcNow.AddSeconds(45)
 while([DateTime]::UtcNow -lt $taskDeadline -and @($taskEntries | Where-Object {$_.status -eq 'starting'}).Count){
  foreach($taskEntry in $taskEntries | Where-Object {$_.status -eq 'starting'}){
   $taskProcess=$taskChildren | Where-Object {$_.Id -eq $taskEntry.pid}
   $taskText=''
   if(Test-Path -LiteralPath ($taskEntry.log+'.out')){
    $taskStream=[IO.File]::Open(($taskEntry.log+'.out'),[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    $taskReader=New-Object IO.StreamReader($taskStream)
    try{$taskText=$taskReader.ReadToEnd()}finally{$taskReader.Dispose()}
   }
   if($taskProcess.HasExited){$taskEntry.status='failed'}elseif($taskText.Contains('Forwarding from 127.0.0.1:')){$taskEntry.status='ready'}
  }
  Start-Sleep -Milliseconds 200
 }
 foreach($taskEntry in $taskEntries){if($taskEntry.status -eq 'starting'){$taskEntry.status='failed'}}
 [IO.File]::WriteAllText($taskState,(@{namespace=$taskPlan.namespace;context=$taskPlan.context;services=$taskEntries}|ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding $false))
 & (Join-Path $PSScriptRoot 'Get-Connections.ps1') -NoSecrets
 if(@($taskEntries | Where-Object {$_.status -ne 'ready'}).Count){
  foreach($taskEntry in $taskEntries | Where-Object {$_.status -ne 'ready'}){Write-Warning ('Baglanamadi: '+$taskEntry.name);if(Test-Path -LiteralPath ($taskEntry.log+'.err')){Get-Content -LiteralPath ($taskEntry.log+'.err') | Write-Host}}
  throw 'Tum tuneller acilamadi; baslatilan tuneller kapatiliyor. Deploy/pod durumunu kontrol edip Connect komutunu tekrar calistirin.'
 }
 Write-Host 'Tum yerel servisler baglandi. Bu tek terminal acik kalsin. Giris bilgileri: .\Get-Connections.ps1'
 Write-Host 'Durdurmak icin Ctrl+C; yalniz bu komutun actigi tuneller kapanir.'
 while($true){
  foreach($taskProcess in $taskChildren){if($taskProcess.HasExited){throw 'Bir tunel kapandi. Connect komutunu yeniden calistirin.'}}
  Start-Sleep -Seconds 1
 }
}finally{
 foreach($taskProcess in $taskChildren){if(-not $taskProcess.HasExited){$taskProcess.Kill();$taskProcess.WaitForExit()}}
 foreach($taskEntry in $taskEntries){$taskEntry.status='closed'}
 if($taskEntries.Count){[IO.File]::WriteAllText($taskState,(@{namespace=$taskPlan.namespace;context=$taskPlan.context;services=$taskEntries}|ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding $false))}
 $taskLock.Dispose()
}

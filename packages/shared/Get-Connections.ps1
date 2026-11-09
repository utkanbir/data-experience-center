[CmdletBinding()]
param([switch]$NoSecrets)
$ErrorActionPreference='Stop'
$taskPlan=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'connections.json') -Raw | ConvertFrom-Json
$taskSaved=$null;$taskState=Join-Path $PSScriptRoot '.connections/runtime.json'
if(Test-Path -LiteralPath $taskState){$taskSaved=Get-Content -LiteralPath $taskState -Raw | ConvertFrom-Json}
Write-Host ('=== RM__N__ | TUM BAGLANTILAR | '+$taskPlan.namespace+' ===')
foreach($taskItem in $taskPlan.services){
 $taskRuntime=if($taskSaved -and $taskSaved.namespace -eq $taskPlan.namespace){$taskSaved.services | Where-Object {$_.id -eq $taskItem.id}}else{$null}
 $taskPort=if($taskRuntime){$taskRuntime.localPort}else{$taskItem.localPort}
 $taskStatus=if($taskRuntime){$taskRuntime.status}else{'Connect henuz calistirilmadi'}
 Write-Host ('--- '+$taskItem.name+' ['+$taskStatus+']')
 $taskAddress=if($taskItem.kind -eq 'http'){'http://127.0.0.1:'+ $taskPort + $taskItem.path}else{'127.0.0.1:'+ $taskPort}
 if($taskItem.id -eq 'neo4j-bolt'){$taskAddress='bolt://127.0.0.1:'+$taskPort}
 Write-Host $taskAddress
 if($taskItem.database){Write-Host ('Database: '+$taskItem.database+' | User: '+$taskItem.username)}
 if($taskItem.id -eq 'trino'){Write-Host ('JDBC: jdbc:trino://127.0.0.1:'+$taskPort+'/models/dwh | user rm9_reader | yerel HTTP, auth yok')}
}
foreach($taskLine in $taskPlan.notes){Write-Host $taskLine}
foreach($taskExternal in $taskPlan.external){
 Write-Host ('--- '+$taskExternal.name+' | harici servis, tunel acilmaz')
 $taskFile=Join-Path $PSScriptRoot $taskExternal.settings
 if(Test-Path -LiteralPath $taskFile){
  $taskSettings=Get-Content -LiteralPath $taskFile -Raw | ConvertFrom-Json
  foreach($taskKey in @('host','apiHost','environmentId','orgId')){if($taskSettings.$taskKey){Write-Host ($taskKey+': '+$taskSettings.$taskKey)}}
 }
 Write-Host $taskExternal.command
}
if($NoSecrets){Write-Host 'Parola ve Cube JWT dahil tam bilgiler: .\Get-Connections.ps1';return}
Write-Host 'Gizli bilgiler yalniz bu terminalde gosterilir; paylasmayin. Dosyaya kaydedilmez.'
foreach($taskCredential in $taskPlan.credentials){
 try{
  $taskRaw=& kubectl --context $taskPlan.context -n $taskPlan.namespace get secret $taskCredential.secret -o json 2>$null
  if($LASTEXITCODE -ne 0){throw 'Secret yok'}
  $taskSecret=($taskRaw | Out-String)|ConvertFrom-Json
  $taskValue=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.($taskCredential.key)))
  Write-Host ($taskCredential.name+': '+$taskValue)
 }catch{Write-Host ($taskCredential.name+': henuz hazir degil; Deploy durumunu kontrol edin.')}
}
if($taskPlan.cubeToken){
 Write-Host 'Cube JWT (5 dakika):'
 try{& (Join-Path $PSScriptRoot 'Get-ApiToken.ps1')}catch{Write-Host 'Cube JWT henuz alinamadi; dashboard/pod durumunu kontrol edin.'}
}

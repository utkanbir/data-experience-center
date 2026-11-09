[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskPlanPath=Join-Path $PSScriptRoot 'external-connections.json'
if(-not (Test-Path -LiteralPath $taskPlanPath)) { return }
$taskPlan=Get-Content -LiteralPath $taskPlanPath -Raw -Encoding UTF8 | ConvertFrom-Json
$taskService=@($taskPlan.services | Where-Object { $_.id -eq 'paid' })
if($taskService.Count -ne 1 -or $taskService[0].mode -ne 'connect') { Write-Host 'Dis servis baglantisi sonraya birakildi. Ilgili kontroller erisim saglanana kadar denenmedi kalir.';return }
$taskHost=[string]$taskService[0].settings.host
$taskIdentity=[string]$taskService[0].settings.environmentId
$taskExisting=(Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'get','secret','rm6-dbt-service','--ignore-not-found=true','-o','json') | Out-String).Trim()
if($taskExisting) {
 $taskStored=$taskExisting | ConvertFrom-Json
 if(-not $taskStored.data.'api-token') { throw 'Yerel Secret icinde token eksik. Set baglanti scriptiyle kimlik bilgisini yeniden saglayin.' }
 $taskOldHost=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String([string]$taskStored.data.'host'))
 $taskOldIdentity=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String([string]$taskStored.data.'environment-id'))
 if(($taskHost -and $taskOldHost -cne $taskHost) -or ($taskIdentity -and $taskOldIdentity -cne $taskIdentity)) { throw 'Mevcut Secret farkli host/kimlige ait. Set-DbtConnection.ps1 ile baglantiyi bilerek guncelleyin ve Deploy tekrar calistirin.' }
 Write-Host 'Ayni baglanti icin yerel Secret var; gizli bilgi yeniden sorulmadi. Suresi dolmus token icin Set-DbtConnection.ps1 kullanin. Gecerlilik deneyde ayrica kontrol edilir.'
 return
}
Write-Host 'Secilen dis servis icin gizli bilgi yalniz bu terminalde sorulacak; ZIP veya web uygulamasina yazilmaz.'
& (Join-Path $PSScriptRoot 'Set-DbtConnection.ps1') -HostName $taskHost -EnvironmentId $taskIdentity

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if ($Rm2Namespace -notmatch '^komtas-[a-z0-9][a-z0-9-]{0,39}$') { throw 'Namespace izin verilen lab araliginda degil.' }
$taskExists = (Invoke-Rm2Kubectl -Arguments @('get','namespace',$Rm2Namespace,'--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskExists) { Write-Host 'Ortam zaten silinmis.'; return }
$taskNamespace = (Invoke-Rm2Kubectl -Arguments @('get','namespace',$Rm2Namespace,'-o','json') | Out-String) | ConvertFrom-Json
if ($taskNamespace.metadata.labels.'app.kubernetes.io/part-of' -ne $Rm2Namespace) { throw 'Lab sahiplik etiketi eslesmiyor. Otomatik silme durduruldu.' }
Write-Host "Context: $Rm2Context"
Write-Host "SILINECEK NAMESPACE: $Rm2Namespace"
Invoke-Rm2Kubectl -Arguments @('-n',$Rm2Namespace,'get','all,pvc,secret,configmap') | Out-Host
Write-Warning 'Namespace icindeki tum kaynaklar, PostgreSQL verisi ve parolalar silinecek. Bu islem geri alinamaz. Saklayacaginiz veriyi once yedekleyin.'
$taskAnswer = Read-Host "Onay icin namespace adini yazin ($Rm2Namespace)"
if ($taskAnswer -cne $Rm2Namespace) { Write-Host 'Iptal edildi.'; return }
Invoke-Rm2Kubectl -Arguments @('delete','namespace',$Rm2Namespace,'--wait=true','--timeout=120s') | Out-Host
Write-Host 'Namespace ve lab kaynaklari silindi. Tekrar kurmak icin Deploy.ps1 calistirin. PVC verisinin fiziksel temizlenmesi StorageClass reclaim politikasina baglidir.'

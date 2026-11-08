[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if ($Rm3Namespace -notmatch '^komtas-[a-z0-9][a-z0-9-]{0,39}$') { throw 'Namespace izin verilen lab araliginda degil.' }
$taskExists = (Invoke-Rm3Kubectl -Arguments @('get','namespace',$Rm3Namespace,'--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskExists) { Write-Host 'Ortam zaten silinmis.'; return }
$taskNamespace = (Invoke-Rm3Kubectl -Arguments @('get','namespace',$Rm3Namespace,'-o','json') | Out-String) | ConvertFrom-Json
if ($taskNamespace.metadata.labels.'app.kubernetes.io/part-of' -ne $Rm3Namespace) { throw 'Lab sahiplik etiketi eslesmiyor. Otomatik silme durduruldu.' }
Write-Host "Context: $Rm3Context"
Write-Host "SILINECEK NAMESPACE: $Rm3Namespace"
Invoke-Rm3Kubectl -Arguments @('-n',$Rm3Namespace,'get','all,pvc,secret,configmap') | Out-Host
Write-Warning 'Namespace icindeki tum kaynaklar, PostgreSQL verisi ve parolalar silinecek. Bu islem geri alinamaz. Saklayacaginiz veriyi once yedekleyin.'
$taskAnswer = Read-Host "Onay icin namespace adini yazin ($Rm3Namespace)"
if ($taskAnswer -cne $Rm3Namespace) { Write-Host 'Iptal edildi.'; return }
Invoke-Rm3Kubectl -Arguments @('delete','namespace',$Rm3Namespace,'--wait=true','--timeout=120s') | Out-Host
Write-Host 'Namespace ve lab kaynaklari silindi. Tekrar kurmak icin Deploy.ps1 calistirin. PVC verisinin fiziksel temizlenmesi StorageClass reclaim politikasina baglidir.'

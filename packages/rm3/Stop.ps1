[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm3Kubectl -Arguments @('-n', $Rm3Namespace, 'scale', 'statefulset/postgres', '--replicas=0') | Out-Host
Write-Host 'PostgreSQL durduruldu. PVC ve Secret korundu. Tekrar baslatmak icin Deploy.ps1 calistirin.'

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm2Kubectl -Arguments @('-n', $Rm2Namespace, 'scale', 'statefulset/postgres', '--replicas=0') | Out-Host
Write-Host 'PostgreSQL durduruldu. PVC ve Secret korundu. Tekrar baslatmak icin Deploy.ps1 calistirin.'

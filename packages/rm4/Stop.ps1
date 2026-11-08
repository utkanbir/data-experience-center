[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm4Kubectl -Arguments @('-n', $Rm4Namespace, 'scale', 'statefulset/postgres', '--replicas=0') | Out-Host
Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'scale','deployment/cube','deployment/cubestore','deployment/dashboard','deployment/dbt-docs','--replicas=0') | Out-Host
Write-Host 'PostgreSQL ve servisler durduruldu. PVC ve Secret korundu. Tekrar baslatmak icin Deploy.ps1 calistirin.'

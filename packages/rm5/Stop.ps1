[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm5Kubectl -Arguments @('-n', $Rm5Namespace, 'scale', 'statefulset/postgres', '--replicas=0') | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'scale','deployment/cube','deployment/cubestore','deployment/dashboard','deployment/dbt-docs','deployment/openmetadata','--replicas=0') | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'scale','statefulset/metadata-postgres','statefulset/elasticsearch','--replicas=0') | Out-Host
Write-Host 'PostgreSQL ve servisler durduruldu. PVC ve Secret korundu. Tekrar baslatmak icin Deploy.ps1 calistirin.'

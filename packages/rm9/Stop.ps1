[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm9Kubectl -Arguments @('-n', $Rm9Namespace, 'scale', 'statefulset/postgres','statefulset/postgres-reference', '--replicas=0') | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'scale','deployment/trino','deployment/cube','deployment/cubestore','deployment/dashboard','deployment/dbt-docs','deployment/openmetadata','--replicas=0') | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'scale','statefulset/metadata-postgres','statefulset/elasticsearch','--replicas=0') | Out-Host
Write-Host 'PostgreSQL ve servisler durduruldu. PVC ve Secret korundu. Tekrar baslatmak icin Deploy.ps1 calistirin.'

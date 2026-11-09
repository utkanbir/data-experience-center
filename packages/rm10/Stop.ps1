[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm10Kubectl -Arguments @('-n', $Rm10Namespace, 'scale', 'statefulset/postgres', '--replicas=0') | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'scale','deployment/cube','deployment/cubestore','deployment/dashboard','deployment/dbt-docs','deployment/openmetadata','--replicas=0') | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'scale','statefulset/metadata-postgres','statefulset/elasticsearch','--replicas=0') | Out-Host
Write-Host 'PostgreSQL ve servisler durduruldu. PVC ve Secret korundu. Tekrar baslatmak icin Deploy.ps1 calistirin.'

Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'scale','statefulset/neo4j','--replicas=0') | Out-Host

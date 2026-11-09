[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'exec','rm9-artifacts','--','rm','-f','/artifacts/dbt-status.txt','/artifacts/dbt-checks.json') | Out-Host
Start-Rm9Job -Name 'rm9-dbt' -Manifest (Join-Path $PSScriptRoot 'k8s/dbt-job.yaml')

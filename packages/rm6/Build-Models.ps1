[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'exec','rm6-artifacts','--','rm','-f','/artifacts/dbt-status.txt','/artifacts/dbt-checks.json') | Out-Host
Start-Rm6Job -Name 'rm6-dbt' -Manifest (Join-Path $PSScriptRoot 'k8s/dbt-job.yaml')

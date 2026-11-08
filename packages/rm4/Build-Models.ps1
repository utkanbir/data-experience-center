[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'exec','rm4-artifacts','--','rm','-f','/artifacts/dbt-status.txt','/artifacts/dbt-checks.json') | Out-Host
Start-Rm4Job -Name 'rm4-dbt' -Manifest (Join-Path $PSScriptRoot 'k8s/dbt-job.yaml')

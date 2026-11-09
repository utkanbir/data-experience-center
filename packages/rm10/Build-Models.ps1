[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'exec','rm10-artifacts','--','rm','-f','/artifacts/dbt-status.txt','/artifacts/dbt-checks.json') | Out-Host
Start-Rm10Job -Name 'rm10-dbt' -Manifest (Join-Path $PSScriptRoot 'k8s/dbt-job.yaml')

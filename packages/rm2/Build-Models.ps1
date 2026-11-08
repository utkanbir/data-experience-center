[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm2Kubectl -Arguments @('-n',$Rm2Namespace,'exec','rm2-artifacts','--','rm','-f','/artifacts/dbt-status.txt','/artifacts/dbt-checks.json') | Out-Host
Start-Rm2Job -Name 'rm2-dbt' -Manifest (Join-Path $PSScriptRoot 'k8s/dbt-job.yaml')

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'exec','rm7-artifacts','--','rm','-f','/artifacts/dbt-status.txt','/artifacts/dbt-checks.json') | Out-Host
Start-Rm7Job -Name 'rm7-dbt' -Manifest (Join-Path $PSScriptRoot 'k8s/dbt-job.yaml')

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'exec','rm8-artifacts','--','rm','-f','/artifacts/dbt-status.txt','/artifacts/dbt-checks.json') | Out-Host
Start-Rm8Job -Name 'rm8-dbt' -Manifest (Join-Path $PSScriptRoot 'k8s/dbt-job.yaml')

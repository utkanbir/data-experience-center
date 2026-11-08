[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'exec','rm5-artifacts','--','rm','-f','/artifacts/dbt-status.txt','/artifacts/dbt-checks.json') | Out-Host
Start-Rm5Job -Name 'rm5-dbt' -Manifest (Join-Path $PSScriptRoot 'k8s/dbt-job.yaml')

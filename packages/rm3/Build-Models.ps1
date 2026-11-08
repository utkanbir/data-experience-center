[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm3Kubectl -Arguments @('-n',$Rm3Namespace,'exec','rm3-artifacts','--','rm','-f','/artifacts/dbt-status.txt','/artifacts/dbt-checks.json') | Out-Host
Start-Rm3Job -Name 'rm3-dbt' -Manifest (Join-Path $PSScriptRoot 'k8s/dbt-job.yaml')

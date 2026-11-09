[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'exec','rm8-artifacts','--','rm','-f','/artifacts/governance-status.txt','/artifacts/governance-checks.json') | Out-Host
Start-Rm8Job -Name 'rm8-catalog-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-verify-job.yaml')

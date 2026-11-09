[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'exec','rm9-artifacts','--','rm','-f','/artifacts/governance-status.txt','/artifacts/governance-checks.json') | Out-Host
Start-Rm9Job -Name 'rm9-catalog-sync' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-sync-job.yaml')

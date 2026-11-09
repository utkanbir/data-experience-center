[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'exec','rm10-artifacts','--','rm','-f','/artifacts/governance-status.txt','/artifacts/governance-checks.json') | Out-Host
Start-Rm10Job -Name 'rm10-catalog-sync' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-sync-job.yaml')

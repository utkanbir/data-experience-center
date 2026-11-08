[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'exec','rm5-artifacts','--','rm','-f','/artifacts/governance-status.txt','/artifacts/governance-checks.json') | Out-Host
Start-Rm5Job -Name 'rm5-catalog-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-verify-job.yaml')

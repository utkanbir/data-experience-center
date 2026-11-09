[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'exec','rm6-artifacts','--','rm','-f','/artifacts/managed-status.txt','/artifacts/managed-checks.json') | Out-Host
Start-Rm6Job -Name 'rm6-managed' -Manifest (Join-Path $PSScriptRoot 'k8s/managed-job.yaml')

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'exec','rm4-artifacts','--','rm','-f','/artifacts/cube-status.txt') | Out-Host
Start-Rm4Job -Name 'rm4-cube-check' -Manifest (Join-Path $PSScriptRoot 'k8s/cube-check-job.yaml')

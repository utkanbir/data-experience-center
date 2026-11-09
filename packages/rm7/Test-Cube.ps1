[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'exec','rm7-artifacts','--','rm','-f','/artifacts/cube-status.txt') | Out-Host
Start-Rm7Job -Name 'rm7-cube-check' -Manifest (Join-Path $PSScriptRoot 'k8s/cube-check-job.yaml')

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'exec','rm9-artifacts','--','rm','-f','/artifacts/cube-status.txt') | Out-Host
Start-Rm9Job -Name 'rm9-cube-check' -Manifest (Join-Path $PSScriptRoot 'k8s/cube-check-job.yaml')

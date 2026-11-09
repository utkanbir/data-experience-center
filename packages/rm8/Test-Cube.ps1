[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'exec','rm8-artifacts','--','rm','-f','/artifacts/cube-status.txt') | Out-Host
Start-Rm8Job -Name 'rm8-cube-check' -Manifest (Join-Path $PSScriptRoot 'k8s/cube-check-job.yaml')

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'exec','rm10-artifacts','--','rm','-f','/artifacts/cube-status.txt') | Out-Host
Start-Rm10Job -Name 'rm10-cube-check' -Manifest (Join-Path $PSScriptRoot 'k8s/cube-check-job.yaml')

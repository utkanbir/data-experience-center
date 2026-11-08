[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'exec','rm5-artifacts','--','rm','-f','/artifacts/cube-status.txt') | Out-Host
Start-Rm5Job -Name 'rm5-cube-check' -Manifest (Join-Path $PSScriptRoot 'k8s/cube-check-job.yaml')

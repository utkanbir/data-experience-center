[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm6Job -Name 'rm6-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')

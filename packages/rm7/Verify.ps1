[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm7Job -Name 'rm7-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')

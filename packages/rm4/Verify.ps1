[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm4Job -Name 'rm4-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')

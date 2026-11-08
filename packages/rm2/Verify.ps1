[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm2Job -Name 'rm2-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')

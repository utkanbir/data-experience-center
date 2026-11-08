[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm3Job -Name 'rm3-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')

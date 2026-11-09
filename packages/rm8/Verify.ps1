[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm8Job -Name 'rm8-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')

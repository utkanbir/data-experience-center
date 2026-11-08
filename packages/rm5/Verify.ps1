[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm5Job -Name 'rm5-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm8Job -Name 'rm8-catalog-fault' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-fault-job.yaml')

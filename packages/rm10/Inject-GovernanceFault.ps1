[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm10Job -Name 'rm10-catalog-fault' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-fault-job.yaml')

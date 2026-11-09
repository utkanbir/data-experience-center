[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm9Job -Name 'rm9-catalog-restore' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-restore-job.yaml')

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm10Job -Name 'rm10-catalog-restore' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-restore-job.yaml')

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm8Job -Name 'rm8-catalog-restore' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-restore-job.yaml')

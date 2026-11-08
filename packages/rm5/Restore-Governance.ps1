[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Start-Rm5Job -Name 'rm5-catalog-restore' -Manifest (Join-Path $PSScriptRoot 'k8s/catalog-restore-job.yaml')

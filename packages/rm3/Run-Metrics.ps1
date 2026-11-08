[CmdletBinding()]
param()
& (Join-Path $PSScriptRoot 'Build-Models.ps1')
& (Join-Path $PSScriptRoot 'Show-Metrics.ps1')

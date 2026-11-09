[CmdletBinding()]
param()
& (Join-Path $PSScriptRoot 'Sync-Graph.ps1')

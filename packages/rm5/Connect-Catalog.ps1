[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port=8585)
. (Join-Path $PSScriptRoot 'Common.ps1')
Write-Host "OpenMetadata: http://127.0.0.1:$Port | Terminal acik kalmali."
& kubectl --context $Rm5Context -n $Rm5Namespace port-forward --address=127.0.0.1 service/openmetadata "${Port}:8585"
if ($LASTEXITCODE -ne 0) { throw 'Katalog tuneli durdu.' }

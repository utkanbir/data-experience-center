[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port=18099)
. (Join-Path $PSScriptRoot 'Common.ps1')
Write-Host "Trino: http://127.0.0.1:$Port | Terminal acik kalmali. Yalniz yerel deney; kimlik dogrulama yok."
& kubectl --context $Rm9Context -n $Rm9Namespace port-forward --address=127.0.0.1 service/trino "${Port}:8080"
if($LASTEXITCODE -ne 0){throw 'Trino tuneli durdu.'}

[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15441)
. (Join-Path $PSScriptRoot 'Common.ps1')
Write-Host "PostgreSQL SQL erisimi: 127.0.0.1:$Port"
Write-Host 'Bu terminal acik kalmali. Durdurmak icin Ctrl+C.'
& kubectl --context $Rm10Context -n $Rm10Namespace port-forward --address=127.0.0.1 service/postgres "${Port}:5432"
if ($LASTEXITCODE -ne 0) { throw 'Port-forward durdu. Pod durumu ve yerel port kullanimini kontrol edin.' }

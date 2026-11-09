[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 4008)
. (Join-Path $PSScriptRoot 'Common.ps1')
Write-Host "Cube: http://127.0.0.1:$Port | Bu terminal acik kalmali."
& kubectl --context $Rm8Context -n $Rm8Namespace port-forward --address=127.0.0.1 service/cube "${Port}:4000"
if ($LASTEXITCODE -ne 0) { throw 'Cube tuneli durdu. Portu ve servisi kontrol edin.' }

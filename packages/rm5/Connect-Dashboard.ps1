[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 8505)
. (Join-Path $PSScriptRoot 'Common.ps1')
Write-Host "Dashboard: http://127.0.0.1:$Port | Bu terminal acik kalmali."
& kubectl --context $Rm5Context -n $Rm5Namespace port-forward --address=127.0.0.1 service/dashboard "${Port}:8501"
if ($LASTEXITCODE -ne 0) { throw 'Dashboard tuneli durdu. Portu ve servisi kontrol edin.' }

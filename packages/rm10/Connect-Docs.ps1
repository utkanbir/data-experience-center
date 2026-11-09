[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 18090)
. (Join-Path $PSScriptRoot 'Common.ps1')
Write-Host "dbt dokumani ve model grafigi: http://127.0.0.1:$Port/static_index.html"
Write-Host 'Bu terminal acik kalmali. Durdurmak icin Ctrl+C. Dokuman dbt Job tamamlaninca hazir olur.'
& kubectl --context $Rm10Context -n $Rm10Namespace port-forward --address=127.0.0.1 service/dbt-docs "${Port}:8080"
if ($LASTEXITCODE -ne 0) { throw 'dbt docs tuneli durdu. Deploy.ps1 ile docs servisini hazirlayin ve portu kontrol edin.' }

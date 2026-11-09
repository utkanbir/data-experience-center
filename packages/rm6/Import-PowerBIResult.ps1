[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Path)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskRows=@(Import-Csv -LiteralPath $Path)
if ($taskRows.Count -ne 6) { throw 'CSV tam 6 ay/kanal satiri icermeli.' }
foreach ($taskColumn in @('month','channel','net_revenue','net_liters','average_price')) { if ($taskColumn -notin $taskRows[0].PSObject.Properties.Name) { throw "Eksik CSV kolonu: $taskColumn" } }
Write-Rm6Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm6-powerbi-export';namespace=$Rm6Namespace};data=@{'result.csv'=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path)}}
Write-Host 'Kullanici kaynakli Power BI CSV kaydedildi. Run-Scenario gercek API sonucu ve bagimsiz referansla karsilastirir; connectoru otomatik calistirmis sayilmaz.'

[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Path)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskFile=Get-Item -LiteralPath $Path
if($taskFile.Length -gt 500000 -or $taskFile.PSIsContainer) { throw 'En fazla 500 KB JSON dosyasi gerekli.' }
$taskText=[IO.File]::ReadAllText($taskFile.FullName)
$taskValue=$taskText | ConvertFrom-Json
if($taskValue.source -ne 'manual_workflow_record' -or @($taskValue.records).Count -ne 3) { throw 'Uc gercek varlik icin manuel workflow kaydi gerekli.' }
Write-Rm7Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm7-approval';namespace=$Rm7Namespace};data=@{'approval.json'=$taskText}}
Write-Host 'Yalniz kullanici kaynakli kayit yuklendi; onay islemi yapilmadi. Run-Scenario ile guncel varlik surumune karsi tutarlilik kontrol edilir.'

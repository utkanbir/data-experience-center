[CmdletBinding()]
param()
Write-Host 'Tum yerel baglantilari ac: .\Connect.ps1'
Write-Host 'Tum adresler ve giris bilgileri: .\Get-Connections.ps1'
Write-Host 'Tek Connect terminali acik kalsin; Ctrl+C tum oturum tunellerini kapatir.'
& (Join-Path $PSScriptRoot 'Get-Connections.ps1') -NoSecrets

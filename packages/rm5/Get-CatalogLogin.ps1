[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret=(Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'get','secret','rm5-governance','-o','json') | Out-String) | ConvertFrom-Json
Write-Host 'OpenMetadata kullanici: admin@open-metadata.org'
Write-Host ('Parola: '+[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'admin-password')))
Write-Host 'Parolayi paylasmayin. Once Connect-Catalog.ps1 tunelini baslatin.'

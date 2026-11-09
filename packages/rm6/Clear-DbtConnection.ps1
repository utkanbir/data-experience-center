[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'delete','secret','rm6-dbt-service','--ignore-not-found=true') | Out-Host
Write-Host 'Yerel servis tokeni kaldirildi. Harici dbt hesabi/tokeni veya veritabani silinmedi.'

[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'delete','secret','rm7-informatica','--ignore-not-found=true') | Out-Host
Write-Host 'Yalniz yerel Secret silindi; harici JWT/org iptal edilmedi. Yeni rapor icin Run-Scenario calistirin.'

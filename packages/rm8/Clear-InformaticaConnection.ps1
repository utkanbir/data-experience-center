[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'delete','secret','rm8-informatica','--ignore-not-found=true') | Out-Host
Write-Host 'Yalniz yerel Secret silindi; harici JWT/org iptal edilmedi. Yeni rapor icin Run-Scenario calistirin.'

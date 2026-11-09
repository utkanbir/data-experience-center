[CmdletBinding()]
param()
Write-Host '=== REFERANS MIMARI 7 | ERISIM REHBERI ==='
Write-Host 'PostgreSQL: 127.0.0.1:15438 | DB: komtas_rm7 | User: rm7_bi'
Write-Host 'SQL erisimi: ayri terminalde .\Connect.ps1; parola: .\Get-Connection.ps1'
Write-Host 'dbt Core CLI/Job: .\Build-Models.ps1 | dokuman: .\Connect-Docs.ps1'
Write-Host 'dbt dokumani (tunel acikken): http://127.0.0.1:18087/static_index.html'
Write-Host 'Streamlit: .\Connect-Dashboard.ps1 | http://127.0.0.1:8507'
Write-Host 'Cube REST API: .\Connect-Cube.ps1 | http://127.0.0.1:4007/cubejs-api/v1/meta'
Write-Host 'API tarayicida tokensiz acilmaz. 5 dakikalik JWT: .\Get-ApiToken.ps1'
Write-Host 'Python API istemcisi: .\Query-Metrics.ps1 | API ve iki tuketici kontrolu: .\Test-Cube.ps1'
Write-Host 'Cube Store kume ici destek servisidir; ayri kullanici UI yoktur. Power BI bu profilde kurulmaz.'
Write-Host 'Deney/rapor: .\Run-Scenario.ps1 | Tam silme: .\Remove-Environment.ps1'

Write-Host 'Informatica CDGC: harici org portalinizi kendi erisiminizle acin. API hostu web arayuzu degildir.'
Write-Host 'Baglanti: Set-InformaticaConnection.ps1 / bash set-informatica-connection.sh; varliklar: governance/settings.json; kontrol: Run-Governance.ps1 / bash run-governance.sh'

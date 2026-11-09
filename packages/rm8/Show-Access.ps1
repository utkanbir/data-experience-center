[CmdletBinding()]
param()
Write-Host '=== REFERANS MIMARI 8 | ERISIM REHBERI ==='
Write-Host 'PostgreSQL: 127.0.0.1:15439 | DB: komtas_rm8 | User: rm8_bi'
Write-Host 'SQL erisimi: ayri terminalde .\Connect.ps1; parola: .\Get-Connection.ps1'
Write-Host 'dbt Core CLI/Job: .\Build-Models.ps1 | dokuman: .\Connect-Docs.ps1'
Write-Host 'dbt dokumani (tunel acikken): http://127.0.0.1:18088/static_index.html'
Write-Host 'Streamlit: .\Connect-Dashboard.ps1 | http://127.0.0.1:8508'
Write-Host 'Cube REST API: .\Connect-Cube.ps1 | http://127.0.0.1:4008/cubejs-api/v1/meta'
Write-Host 'API tarayicida tokensiz acilmaz. 5 dakikalik JWT: .\Get-ApiToken.ps1'
Write-Host 'Python API istemcisi: .\Query-Metrics.ps1 | API ve iki tuketici kontrolu: .\Test-Cube.ps1'
Write-Host 'Cube Store kume ici destek servisidir; ayri kullanici UI yoktur.'
Write-Host 'Deney/rapor: .\Run-Scenario.ps1 | Tam silme: .\Remove-Environment.ps1'

Write-Host 'OpenMetadata: .\Connect-Catalog.ps1 | http://127.0.0.1:18588'
Write-Host 'Katalog girisi: .\Get-CatalogLogin.ps1 | Varsayilan admin parolasi ilk sync sirasinda rastgele lab parolasina cevrilir.'
Write-Host 'Katalogda: RM8Postgres > komtas_rm8 > dwh > v_sales_detail; Metrics: NetRevenue / NetLiters / AveragePrice.'
Write-Host 'Metadata senkronizasyonu: .\Sync-Catalog.ps1 | Salt governance kontrolu: .\Verify-Catalog.ps1'

Write-Host 'Metadata PostgreSQL: kume ici metadata-postgres:5432; OpenMetadata depolamasi, ikinci is veri kaynagi degildir.'
Write-Host 'Elasticsearch: kume ici elasticsearch:9200; katalog arama destegi, ayri kullanici ekrani yoktur.'

Write-Host 'CDGC: dis org/JWT; yerel baglanti: Set-InformaticaConnection.ps1 / bash set-informatica-connection.sh'
Write-Host 'Is tanimi: CDGC | Teknik metadata/kalite: OpenMetadata | Hesap: Cube. Harici API hostu portal adresi degildir.'
Write-Host 'Esleme: bridge/settings.json ve cdgc/settings.json | Kopyala: Sync-BusinessDefinitions.ps1 / bash sync-business-definitions.sh | Kontrol: Verify-DualCatalog.ps1 / bash verify-dual-catalog.sh'

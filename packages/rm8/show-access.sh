#!/usr/bin/env bash
printf '%s\n' '=== REFERANS MIMARI 8 | ERISIM REHBERI ===' 'PostgreSQL: 127.0.0.1:15439 | DB: komtas_rm8 | User: rm8_bi' 'SQL: bash connect.sh | parola: bash get-connection.sh' 'dbt: bash build-models.sh | dokuman tuneli: bash connect-docs.sh' 'dbt dokumani: http://127.0.0.1:18088/static_index.html' 'Streamlit: bash connect-dashboard.sh | http://127.0.0.1:8508' 'Cube REST: bash connect-cube.sh | http://127.0.0.1:4008/cubejs-api/v1/meta' '5 dakikalik JWT: bash get-api-token.sh | Python: bash query-metrics.sh' 'API/iki tuketici kontrolu: bash test-cube.sh' 'Cube Store kume ici destek servisidir, ayri UI yoktur.' 'Deney: bash run-scenario.sh | Tam silme: bash remove-environment.sh'

printf '%s\n' 'OpenMetadata: bash connect-catalog.sh | http://127.0.0.1:18588' 'Giris: bash get-catalog-login.sh' 'Metadata sync: bash sync-catalog.sh | Governance kontrolu: bash verify-catalog.sh' 'Katalog: RM8Postgres > komtas_rm8 > dwh > v_sales_detail; Metrics: NetRevenue / NetLiters / AveragePrice'

printf '%s\n' 'Metadata PostgreSQL: kume ici metadata-postgres:5432; OpenMetadata depolamasi, ikinci is veri kaynagi degildir.' 'Elasticsearch: kume ici elasticsearch:9200; katalog arama destegi, ayri kullanici ekrani yoktur.'

printf '%s\n' 'CDGC: dis org/JWT; yerel baglanti: Set-InformaticaConnection.ps1 / bash set-informatica-connection.sh'
printf '%s\n' 'Is tanimi: CDGC | Teknik metadata/kalite: OpenMetadata | Hesap: Cube. Harici API hostu portal adresi degildir.'
printf '%s\n' 'Esleme: bridge/settings.json ve cdgc/settings.json | Kopyala: Sync-BusinessDefinitions.ps1 / bash sync-business-definitions.sh | Kontrol: Verify-DualCatalog.ps1 / bash verify-dual-catalog.sh'

# RM5 doğrulama · 9 Kasım 2026 · Europe/Istanbul

Gerçek Docker Desktop Kubernetes kurulumu, ayrı ve geçici `komtas-rm5-check-1109` namespace’inde yapıldı. RM1–RM4 ortamları değiştirilmedi.

- Tam Deploy.ps1 tekrar çalıştırması başarılı: PostgreSQL iş verisi, 7 dbt modeli / 12 veri testi ve dokümanı, Cube Core/Store, Streamlit/Python, metadata PostgreSQL’i, Elasticsearch ve OpenMetadata.
- OpenMetadata 2.0.7, Elasticsearch 9.3.0, PostgreSQL 17.11-bookworm, Cube Core/Store v1.6.77, Python 3.12.12-slim-bookworm, psycopg 3.2.13; dbt-core 1.9.10 / dbt-postgres 1.9.1 / Streamlit 1.51.0.
- Metadata migration ve gerçek basic login başarılı. İlk admin parolası yerel rastgele Secret parolasına çevrildi; parola ve token rapora alınmaz.
- 12 PostgreSQL tablo/görünümü API ile kaydedildi. Satış görünümünün 21 kolonunun adları/türleri gerçek pg_catalog ile eşleşti. Görünüm search/query API’sinde bulundu.
- SalesStewards owner, üç glossary terimi ve üç metrik kaydı geri okunarak doğrulandı. dbt manifest bağımlılıkları lineage API’sinde doğrulandı.
- Metrik SQL kayıtları ve yapılandırılmış Cube ifadeleri, beklenen metric-contract.json metinleriyle eşleşti. Runtime sayısal sonuçlar ayrıca bağımsız referansla sınandı.
- Gerçek SELECT count(*) sonucu, OpenMetadata tableRowCountToEqual test sonucu olarak yazıldı ve geri okundu. Airflow, native ingestion pipeline veya zamanlanmış profiler kurulmadı.
- BeverageRevenue ürün kaydı domain/owner/görünüm/üç metrik ilişkileriyle doğrulandı. Kayıt DEVELOPMENT aşamasında; insan onayı, contract/SLO enforcement ve tam yaşam döngüsü sağlanmış sayılmaz.
- Negatif deney: NetRevenue owner bağı kaldırıldı. dbt, Cube referans eşleşmesi ve iki tüketici kontrolleri geçerken om_owner başarısız oldu; Run-Scenario başarısızlık raporu üretti.
- Restore sonrası tam Run-Scenario: 23 kontrol + 4 SQL yürütmesi, 27/27 geçti. Tasarım kapsam notu 43.3/100 olarak kalır.
- Windows kubectl cp sürücü harfi belirsizliği, kanıt klasöründe göreli hedef kullanılarak giderildi. Kanıt aktarımının doğrulaması, functional kontrol durumlarından ayrı yapıldı. Aynı düzeltme RM2–RM4 paketlerine de uygulandı.
- Uygulama/paket testleri ve derleme; PowerShell ve 24 Bash betiği sözdizimi kontrolleri yapıldı. Gerçek Linux host kurulumu ayrıca doğrulanmalı.

OpenMetadata 2.0.7 API uyarlamaları canlı testle doğrulandı: sağlık kontrolü 8586 /healthcheck; lineage okuması /api/v1/lineage/table/{id}; kalite sonucu POST /api/v1/dataQuality/testCases/testCaseResults/{fqn}; ürün varlıkları ayrı /assets/add işlemiyle bağlanır. Verify-Catalog owner eksiklerini kendiliğinden düzeltmez. Restore-Governance ve Sync-Catalog değişiklik yapan açık adımlardır.

Stack tek düğümlü lab’dır. Metadata PostgreSQL’i ikinci iş kaynağı federasyonu değildir. İnsan onayı, kurumsal politika işletimi, sürekli izleme, ontology/Neo4j ve Agent360 uygulanmadı. PyPI ve Docker registry erişimi gerekir.

Resmî kaynaklar: https://github.com/open-metadata/OpenMetadata/releases/tag/2.0.7-release · https://github.com/open-metadata/OpenMetadata/blob/2.0.7-release/docker/docker-compose-quickstart/docker-compose-postgres.yml · https://github.com/open-metadata/OpenMetadata/tree/2.0.7-release/openmetadata-spec/src/main/resources/json/schema

Son sağlıklı Windows raporunda 12/12 araç kanıtı dosyası yerel kanitlar klasöründe doğrulandı. Üç gerçek sonuc.json dosyası uygulamanın validator’ından geçti: owner hatası 26/27; iki sağlıklı koşum 27/27. Uygulama ve paket regresyon testleri: 31 geçti.

Stop.ps1 gerçek testte tüm application Deployment ve üç StatefulSet’i sıfır replikaya indirdi. Ardından sahiplik ve yazılı namespace kontrolüyle Remove-Environment çalıştırıldı; geçici namespace’in kaldırıldığı doğrulandı.

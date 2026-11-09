# Referans Mimari 5 · Ortak metrik ve governance

Ortak soru: HoReCa net geliri Ocak 2025’ten Şubat 2025’e neden düştü; hacim ve fiyat etkileri ne kadar?

PostgreSQL raw → dbt Core → PostgreSQL dwh → Cube Core REST → Streamlit ve Python.
Cube Store lab destek servisidir; bu profilde pre-aggregation veya performans kazanımı ölçülmez.
Net gelir, net litre ve ağırlıklı ortalama fiyat cube/schema/Sales.js içinde tanımlıdır. Tüketiciler formülü kopyalamaz.

## Kurulum

Docker Desktop Linux containers, Kubernetes docker-desktop context, varsayılan StorageClass ve kubectl gerekli. İnternet üzerinden Docker Hub/PyPI erişimi gerekir.
Windows: ZIP’i çıkar, rm5-kubernetes içinde terminal aç. İmza/indirme engeli varsa yalnız paket scriptleri için `Get-ChildItem -LiteralPath . -Filter '*.ps1' -File | Unblock-File`.
Sırayla `.\Deploy.ps1`, `.\Run-Scenario.ps1`.
Linux: `bash deploy.sh`, `bash run-scenario.sh`. Bash ve OpenSSL gerekli.
dbt Job her çalışmada dbt-core 1.9.10 ve dbt-postgres 1.9.1 yükler. Dashboard ve kontrol Job’u streamlit 1.51.0 yükler.
Cube Core/Store v1.6.77, PostgreSQL 17.11-bookworm, Python 3.12.12-slim-bookworm sabittir.

## Erişim

Deploy sonunda Show-Access tüm bileşenleri listeler. Tünelleri ayrı terminallerde açık tut.
- SQL: `.\Connect.ps1` / `bash connect.sh`; 127.0.0.1:15436, komtas_rm5, rm5_bi. Parola Get-Connection ile alınır.
- dbt dokümanı: `.\Connect.ps1` / `bash connect.sh`; http://127.0.0.1:18085/static_index.html.
- Streamlit: `.\Connect.ps1` / `bash connect.sh`; http://127.0.0.1:8505.
- Cube API: `.\Connect.ps1` / `bash connect.sh`; http://127.0.0.1:4005/cubejs-api/v1/meta. Web yönetim ekranı değildir; JWT gerektirir.
- 5 dakikalık JWT: `.\Get-ApiToken.ps1` / `bash get-api-token.sh`. Authorization başlığında kullan; tokeni paylaşma.
- Python tüketicisi: `.\Query-Metrics.ps1` / `bash query-metrics.sh`. Yerel Python gerekmez.
- Cube Store: küme içi servis, ayrı UI yoktur.

## Deney ve kanıt

Run-Scenario dbt’yi ve API/iki tüketici testini yeniden çalıştırır; üç iş sorgusu ve SQL referans kontrolleri uygular. reports/run-.../rapor.html tarayıcıda açılır; sonuc.json uygulamadaki Senaryo & deney bölümüne yüklenir.
kanitlar: dbt manifest/build_results/static_index, Cube API sonucu ve üretilen SQL, Python ve dashboard tüketici sonuçları, kontrol durumları.
23 kontrol + 4 SQL yürütme kaydı. Tokensiz API ret, 6 satır × 3 metrik referans eşleşmesi ve iki tüketici kod yolu ayrı değerlendirilir. Ekran servisinin sağlık kontrolü görsel tarayıcı testi yerine geçmez.
HoReCa 8164.80 → 3628.80 EUR; net fark −4536 EUR. Fiyat değişmez; sentetik veri hacim etkisini gösterir, ticari kök nedeni kanıtlamaz.

## Kapsam ve sınırlar

Data360: dbt model/test/dokümantasyon ve PostgreSQL. Business360: ortak executable metrik API’si ve iki tüketici. OpenMetadata ile owner, glossary, dbt manifest lineage ve demo data product kaydı eklenir. İnsan onayı, kurumsal politika, contract/SLO enforcement, federasyon, ontology ve Agent360 uygulanmaz. Tasarım kapsam notu 43.3/100; başarılı test oranı kapsam notunu değiştirmez.
Cube Cloud ve SQL/BI connector yetenekleri bu REST deneyinde doğrulanmaz.
Cube production auth modunda, tüm Services ClusterIP ve yerel tüneller loopback üzerindedir. JWT lab paylaşılmış servis kimliğidir; kullanıcı bazlı RLS/SSO uygulanmaz.

## Durdurma ve silme

Stop.ps1 / bash stop.sh PostgreSQL ve uygulama Deployment’larını durdurur; PVC/Secret korunur. Deploy yeniden başlatır.
Remove-Environment.ps1 / bash remove-environment.sh yalnız lab sahiplik etiketi eşleşen namespace’i adını yazarak onaydan sonra siler. Veri ve parolalar silinir; önce yedekle.

## İsteğe bağlı semantik hata deneyi

`Set-MetricFault.ps1 -Mode Inject` / `bash set-metric-fault.sh inject` yalnız Cube formülünü brüt gelire çevirir; dbt modeli değişmez. Run-Scenario tekrar çalıştırıldığında dbt testleri geçerken cube_match başarısız olmalıdır. Sonra `Set-MetricFault.ps1 -Mode Restore` / `bash set-metric-fault.sh restore` ve Run-Scenario ile doğru formüle dön. Yerel tanım dosyaları değiştirilmez.

## RM5 · OpenMetadata ile ne ekledik?

OpenMetadata 2.0.7, ayrı metadata PostgreSQL’i ve Elasticsearch 9.3.0 yerel Kubernetes üzerinde kurulur. Cube ve iş verisinin PostgreSQL’i ayrı kalır. Metadata PostgreSQL’i ikinci bir iş veri kaynağı değildir; federasyon uygulanmaz. Docker Desktop’a bu stack için yaklaşık 8 GB veya üzeri bellek ayırmak başlangıç önerisidir; gerçek gereksinim diğer açık lab’lara bağlıdır.

Deploy metadata şemasını migrate eder ve katalog kaydını Sync-Catalog ile oluşturur. PostgreSQL pg_catalog alanları ve dbt manifest bağımlılıkları bu lab’ın açık API Job’u tarafından gönderilir. Native Cube/OpenMetadata connector, Airflow, otomatik tarama veya zamanlanmış profiler kurulduğu iddia edilmez.

- Teknik tablo/kolon kataloğu: RM5Postgres.komtas_rm5.raw / dwh.
- Owner: SalesStewards demo ekibi.
- İş sözlüğü: BeverageBusiness.NetGelir / NetHacim / OrtalamaFiyat.
- Metrik kaydı: NetRevenue / NetLiters / AveragePrice; Cube model tanımları beklenen metric-contract.json ile karşılaştırılır.
- Lineage: dbt manifest kaynak/model bağımlılıkları API ile kaydedilir.
- Kalite: gerçek SQL fact row-count testi çalıştırılır, OpenMetadata’ya sonuç yazılır ve geri okunur. 12 dbt veri testi raporda ayrıca değerlendirilir.
- Ürün: BeverageSales domain’i altında BeverageRevenue kaydı görünüm ve metriklere bağlanır. Bu kayıt contract/SLO enforcement veya tam data product yaşam döngüsü değildir.

OpenMetadata iş tanımı ve sahipliği tutar; çalıştırılabilir metrik hesabı Cube’da kalır. Glossary veya ürün kaydı oluşması insan tarafından onaylandığı anlamına gelmez.

## Kataloğu aç

`Connect.ps1` / `bash connect.sh` ile tüneli açık tut; http://127.0.0.1:8585 adresini aç. `Get-Connections.ps1` / `bash get-connections.sh` yerelde üretilmiş giriş bilgilerini gösterir. Kurulum ilk basic admin parolasını rastgele Kubernetes Secret parolasına çevirir. Parola uygulama formuna girilmez.
Elasticsearch ve metadata PostgreSQL’i küme içi destek servisleridir; ayrı kullanıcı ekranları açılmaz.

## Governance hata deneyi

`Inject-GovernanceFault.ps1` / `bash inject-governance-fault.sh` NetRevenue metrik sahibini kaldırır. Veriler ve Cube hesabı değişmez. Run-Scenario yeni raporda om_owner kontrolünü başarısız göstermelidir. `Restore-Governance.ps1` / `bash restore-governance.sh` ile kaydı düzelt; Run-Scenario tekrar çalıştır.
Run-Scenario ownership/glossary kayıtlarını otomatik düzeltmez; Verify-Catalog bunları okur. SQL kalite sonucu her kontrol sırasında güncellenir. Metadata’yı kaynaklardan yeniden yüklemek için Sync-Catalog kullanılır.
Kanıtlar: governance-checks.json ve catalog-lineage-map.json. Bu dosyalar API’den okunan gerçek entity, owner, term, lineage, metrik ve kalite sonucunu içerir; parola veya token içermez.

Metrik eşleşmesi kontrolü, katalogdaki SQL tanımını ve yapılandırılmış Cube model ifadesini beklenen metric-contract.json metinleriyle karşılaştırır. Genel amaçlı SQL anlamsal eşdeğerlik analizi değildir. Runtime hesap sonuçları ayrıca bağımsız sayısal referansa karşı doğrulanır.

Buradaki lineage teknik model bağımlılıklarını gösterir; iş ontolojisi veya Neo4j knowledge graph uygulaması değildir.

## Tek bağlantı oturumu

Kurulumdan sonra Windows `.\Connect.ps1`, Linux `bash connect.sh` bütün yerel servisleri tek terminalden bağlar. İkinci terminalde `.\Get-Connections.ps1` / `bash get-connections.sh` adresleri ve giriş bilgilerini toplu gösterir. Dolu port otomatik değiştirilir; gerçek adres için bu özeti kullanın. Ctrl+C bu oturumun bütün tünellerini kapatır. Ayrıntılar: BAGLANTILAR.md.

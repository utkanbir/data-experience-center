# RM9 — İki PostgreSQL + Trino + dbt Core + Cube + OpenMetadata

Ortak iş sorusu: Ocak–Şubat arasında HoReCa net geliri neden düştü; hacim ve fiyat etkisi nedir, hangi distribütör/ürünler etkilenmiştir?

Satış satırları ilk PostgreSQL’de, tarih/ürün/outlet/promosyon boyutları ikinci PostgreSQL’de bulunur. Aynı tablo iki kaynağa kopyalanmaz. Trino iki catalog arasında SQL yürütür. dbt Core yedi modeli `models.dwh` altında yalnız VIEW olarak kurar. Cube ortak net gelir, net litre ve ağırlıklı ortalama fiyat hesabını Streamlit/Python’a sunar. OpenMetadata tanım/owner, üç servisin metadata’sı, dbt cross-catalog lineage ve gerçek Trino satır sayısı kalite sonucunu kaydeder.

## Kurulum ve deney

Docker Desktop Linux containers, etkin Kubernetes, `kubectl`, `docker-desktop` context’i ve varsayılan StorageClass gerekir. Linux: Bash/OpenSSL. İmaj ve PyPI indirmeleri için internet gerekir; yerel dbt/Python kurulmaz. İki iş PostgreSQL’i, katalog metadata PostgreSQL’i, Elasticsearch ve Trino birlikte bellek tüketir; Docker kaynaklarını kontrol edin.

ZIP’i çıkarın ve `rm9-kubernetes` klasöründe terminal açın:

| İşlem | Windows PowerShell | Linux Bash |
|---|---|---|
| Kur | `.\Deploy.ps1` | `bash deploy.sh` |
| Deneyi çalıştır | `.\Run-Scenario.ps1` | `bash run-scenario.sh` |
| Modelleri yeniden kur | `.\Build-Models.ps1` | `bash build-models.sh` |
| Katalog güncelle | `.\Sync-Catalog.ps1` | `bash sync-catalog.sh` |
| Erişim özeti | `.\Show-Access.ps1` | `bash show-access.sh` |
| Kaynağı boz | `.\Break-Reference.ps1` | `bash break-reference.sh` |
| Kaynağı düzelt | `.\Restore-Reference.ps1` | `bash restore-reference.sh` |
| Kaynakları durdur | `.\Stop.ps1` | `bash stop.sh` |
| Tamamen sil | `.\Remove-Environment.ps1` | `bash remove-environment.sh` |

Her Run-Scenario yeni `reports/run-…` klasörüne `rapor.html`, `sonuc.json` ve `kanitlar/` üretir. HTML’i tarayıcıda açın; JSON’u uygulamadaki deney sonucuna yükleyin. Başarısız kontrol varsa rapor korunur ve script hata kodu döndürür. Önceki aşamadan kalan dosyalar yeni başarı sayılmaz.

PowerShell indirme imzası engelinde paket klasöründe `Get-ChildItem -LiteralPath . -Filter '*.ps1' -File | Unblock-File` çalıştırın. Kurumsal AllSigned politikası varsa imzalı script gerekir. Yönetici açmak tek başına imza sorununu çözmez.

## Erişim

Tek Connect komutu bütün yerel tünelleri açar; bu terminal açık kalmalıdır; tüm tüneller localhost’a bağlanır. Port doluysa ilgili Connect komutuna `-Port` veya Bash komutuna farklı port verin. Docker backend/WSL relay işlemini sonlandırmayın.

| Bileşen | Komut (Windows / Linux) | Varsayılan erişim |
|---|---|---|
| Satış PostgreSQL | Connect.ps1 / connect.sh | 127.0.0.1:15440; komtas_rm9; rm9_bi |
| Referans PostgreSQL | Connect.ps1 / connect.sh | 127.0.0.1:16440; komtas_rm9_reference; rm9_bi |
| Trino | Connect.ps1 / connect.sh | http://127.0.0.1:18099; JDBC jdbc:trino://127.0.0.1:18099/models/dwh; user rm9_reader |
| dbt dokümanı | Connect.ps1 / connect.sh | http://127.0.0.1:18089/static_index.html |
| Cube | Connect.ps1 / connect.sh | http://127.0.0.1:4009/cubejs-api/v1/meta; JWT gerekir |
| Streamlit | Connect.ps1 / connect.sh | http://127.0.0.1:8509 |
| OpenMetadata | Connect.ps1 / connect.sh | http://127.0.0.1:18589 |

PostgreSQL parolası: Get-Connections.ps1 / get-connections.sh (iki iş kaynağında aynı demo Secret). Katalog hesabı: Get-Connections.ps1 / get-connections.sh. Cube kısa ömürlü JWT: Get-ApiToken.ps1 / get-api-token.sh. Parolalar kurulumda yerel Secret olarak üretilir; pakette gerçek kimlik bilgisi yoktur. RM9’da Informatica veya Power BI kurulmaz/istenmez.

## Neyi ölçüyoruz?

29 kontrol + 4 SQL yürütmesi = 33 kontrol. `federation-checks.json` iki ayrı fiziksel system_identifier, kaynak tablo ayrımı, cross-source join, EXPLAIN planı, yedi nesnenin VIEW oluşu ve kaynak rollerinin salt okunur oluşunu kaydeder. `federation-plan.txt` gerçek dağıtık sorgu planıdır. dbt build_results/manifest, Cube SQL ve iki tüketici sonuçları, governance-checks ve katalog lineage eşlemesi ayrı kanıtlardır.

OpenMetadata’da `RM9Trino.models.dwh.v_sales_detail` lineage ekranından `RM9Sales` ve `RM9Reference` tablolarına gidin. Bu açık API Job yüklemesidir; native ingestion connector, Airflow, sürekli profiler veya kaynak tarama otomasyonu kurulmaz. OM metriği hesaplamaz; hesap Cube/Trino’dadır.

## Kaynak bağımlılığı deneyi

Break-Reference yalnız bu namespace’in ikinci PostgreSQL’inde `raw.dim_outlet` tablosunu geçici yeniden adlandırır. Run-Scenario’yu çalıştırın: doğrudan join, dbt/SQL ve cache yenilemeli Cube sorgusu artık başarısız olmalıdır. Rapor hatayı saklar. Restore-Reference ardından Run-Scenario’yu tekrar çalıştırın; modeller yeniden kurulur. Bu hata deneyi kullanıcıya ait başka ortamı kapatmaz.

## Sınırlar

Trino 484, PostgreSQL 17.11, dbt Core 1.9.10/dbt-trino 1.9.3, Cube 1.6.77, OpenMetadata 1.12.3 kullanılır. Trino `models` memory connector yalnız VIEW metadata’sı tutar; yeniden başlatınca kaybolur, Build-Models gerekir. Kalıcı merkezi iş verisi kopyası yoktur; sorgu sırasında veri ağdan taşınır. Performans, maliyet, pushdown verimi, HA, üretim TLS/auth/RLS ve kurumsal onay bu deneyle kanıtlanmaz. Trino kimlik doğrulamasız HTTP yalnız izole yerel deney içindir. Katalog sahipliği insan onayı değildir; data product kaydı SLO/contract enforcement değildir. Tasarım kapsam notu 53,3/100, çalışma başarısı 33 kontrolle ayrı ölçülür.

## Ürün belgeleri

- https://trino.io/docs/current/connector/postgresql.html
- https://trino.io/docs/current/connector/memory.html
- https://docs.getdbt.com/docs/local/connect-data-platform/trino-setup
- https://docs.cube.dev/admin/connect-to-data/data-sources/trino

Cube deneyinde her yenilemede UUID üreten refreshKey kullanılır ve renewQuery aktiftir. Amaç cache arkasında kaynak hatasını gizlememektir; bu profil cache performansını ölçmez.

## Tek bağlantı oturumu

Kurulumdan sonra Windows `.\Connect.ps1`, Linux `bash connect.sh` bütün yerel servisleri tek terminalden bağlar. İkinci terminalde `.\Get-Connections.ps1` / `bash get-connections.sh` adresleri ve giriş bilgilerini toplu gösterir. Dolu port otomatik değiştirilir; gerçek adres için bu özeti kullanın. Ctrl+C bu oturumun bütün tünellerini kapatır. Ayrıntılar: BAGLANTILAR.md.

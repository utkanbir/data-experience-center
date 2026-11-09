# RM9 deney ve rapor

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

# Referans Mimari 6 · Yönetilen dbt Semantic Layer + PostgreSQL

Ortak soru: HoReCa geliri Ocak 2025’ten Şubat 2025’e neden düştü; hacim ve fiyat etkisi ne kadar?
Yerel hazırlık: PostgreSQL raw → dbt Core modelleri / semantic_manifest → PostgreSQL dwh.
Harici hedef: dbt deployment environment + yönetilen Semantic API → Python / Power BI.

## Nerede çalışır?

Docker Desktop Kubernetes: PostgreSQL, dbt Core 1.10.15 + dbt-postgres 1.9.1 Job, yerel doküman servisi, Python GraphQL istemci Job’u.
Harici sağlanacaklar: uygun dbt hesabı/planı, başarılı deployment environment run’ı, Semantic Layer credential/token, bu servisin PostgreSQL’e güvenli erişimi; Power BI Desktop ve resmi dbt connector/ODBC sürücüsü.
Power BI entegrasyonu resmî dokümanda preview’dur. Power BI Service için özel connector/gateway koşulları ayrıca kontrol edilmelidir. Managed servis Docker’da kurulmaz. Yerel Core veya MetricFlow onun yerine geçirilmez.

## Yerel kurulum ve rapor

ZIP’i çıkar, rm6-kubernetes içinde terminal aç. Docker Desktop Linux containers, Kubernetes docker-desktop context, varsayılan StorageClass ve kubectl gerekli.
Windows: `Deploy.ps1`, ardından `Run-Scenario.ps1`. İndirme engeli için yalnız paket scriptlerinde `Get-ChildItem -LiteralPath . -Filter '*.ps1' -File | Unblock-File`.
Linux: `bash deploy.sh`, ardından `bash run-scenario.sh`; Bash/OpenSSL gerekli.
Token verilmediyse yerel bölüm çalışır ve harici 5 kontrol not_tested kalır. Bu kısmi koşum hata sayılmaz, tam başarı sayılmaz. Tam doğrulama şartı için `Run-Scenario.ps1 -RequireComplete` / `bash run-scenario.sh --require-complete` kullan.
reports/run-.../rapor.html dosyasını aç; sonuc.json dosyasını uygulamaya yükle. Yerel SQL metrikleri ile harici API kanıtları ayrı değerlendirilir.

## Harici hesabı hazırlama

1. dbt hesabında Semantic Layer kullanılabilen plan/environment oluştur. Platformdaki desteklenen v1 release/model uyumunu kontrol et; yerel model formatı dbt Core 1.10.15 ile doğrulanır. Gerçek platform release uyumu dış test gerektirir.
2. cloud-project klasörünü kendi dbt proje repository’sine al. Cloud bağlantısının hedef PostgreSQL database/schema bilgisini yapılandır; üretim hedef schema dwh olmalı, raw kaynak tabloları aynı demo verisini içermeli.
3. Yerel 127.0.0.1 veya kubectl port-forward dışarıdaki dbt servisine erişim vermez. Paket firewall, NodePort, LoadBalancer veya halka açık veritabanı açmaz. Kurumun onaylı ağ erişim yolunu kullan veya dbt tarafından erişilebilir ayrılmış bir demo PostgreSQL sağla.
4. İstersen Export-Demo.ps1 / bash export-demo.sh ile yalnız sentetik raw şemasını cloud-transfer/demo.sql olarak çıkar. Script dış sisteme aktarım yapmaz. Bu SQL’i yalnız ayrılmış lab hedefinde DBA’nızla yükleyin; aynı hedef üzerinde cloud dbt build çalıştırın. DB bağlantı parolası dbt platformunda sağlanır.
5. Başarılı deployment run ve Semantic Layer credential/token bağlantısını tamamla. Üç metrik net_revenue, net_liters, average_price görünmeli. GraphQL host ve Environment ID’yi proje bağlantı detaylarından al.

## Bağlantı ve gerçek API testi

Tokeni web uygulamasına, environment.json’a veya ZIP’e yazma. Windows: Set-DbtConnection.ps1 host/environment bilgilerini settings.json’dan alır veya sorar; tokeni gizli sorar. Linux: bash set-dbt-connection.sh host environmentId; argüman yoksa bilgiler sorulur. Token yalnız yerel Kubernetes Secret rm6-dbt-service içine yazılır.
Run-RemoteChecks.ps1 / bash run-remote-checks.sh gerçek yönetilen API’de metrik keşfi, createQuery/poll, SQL ve sayısal referans kontrollerini yürütür. Kimlik doğrulama hatası veya yanlış ortam failed; eksik bağlantı not_tested olarak raporlanır. API host’u resmî dbt Semantic Layer host’u ve HTTPS olmalı; redirect izlenmez.
Sonra Run-Scenario ile bütün raporu üret. Harici tokeni kaldırmak için Clear-DbtConnection.ps1 / bash clear-dbt-connection.sh kullan. Script dış dbt hesabını/tokenini iptal etmez.

## Erişim

PostgreSQL: Connect.ps1 / bash connect.sh → 127.0.0.1:15437, komtas_rm6, rm6_bi. Parola Get-Connection ile alınır.
dbt docs: Connect-Docs.ps1 / bash connect-docs.sh → http://127.0.0.1:18086/static_index.html; tünel açık kalmalı.
Yönetilen servis web ekranı ve Semantic API dbt hesabından sağlanır. Python istemcisi Kubernetes Job’unda çalışır; yerel Python gerekmez. Bütün bağlantı özeti Show-Access ile yeniden gösterilir.

## Power BI kanıtı

Power BI PostgreSQL connector’ı yönetilen Semantic Layer tüketimi yerine geçmez. Resmi dbt Semantic Layer connector ve ODBC sürücüsünü üretici dokümanına göre kur. Host, Environment ID ve tokenle aynı environment’a bağlan. Üç metriği ay/kanal kırılımında getir; formülü Power BI’da yeniden yazma.
6 satırı CSV olarak dışa aktar. Kolon adları: month,channel,net_revenue,net_liters,average_price; ondalık ayıracı nokta. Import-PowerBIResult.ps1 -Path result.csv / bash import-powerbi-result.sh result.csv ile kaydet. Sonraki Run-Scenario CSV’yi gerçek API ve bağımsız referansla karşılaştırır.
Bu kullanıcı kaynaklı manuel kanıttır; script Power BI connector’ını otomatik çalıştırdığını veya CSV’nin kaynağını bağımsız doğruladığını iddia etmez. PBIX, Power BI Desktop, connector veya gateway pakete dahil değildir.

## Beklenen sonuç ve kapsam

HoReCa 8164.80 → 3628.80 EUR, fark −4536 EUR. Net litre 1844.64 → 819.84; ağırlıklı fiyat değişmez. Bu sentetik veri hacim etkisini gösterir; ticari kök nedeni kanıtlamaz.
17 kontrol + 4 SQL yürütme kaydı: 12 yerel kontrol ve 5 harici/tüketici kontrolü. Yerel-only koşumda toplam 16 geçti / 5 denenmedi beklenir. Tasarım kapsam notu 23.3/100 olarak kalır.
Kanıtlar: dbt manifest/build_results/static_index/semantic_manifest; managed-checks.json; gerçek sorgu çalıştıysa managed-results.json ve managed-sql.txt; kullanıcı CSV verdi ve API çalıştıysa powerbi-results.json. Placeholder veya yerel hesaplar harici kanıt olarak kullanılmaz.
Governance, data product yaşam döngüsü, federasyon, ontology ve Agent360 yoktur. Semantic model yerelde derlenmiş olması yönetilen servis veya iki tüketicinin doğrulandığı anlamına gelmez.

## Durdurma ve silme

Stop.ps1 / bash stop.sh yerel PostgreSQL ve dbt docs servisini durdurur; PVC/Secret korunur.
Remove-Environment.ps1 / bash remove-environment.sh lab sahiplik etiketi ve namespace adını yazarak onaydan sonra yalnız yerel lab namespace’ini siler. Harici dbt hesabı, environment, token, PostgreSQL ve Power BI kaynakları silinmez. Onların yaşam döngüsünü ayrı yönet.

Resmî kaynaklar: https://docs.getdbt.com/docs/use-dbt-semantic-layer/setup-sl · https://docs.getdbt.com/docs/dbt-apis/sl-graphql · https://docs.getdbt.com/docs/platform-integrations/semantic-layer/power-bi

## Ekrandan tanımlanan dış bağlantı

Kurulum paketini hazırla ekranında dış servisi seçip host/kimlik ve isteğe bağlı eşlemeleri doldurabilirsin. Bilgiler external-connections.json ve servisin settings.json dosyasına aktarılır; DIS_SERVISLER.md akışı açıklar. “Kurulumda bağlan” seçildiyse Deploy namespace oluşturulduktan sonra token’ı yerelde gizli olarak ister. Aynı host/kimliğe ait Secret varsa yeniden istemez; farklı bağlantı varsa sessizce değiştirmek yerine durur ve Set bağlantı scriptini kullanmanı ister. Token süresi dolmuşsa Set scriptiyle yenile. “Şimdilik yerel bileşenleri dene” seçimi dış servis adımını atlar; eksik kontroller denenmedi kalır. Bağlantı formu erişim testi veya dış hesabın kurulması değildir.

Yerel-only seçiminde connection-mode.txt işareti, daha önce var olan Secret olsa bile dış API kullanımını engeller. Daha sonra Set bağlantı scriptini bilerek çalıştırmak bu işareti connect yapar; Run kontrolleri ConfigMap’i yenileyerek yeni modu kullanır. Formdan yeni paket üretmek seçilen modu tekrar uygular.

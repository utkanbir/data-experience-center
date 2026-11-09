# Referans Mimari 2 · PostgreSQL + dbt Core + Power BI

Aynı içecek dağıtımı senaryosu, 2 ülke, 3 kanal, 2.016 satış satırı. PostgreSQL kaynak veriyi saklar; dbt staging ve yıldız modeli üretir, null/tekillik/ilişki ve referans gelir testlerini çalıştırır. Model bağımlılık grafiği dbt dokümanında gösterilir. Merkezi semantic servis veya governance sağlanmaz. Power BI Windows'ta ayrıca kurulur; PBIX dahil değildir.

## Kurulum

Docker Desktop Linux containers ve Kubernetes açık, docker-desktop context'i, kubectl ve varsayılan StorageClass gerekli. Linux'ta Bash/OpenSSL/base64 gerekli. İlk dbt Job'unda PyPI internet erişimi gerekir: dbt-core 1.9.10, dbt-postgres 1.9.1 yüklenir. Job süresi 20 dakikayla sınırlıdır. Yerel Python/dbt kurulmaz. PostgreSQL ve dbt artifacts için toplam 3 GiB PVC istenir.

ZIP'i çıkarıp rm2-kubernetes klasöründe terminal açın. Windows: `.\Deploy.ps1`; Linux: `bash deploy.sh`. Sonra Windows: `.\Run-Scenario.ps1`; Linux: `bash run-scenario.sh`.
İmza engelinde paket klasöründe `Get-ChildItem -LiteralPath . -Filter '*.ps1' -File | Unblock-File` çalıştırın. Kurumsal AllSigned politikasını değiştirmeyin; imzalı script gerekir.

Varsayılan namespace komtas-rm2, port 15433; RM1'den bağımsızdır. İlk kurulum üç rastgele parola üretir: admin, dbt dönüşüm rolü ve BI salt okuma rolü. dbt kaynağı okur ve dwh içinde model oluşturur. Web formuna parola girilmez.

## Deney ve rapor

Run-Scenario dbt Job'unu yeniden çalıştırır, iş sorgularını ve referans kontrollerini yürütür. reports/run-… altında rapor.html, sonuc.json ve kanitlar oluşur. HTML'i tarayıcıda açın. JSON'u uygulamadaki Ortak iş senaryosu veya RM2 Senaryo & deney bölümüne yükleyin. Kanıtlarda build_results.json, manifest.json, catalog.json, dbt-checks.json ve static_index.html bulunur. static_index.html çevrimdışı dbt dokümanı ve model bağımlılık grafiğidir. Model testleri geçmeden tüm mimari doğrulanmış sayılmaz. Power BI ayrıca test edilmelidir. Hata halinde rapor üretimi devam eder, başarısızlıklar işaretlenir. Bağlantı yoksa ölçülemeyen kontroller denenmedi kalır.

HoReCa gelirleri Ocak 8164.80 EUR, Şubat 3628.80 EUR; fark −4536 EUR. Net litre 1844.640 → 819.840; ortalama fiyat değişmez. Sorgular sql klasöründe. Promosyon ilişkisi nedensellik kanıtı değildir.

## İsteğe bağlı hata deneyi

Windows: `.\Set-DemoFault.ps1 -Mode Inject`; Linux: `bash set-demo-fault.sh inject`. Bir sentetik kaynak satırının ürün anahtarı geçersiz yapılır. Run-Scenario çalıştırın; dbt ilişki testi başarısız olmalı, hata raporda görünmeli. Başarısız build bazı alt modelleri atlayabilir; eski ambar tablosu duruyor olsa bile dbt testi başarısız kalır.
Düzeltmek için Windows: `.\Set-DemoFault.ps1 -Mode Restore`; Linux: `bash set-demo-fault.sh restore`. Sonra Run-Scenario tekrar çalıştırın. Bu demo yalnız bu paketin sentetik verisi içindir.

## Bağlantı ve yaşam döngüsü

Windows `.\Connect.ps1`, diğer terminalde `.\Get-Connections.ps1`; Linux `bash connect.sh`, diğer terminalde `bash get-connections.sh`. Kullanıcı rm2_bi, DB komtas_rm2. Tünel açık kalmalı.
Stop.ps1 / stop.sh PostgreSQL'i durdurur, veri kalır. Remove-Environment.ps1 / remove-environment.sh namespace, tüm PVC'ler ve Secret'ları kaldırır; sahiplik etiketi ve yazılı namespace onayı ister. Önce yedek alın. Diskin fiziksel temizliği StorageClass reclaim politikasına bağlıdır.

Kaynaklar: https://docs.getdbt.com/docs/local/connect-data-platform/postgres-setup ve https://docs.getdbt.com/docs/build/data-tests

## Kurulan bilesenlere erisim

Deploy sonunda erisim rehberi goruntulenir. Tekrar acmak icin Windows `.\Show-Access.ps1`, Linux `bash show-access.sh`. PostgreSQL'e baglanmak icin Connect tunelini baslatin; kullanici/parola Get-Connection ile yerelde gorulur. SQL istemcisinde sunucu 127.0.0.1, port 15433, DB komtas_rm2, kullanici rm2_bi. Power BI Desktop Windows'ta ayrica kurulur: Veri al > PostgreSQL veritabani > sunucu 127.0.0.1:15433, DB komtas_rm2, Veritabani kimlik dogrulama.

dbt Core bir CLI/Job'dur, yonetim web arayuzu yoktur. Dokumani ve model bagimlilik grafigini acmak icin Windows `.\Connect.ps1`, Linux `bash connect.sh`; sonra http://127.0.0.1:18082/static_index.html (varsayilan port). Tünel terminali acik kalmali. Dokuman dbt Job tamamlaninca hazir olur. Yerel rapordaki kanitlar/static_index.html dosyasi da acilabilir. Build-Models ile yeniden uretilebilir.

## Tek bağlantı oturumu

Kurulumdan sonra Windows `.\Connect.ps1`, Linux `bash connect.sh` bütün yerel servisleri tek terminalden bağlar. İkinci terminalde `.\Get-Connections.ps1` / `bash get-connections.sh` adresleri ve giriş bilgilerini toplu gösterir. Dolu port otomatik değiştirilir; gerçek adres için bu özeti kullanın. Ctrl+C bu oturumun bütün tünellerini kapatır. Ayrıntılar: BAGLANTILAR.md.

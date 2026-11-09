# Referans Mimari 3 · PostgreSQL + dbt Core + yerel MetricFlow

## Bu mimari neyi değiştiriyor?

Aynı içecek dağıtımı senaryosu ve aynı veri kullanılır. RM2'nin kodla modelleme/test katmanına BI'dan bağımsız metrik tanımı eklenir. Net Revenue, Net Liters ve Average Price dbt/models/metrics.yml içinde tanımlıdır. Average Price, toplam gelirin toplam net litreye oranıdır; satır fiyatlarının ortalaması değildir.

Data360 katkısı: PostgreSQL, dbt modelleri ve veri testleri. Business360 katkısı: yerel semantic metrik tanımı, üretilen SQL ve referans eşleşmesi. Merkezi glossary/owner/onay, kurumsal governance, ontology ve Agent360 bu mimaride yoktur. S2 kısmi kapsamdır: yerel motor, hazır online ortak metric API değildir. Power BI bu profilin bileşeni değildir; hazır connector kurulmaz.

## Kurulum ve erişim

Docker Desktop Linux containers + Kubernetes, docker-desktop context, kubectl ve varsayılan StorageClass gerekir. Linux'ta Bash/OpenSSL/base64 gerekir. PostgreSQL 2 GiB ve dbt artifacts 1 GiB PVC kullanılır. Python/dbt/MetricFlow yerel makinaya kurulmaz; Job içinde yüklenir. PyPI internet erişimi gerekir. Sabit sürümler: dbt-core 1.10.15, dbt-postgres 1.9.1, dbt-metricflow 0.11.0, MetricFlow 0.209.0. Motorun seçilen sürümü Apache 2.0 lisanslıdır; ücretli yönetilen dbt Semantic servisi kullanılmaz. Paket sürümlerini birlikte doğrulamadan yükseltmeyin.

ZIP'i çıkar, rm3-kubernetes klasöründe terminal aç. Windows `.\Deploy.ps1`, sonra `.\Run-Scenario.ps1`; Linux `bash deploy.sh`, sonra `bash run-scenario.sh`. Windows imza engelinde `Get-ChildItem -LiteralPath . -Filter '*.ps1' -File | Unblock-File`. AllSigned kurumsal politikası için imzalı script gerekir.

Varsayılan namespace komtas-rm3, PostgreSQL yerel portu 15434. Connect.ps1 / connect.sh tüneli açıkken Get-Connections.ps1 / get-connections.sh ile BI salt okuma bağlantısını al. Web formunda parola yok; yerelde üç rastgele parola üretilir. Deploy sonunda Show-Access rehberi yazılır.

MetricFlow çıktıları: `.\Show-Metrics.ps1` / `bash show-metrics.sh`. Yeniden model ve metrik hesabı: `.\Run-Metrics.ps1` / `bash run-metrics.sh`. Bunlar yerel CLI motorunu Kubernetes Job'unda çalıştırır; web API değildir. Çalışan sorgu: `mf query --metrics net_revenue,net_liters,average_price --group-by metric_time__month,sales_line__channel`. `--explain` SQL'i, `--csv` sonuç dosyasını üretir.

Doküman/model grafiği: Connect.ps1 / connect.sh tünelini ayrı terminalde açık tut, sonra http://127.0.0.1:18083/static_index.html (varsayılan port). Tünel kapalıyken link çalışmaz. Yerel raporun kanitlar/static_index.html dosyası da açılabilir.

## Senaryo ve kanıt raporu

HoReCa net gelir Ocak 8164.80, Şubat 3628.80 EUR; net litre 1844.640 → 819.840. İki ay, üç kanal için altı metrik satırı SQL referansıyla karşılaştırılır. Karşılaştırma toleransı 0.0001'dir. Üretilen SQL, CSV/JSON, semantic_manifest ve dbt çıktı dosyaları kanitlar içinde saklanır.

Run-Scenario her çalıştırmada reports/run-… altında rapor.html, sonuc.json ve kanitlar üretir. HTML'i aç, sonuc.json dosyasını uygulamada RM3 Senaryo & deney bölümüne yükle. Metrik sorgusu, SQL üretimi ve referans eşleşmesi üç ayrı kontroldür. Metrik tanımının doğru hesaplanması kurumsal owner/onay kanıtı değildir.

## Semantik hata deneyi

Windows `.\Set-MetricFault.ps1 -Mode Inject`; Linux `bash set-metric-fault.sh inject`. Yalnız yerel metrik tanımı ConfigMap içinde brüt gelire çevrilir; ambar modeli ve SQL referansı değişmez. Run-Scenario çalıştır: sorgu ve SQL üretimi çalışabilir ama mf_match başarısız olmalıdır. Bu, teknik olarak çalışan bir sorgunun yanlış iş tanımını hesaplayabileceğini gösterir.

Düzelt: `.\Set-MetricFault.ps1 -Mode Restore` / `bash set-metric-fault.sh restore`; Run-Scenario tekrar çalıştır. Yerel metrik dosyası değiştirilmez. Yeni Deploy, paketin doğru tanımını tekrar uygular.

İsteğe bağlı veri ilişki hatası RM2'deki gibi Set-DemoFault -Mode Inject/Restore veya set-demo-fault.sh inject/restore ile denenebilir.

## Durdur ve kaldır

Stop.ps1 / stop.sh PostgreSQL'i durdurur, veri korunur. Remove-Environment.ps1 / remove-environment.sh lab namespace, PVC, Secret ve docs servisini kaldırır; sahiplik etiketi ve yazılı namespace onayı ister. Önce yedek al. Fiziksel temizlik StorageClass reclaim politikasına bağlıdır.

Kaynaklar: https://docs.getdbt.com/docs/build/metricflow-commands ve https://github.com/dbt-labs/metricflow (lisans geçmişi).

## Tek bağlantı oturumu

Kurulumdan sonra Windows `.\Connect.ps1`, Linux `bash connect.sh` bütün yerel servisleri tek terminalden bağlar. İkinci terminalde `.\Get-Connections.ps1` / `bash get-connections.sh` adresleri ve giriş bilgilerini toplu gösterir. Dolu port otomatik değiştirilir; gerçek adres için bu özeti kullanın. Ctrl+C bu oturumun bütün tünellerini kapatır. Ayrıntılar: BAGLANTILAR.md.

# Referans Mimari 7 — Cube Core + Informatica CDGC

Yerel PostgreSQL → dbt Core → Cube Core/Store → Streamlit ve Python aynı metrikleri kullanır. Informatica Data Governance and Catalog (CDGC) dışarıdan sağlanır. CDGC, Cloud Data Quality, Marketplace veya Secure Agent konteyneri kurulmaz. Power BI bu mimaride yoktur.

## Kur ve deneyimle

Docker Desktop Kubernetes açık ve kubectl context docker-desktop olmalı. ZIP'i çıkar, rm7-kubernetes klasöründe terminal aç.

Windows: `./Deploy.ps1`, ardından `./Run-Scenario.ps1`.
Linux: `bash deploy.sh`, ardından `bash run-scenario.sh`.

İmza hatası varsa yalnız indirdiğin paket scriptlerini aç: `Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File`. Kurumsal execution policy ayrıca engelliyorsa kurum politikasını izle.

Her deney reports/run-* içinde rapor.html, sonuc.json ve kanitlar üretir. HTML'i aç; JSON'u uygulamada Deney sonucunu yükle alanına aktar. Yerel başarı halinde 20 kontrol geçer; CDGC kimliği/eşlemesi yokken 7 kontrol denenmedi kalır. Bu dış governance başarısı değildir. Tam kanıt zorunluluğu: `./Run-Scenario.ps1 -RequireComplete` / `bash run-scenario.sh --require-complete`.

## Dış governance bağlantısı

1. Kendi Informatica org'unu, CDGC lisansını ve varlık okuma yetkisini sağla. Üç gerçek iş terimini seç veya kurum sürecinle oluştur: Net Revenue (discounts, returns, EUR), Net Liters (net volume, liters), Average Price (Net Revenue / Net Liters, EUR/liter). Paket dış org'da varlık oluşturmaz/değiştirmez.
2. governance/settings.json içindeki üç internal assetId'yi doldur. expectedName ve descriptionContains gerçek iş tanımını sınar; tam anlamsal eşdeğerlik kanıtlamaz. owner.expectedId ve expectedRoleId gir; idPointer/rolePointer alanlarını org'un gerçek API yanıtındaki JSON yollarıyla doğrula. Varsayılan sahiplik yolları org şemasına göre değiştirilmelidir.
3. `./Set-InformaticaConnection.ps1` / `bash set-informatica-connection.sh`: resmi idmc-api pod hostu (URL yolu olmadan), Org ID ve gizli JWT ister. Token web uygulamasına, ZIP'e veya rapora yazılmaz; yalnız yerel Kubernetes Secret rm7-informatica içinde saklanır. Süresi dolunca yenile. `Clear-InformaticaConnection.ps1` / `bash clear-informatica-connection.sh` yalnız yerel Secret'ı siler; dış token'ı iptal etmez.
4. İsteğe bağlı technical.assetId ve expectedExternalId ile gerçek teknik varlığı eşle. Üç iş terimine ACCEPTED glossary bağlantıları aranır; yerel Cube SQL view'u ve metrik kimlikleri kontrol edilir. Bu beyan edilen eşlemedir; otomatik kaynak taraması veya uçtan uca lineage doğrulaması değildir. Harici tarayıcının yerel PostgreSQL'e erişimi onaylı agent/ağ tasarımı ister; 127.0.0.1 port-forward dış servis erişimi sağlamaz.
5. Ürün kaydı için product.assetId, expectedName ve expectedClass gerçek org kaydından girilir. Kayıt kontrolü Marketplace veya erişim enforcement kanıtı değildir.
6. Run-Scenario'yu tekrar çalıştır. Sadece governance denemesi: Run-Governance.ps1 / bash run-governance.sh. Bu komut settings.json değişikliklerini ConfigMap'e yeniden aktarır.

## Yayın ve onay ayrımı

Published yalnız yaşam döngüsü durumudur, insan onayı kanıtı değildir. Gerçek varlık sürümlerinden kanitlar/cdgc-approval-template.json üretilir. Yalnız gerçek workflow kaydından decision=approved, ticketId, reviewer ve observedAt (ISO tarih + timezone) doldur. `./Import-GovernanceApproval.ps1 -Path <dosya>` / `bash import-governance-approval.sh <dosya>` ile aktar ve Run-Scenario'yu tekrar çalıştır. Üç benzersiz varlık, son değiştirilme sürümü ve tarih tutarlılığı sınanır. Bu manuel kanıttır; onaylayanın yetkisi ve workflow yürütümü bağımsız doğrulanmaz. Eski sürüm kaydı başarısız olur.

## Bileşenlere erişim

Deploy sonunda Show-Access çıktısı erişimi özetler. Tünel terminalini açık tut:

| Bileşen | Windows / Linux | Adres |
|---|---|---|
| PostgreSQL | Connect.ps1 / bash connect.sh | 127.0.0.1:15438, DB komtas_rm7, user rm7_bi |
| dbt dokümanı | Connect.ps1 / bash connect.sh | http://127.0.0.1:18087/static_index.html |
| Streamlit | Connect.ps1 / bash connect.sh | http://127.0.0.1:8507 |
| Cube API | Connect.ps1 / bash connect.sh | http://127.0.0.1:4007/cubejs-api/v1/meta |
| Python | Query-Metrics.ps1 / bash query-metrics.sh | Kubernetes istemcisi |
| CDGC | Kendi org portalın | Dış hesap; API hostu UI adresi değildir |

SQL parolası Get-Connections.ps1 / bash get-connections.sh ile alınır. Cube için Get-ApiToken.ps1 / bash get-api-token.sh kısa süreli token üretir; Authorization başlığı gerekir. dbt Core ayrı yönetim ekranı sunmaz. Cube Store yalnız küme içi destek servisidir.

## Neyi çözer, neyi çözmez?

Ortak executable metrik hesabı iki bağımsız tüketicide çalışır. Dış CDGC varsa iş tanımı, sahiplik, yayın durumu ve beyan edilen teknik bağlantı ayrıca sınanır. Doğru hesap eksik governance'ı kapatmaz. Contract/SLO enforcement, gerçek otomatik tarama, sürekli observability, federasyon, ontology/knowledge graph ve agent bu pakette yoktur. Tasarım karne notu ile deney kontrol başarısı farklı ölçülerdir.

Hata deneyi için settings.json içinde beklenen owner/role veya tanımı yanlış girip tekrar çalıştır; başarısızlık görünür olmalı. Gerçek org kayıtlarını değiştirmene gerek yok. Yerel metrik hatası Set-MetricFault.ps1 / set-metric-fault.sh ile sınanabilir.

## Durdur / sil

Stop.ps1 / bash stop.sh yerel servisleri durdurur. Remove-Environment.ps1 / bash remove-environment.sh namespace adını yazarak onay ister ve yalnız o lab namespace'ini verileri/Secret'larıyla kaldırır. Önce rapor ve gerekiyorsa veriyi yedekle. Dış Informatica org'una veya varlıklarına dokunmaz.

## API kaynağı

- https://docs.informatica.com/data-governance-and-quality-cloud/data-governance-and-catalog/current-version/api-reference/introduction/authentication.html
- https://docs.informatica.com/data-governance-and-quality-cloud/data-governance-and-catalog/current-version/api-reference/search-for-assets/retrieve-details-of-multiple-assets/example-request.html

İstemci yalnız `POST /data360/search/v1/assets/details?scheme=internal&segments=all` okuma uç noktasını çağırır; Bearer JWT ve X-INFA-ORG-ID kullanır. Yönlendirme takip etmez. Dış hesap olmadan gerçek API doğrulanmış sayılmaz.

## Ekrandan tanımlanan dış bağlantı

Kurulum paketini hazırla ekranında dış servisi seçip host/kimlik ve isteğe bağlı eşlemeleri doldurabilirsin. Bilgiler external-connections.json ve servisin settings.json dosyasına aktarılır; DIS_SERVISLER.md akışı açıklar. “Kurulumda bağlan” seçildiyse Deploy namespace oluşturulduktan sonra token’ı yerelde gizli olarak ister. Aynı host/kimliğe ait Secret varsa yeniden istemez; farklı bağlantı varsa sessizce değiştirmek yerine durur ve Set bağlantı scriptini kullanmanı ister. Token süresi dolmuşsa Set scriptiyle yenile. “Şimdilik yerel bileşenleri dene” seçimi dış servis adımını atlar; eksik kontroller denenmedi kalır. Bağlantı formu erişim testi veya dış hesabın kurulması değildir.

Yerel-only seçiminde connection-mode.txt işareti, daha önce var olan Secret olsa bile dış API kullanımını engeller. Daha sonra Set bağlantı scriptini bilerek çalıştırmak bu işareti connect yapar; Run kontrolleri ConfigMap’i yenileyerek yeni modu kullanır. Formdan yeni paket üretmek seçilen modu tekrar uygular.

## Tek bağlantı oturumu

Kurulumdan sonra Windows `.\Connect.ps1`, Linux `bash connect.sh` bütün yerel servisleri tek terminalden bağlar. İkinci terminalde `.\Get-Connections.ps1` / `bash get-connections.sh` adresleri ve giriş bilgilerini toplu gösterir. Dolu port otomatik değiştirilir; gerçek adres için bu özeti kullanın. Ctrl+C bu oturumun bütün tünellerini kapatır. Ayrıntılar: BAGLANTILAR.md.

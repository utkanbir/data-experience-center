# Referans Mimari 8 — CDGC + OpenMetadata

## Ortak iş senaryosu

İçecek dağıtımında Ocak–Şubat kanal bazlı net gelir, net litre ve ağırlıklı ortalama fiyatı aynı hesap tanımıyla dashboard ve Python'da göster; hesabı iş tanımı, owner ve teknik güven kanıtıyla ilişkilendir. İki katalog kurulması tek başına bu ilişkiyi kanıtlamaz.

| Görev | Asıl kaynak | RM8'de somut kazanım |
|---|---|---|
| İş tanımı ve kurumsal owner/rol | Harici Informatica CDGC | Gerçek org varlıkları API ile okunur; yayın ve manuel onay kaydı ayrı kontrol edilir |
| Teknik tablolar, dbt lineage, SQL kalite sonucu | Yerel OpenMetadata | Teknik görünüm, sahiplik, metrik SQL bağlantısı ve test sonucu yerelde gözlenir |
| Metrik hesabı | Cube Core | Streamlit ve Python aynı REST metriğini kullanır |
| Kataloglar arası bağ | Açık bridge/settings.json ve gerçek kaynak sürümü | Kimlik, tanım, beyan edilen owner eşlemesi ve son aktarım sürümü karşılaştırılır |

Bu, Informatica'nın genel ürün yeteneklerinin eksik olduğu iddiası değildir. RM7'de dahil edilmeyen yerel teknik metadata/lineage/SQL kalite işini RM8 OpenMetadata ile gösterir. Aynı iş için ikinci katalog yalnız tekrar üretirse ek fayda sayılmaz. Kurumsal tanımı ve yerel teknik kanıtı birlikte görme karşılığında kimlik/sürüm eşlemesi ve iki sistemin işletim yükü eklenir.

## Kurulum ve ilk deney

Docker Desktop Linux containers, Kubernetes, kubectl docker-desktop context ve varsayılan StorageClass gerekli. Yerel stack PostgreSQL, dbt Core, Cube/Store, Streamlit/Python, OpenMetadata, ayrı metadata PostgreSQL ve Elasticsearch içerir. İmaj indirme ve PyPI erişimi gerekir. CDGC, Cloud Data Quality, Marketplace ve Secure Agent kurulmaz. Power BI bu mimaride yoktur. Metadata PostgreSQL ikinci iş veri kaynağı değildir; federasyon yoktur.

ZIP'i çıkar, rm8-kubernetes klasöründe terminal aç.

Windows: `./Deploy.ps1`, ardından `./Run-Scenario.ps1`.
Linux: `bash deploy.sh`, ardından `bash run-scenario.sh`.

İmza hatası varsa yalnız bu paket scriptlerini aç: `Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File`. Kurumsal execution policy ayrıca engelliyorsa kurum politikasını izle.

Başarılı yerel deneyde **38 kontrolden 27 geçer, 11 denenmedi kalır**: 7 CDGC + 4 çift katalog kontrolü dış erişim/eşleme bekler. Doğru metrik ve yerel katalog, harici governance kanıtı değildir. `reports/run-*` içinde rapor.html ve sonuc.json üretilir; HTML'i aç, JSON'u uygulamaya yükle. kanitlar/ gerçek SQL, dbt, Cube, governance ve dual-checks.json kayıtlarını içerir.

`./Run-Scenario.ps1 -RequireComplete` / `bash run-scenario.sh --require-complete` eksik kanıt varsa raporu üretip hata verir. Herhangi bir başarısız kontrol normal modda da hata üretir. Job'un tamamlanması kontrol başarısı değildir.

## Gerçek CDGC erişimi ve kimlik eşlemesi

1. cdgc/settings.json içinde üç gerçek metrik internal assetId'si, expectedName ve descriptionContains değerlerini gir. owner.expectedId / expectedRoleId ve gerçek org yanıtına göre idPointer / rolePointer alanlarını doğrula. Teknik varlık ve product alanları RM7'deki gibi isteğe bağlıdır; doldurulmazsa ilgili kanıtlar denenmedi kalır.
2. bridge/settings.json üç Cube metricId'sini yerel OM metrik ve terim FQN'lerine bağlar. ownerTeam yerel ekip adıdır. Bu, kullanıcı tarafından beyan edilmiş kimlik eşlemesidir; otomatik kurumsal kişi/rol çözümleme değildir.
3. `./Set-InformaticaConnection.ps1` / `bash set-informatica-connection.sh` ile resmi idmc-api pod hostu, Org ID ve JWT'yi yerelde sağla. Token web uygulamasına veya ZIP'e girilmez; rm8-informatica Kubernetes Secret içinde kalır. Süresi dolunca yenile. Clear-InformaticaConnection yalnız yerel Secret'ı siler; dış token'ı iptal etmez.
4. İş tanımı ve owner eşlemesini gözden geçirdikten sonra `./Sync-BusinessDefinitions.ps1` / `bash sync-business-definitions.sh` çalıştır. CDGC'den gerçek tanım ve kaynak sürümü okunur; yalnız bu lab'ın OM metrik/terim açıklaması ve owner kopyası güncellenir. Cube SQL veya CDGC değiştirilmez; yayın/onay kopyalanmaz. Sonuç yeniden okunup doğrulanmadan başarılı business-sync.json checkpoint'i yazılmaz. Dış erişim yokken bu komut hata verir ve sahte kopya üretmez.
5. Run-Scenario'yu tekrar çalıştır. Verify-DualCatalog / verify-dual-catalog.sh yalnız mevcut durumu ölçer; eksikleri kendiliğinden onarmaz. Sync-Catalog teknik metadata'yı yeniler; son gerçek CDGC kopyası varsa onun açıklamasını korur, dış org'a yazmaz.

Çift katalog kontrolleri: üç varlık/metrik/terim kimliği; normalize edilmiş açıklamanın iki katalogda aynı olması ve Cube/OM hesap sözleşmesi; CDGC owner/rol → OM ekip eşlemesi; CDGC modifiedOn ve açıklama hash'inin son aktarım checkpoint'iyle aynı olması. Kaynak sürümü değişirse tekrar inceleyip açık sync çalıştırılana kadar revision kontrolü başarısız olur. Bu, sürekli senkronizasyon veya otomatik anlam/çeviri eşdeğerliği değildir.

## Yayın ve manuel onay

Published insan onayı değildir. Gerçek CDGC varlık sürümlerinden kanitlar/cdgc-approval-template.json oluşur. Yalnız gerçek workflow kaydından decision=approved, ticketId, reviewer ve timezone içeren observedAt gir; Import-GovernanceApproval.ps1 -Path <dosya> / bash import-governance-approval.sh <dosya> ile aktar. Run-Scenario kaydın üç benzersiz varlık/sürüm/tarih tutarlılığını sınar; onaylayanın yetkisi veya workflow yürütümü bağımsız doğrulanmaz.

## Bileşenlere erişim

Deploy sonunda Show-Access aynı özeti verir. Her tünel ayrı terminalde açık kalmalı:

| Bileşen | Windows / Linux | Adres |
|---|---|---|
| PostgreSQL | Connect.ps1 / bash connect.sh | 127.0.0.1:15439, DB komtas_rm8, user rm8_bi |
| dbt dokümanı | Connect-Docs.ps1 / bash connect-docs.sh | http://127.0.0.1:18088/static_index.html |
| Streamlit | Connect-Dashboard.ps1 / bash connect-dashboard.sh | http://127.0.0.1:8508 |
| Cube API | Connect-Cube.ps1 / bash connect-cube.sh | http://127.0.0.1:4008/cubejs-api/v1/meta |
| Python | Query-Metrics.ps1 / bash query-metrics.sh | Kubernetes içindeki istemci |
| OpenMetadata | Connect-Catalog.ps1 / bash connect-catalog.sh | http://127.0.0.1:18588 |
| CDGC | Mevcut org portalın | Dış hesap; API hostu web portalı değildir |

SQL parolası: Get-Connection.ps1 / bash get-connection.sh. OM girişi: Get-CatalogLogin.ps1 / bash get-catalog-login.sh. Cube kısa süreli JWT: Get-ApiToken.ps1 / bash get-api-token.sh. OM'de RM8Postgres.komtas_rm8.dwh.v_sales_detail, BeverageBusiness, üç metrik ve BeverageRevenue kaydını incele. dbt ayrı yönetim ekranı sunmaz. Destek servisleri dışarı açılmaz.

Port doluysa `./Connect-Catalog.ps1 -Port 18589` / `bash connect-catalog.sh 18589` kullan ve http://127.0.0.1:18589 adresini aç. Docker backend/WSL relay işlemini kapatma. `docker ps --filter publish=18588` ile mevcut Docker port eşlemesini görebilirsin. Namespace izolasyonu aynı localhost tünel portunu paylaşma imkânı vermez.

## Hata deneyi ve sınırlar

Inject-GovernanceFault.ps1 / bash inject-governance-fault.sh yerel NetRevenue owner kaydını kaldırır; veri ve Cube hesabı değişmez. Run-Scenario yerel sahiplik kontrolünü başarısız göstermeli. Restore-Governance.ps1 / bash restore-governance.sh ile yerel kayıtları düzelt. Gerçek CDGC erişimi varsa OM açıklamasını değiştirmek definition kontrolünü, CDGC kaynak sürümü değişikliği revision kontrolünü düşürür. Dış org'u otomatik değiştiren hata scripti yoktur.

API bridge ve manuel checkpoint kurumsal entegrasyon ürünü değildir. Çift yönlü sync, silme olayları, retry kuyruğu, conflict onayı, tam audit, otomatik tarama, contract/SLO enforcement, federasyon, ontology/graph ve agent kapsam dışıdır. Dış tarayıcının yerel PostgreSQL'e erişimi ayrıca onaylı agent/ağ tasarımı ister; 127.0.0.1 port-forward bunu sağlamaz. business-sync.json gerçek iş tanımı içerebilir; yerelde sakla. Uygulamaya yüklenen sonuc.json tanım metnini taşımaz.

## Durdur ve sil

Stop.ps1 / bash stop.sh yerel lab servislerini durdurur; veriler korunur. Remove-Environment.ps1 / bash remove-environment.sh sahiplik etiketini kontrol eder ve namespace adını yazarak onay ister. Yalnız o namespace'in verilerini ve Secret'larını siler; önce rapor/veri yedeğini al. Dış CDGC org'una veya varlıklarına dokunmaz.

## CDGC API kaynağı

https://docs.informatica.com/data-governance-and-quality-cloud/data-governance-and-catalog/current-version/api-reference/introduction/authentication.html

https://docs.informatica.com/data-governance-and-quality-cloud/data-governance-and-catalog/current-version/api-reference/search-for-assets/retrieve-details-of-multiple-assets/example-request.html

CDGC istemcisi yalnız read-only bulk asset details POST çağrısını kullanır; Bearer JWT / X-INFA-ORG-ID, resmi HTTPS host ve yönlendirme engeli vardır. Gerçek dış hesap olmadan API entegrasyonu doğrulanmış sayılmaz.

## Ekrandan tanımlanan dış bağlantı

Kurulum paketini hazırla ekranında dış servisi seçip host/kimlik ve isteğe bağlı eşlemeleri doldurabilirsin. Bilgiler external-connections.json ve servisin settings.json dosyasına aktarılır; DIS_SERVISLER.md akışı açıklar. “Kurulumda bağlan” seçildiyse Deploy namespace oluşturulduktan sonra token’ı yerelde gizli olarak ister. Aynı host/kimliğe ait Secret varsa yeniden istemez; farklı bağlantı varsa sessizce değiştirmek yerine durur ve Set bağlantı scriptini kullanmanı ister. Token süresi dolmuşsa Set scriptiyle yenile. “Şimdilik yerel bileşenleri dene” seçimi dış servis adımını atlar; eksik kontroller denenmedi kalır. Bağlantı formu erişim testi veya dış hesabın kurulması değildir.

Yerel-only seçiminde connection-mode.txt işareti, daha önce var olan Secret olsa bile dış API kullanımını engeller. Daha sonra Set bağlantı scriptini bilerek çalıştırmak bu işareti connect yapar; Run kontrolleri ConfigMap’i yenileyerek yeni modu kullanır. Formdan yeni paket üretmek seçilen modu tekrar uygular.

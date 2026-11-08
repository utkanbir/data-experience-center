# RM4 doğrulama · 2026-11-08 UTC

Docker Desktop Kubernetes, ayrı ve geçici `komtas-rm4-check-1108` namespace’i üzerinde gerçek kurulum yapıldı. Kullanıcının RM1/RM2/RM3 ortamları değiştirilmedi.

- Deploy.ps1 başarılı: PostgreSQL, dbt Core Job, dbt dokümanı, Cube Core/Store ve Streamlit.
- 7 dbt modeli ve 12 veri testi geçti; statik doküman üretildi.
- Cube API 6 ay/kanal satırı üretti. Net gelir, net litre ve ağırlıklı ortalama fiyat bağımsız CSV referansıyla eşleşti.
- Cube SQL üretim kanıtı saklandı. Python CLI ve gerçek dashboard kod yolu aynı API’den aynı sonuçları aldı; dashboard servis sağlık kontrolü geçti.
- Tokensiz API isteği reddedildi (401/403); kimliği doğrulanmış sorgu başarılı oldu. Kullanıcı bazlı SSO/RLS testi yapılmadı.
- Streamlit tarayıcıda açıldı; 6 satırlı tablo ve HoReCa gelir grafiği görüldü.
- Negatif deney: Cube net gelir formülü brüt gelire çevrildi. dbt testleri ve iki tüketici eşleşmesi geçtiği halde cube_match başarısız oldu; Run-Scenario başarısızlık raporu üretti.
- Restore sonrası tam Run-Scenario raporu: 16 kontrol + 4 SQL yürütmesi, 20/20 geçti. Tasarım kapsam notu 23.3/100 olarak kalır.
- Uygulama/paket testleri: 26 geçti. PowerShell ve 18 Bash betiği sözdizimi kontrolü yapıldı. Gerçek Linux host kurulumu ayrıca doğrulanmalı.

Cube Core/Store v1.6.77, PostgreSQL 17.11-bookworm, Python 3.12.12-slim-bookworm, dbt-core 1.9.10, dbt-postgres 1.9.1, Streamlit 1.51.0. PyPI bağımlılıkları çalışma sırasında kurulur; internet erişimi ve paket indirme süresi gerekir.

Kubernetes ayarları gerçek test sırasında düzeltildi: Cube Store servis ortam değişkeni çakışmasını önlemek için enableServiceLinks=false; Cube model yolu schema olarak açıkça tanımlı; ConfigMap dizinindeki symlink kopyalarının çift derlenmesini önlemek için Sales.js tek dosya/subPath olarak bağlanır. Formül değişimi Cube rollout restart gerektirir.

Lab tek düğümlüdür. Cube Store ön toplama/performance benchmark, yüksek erişilebilirlik, kurumsal governance, ontology, federasyon ve Agent360 bu doğrulamanın kapsamı değildir. İki tüketicinin eşleşmesi tek başına doğruluk kanıtı sayılmadı; bağımsız referans kontrolü ayrıca uygulandı.

Resmî kaynaklar: https://github.com/cube-js/cube · https://docs.cube.dev/reference/core-data-apis/rest-api/reference · https://pypi.org/project/streamlit/1.51.0/

Stop.ps1 gerçek testte PostgreSQL ve tüm uygulama Deployment’larını sıfır replikaya indirdi; kalıcı veri ve Secret korunur. Geçici test namespace’i sahiplik ve yazılı namespace kontrolüyle Remove-Environment kullanılarak temizlendi.

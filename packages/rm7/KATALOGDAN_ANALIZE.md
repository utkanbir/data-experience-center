# RM7 — Katalogdan analize

Ortak soru: HoReCa kanalında Şubat net geliri Ocak’a göre nasıl değişti? Hangi kurumsal tanım, sorumlu ve teknik kaynak kullanılıyor?

1. Informatica’da üç Metric tanımı, stakeholder/yayın hazırlığı ve gerçek PostgreSQL metadata taraması yapılır. View’da üç ACCEPTED glossary bağı kurulur.
2. governance/settings.json içindeki üç CDGC kaydı ve teknik kaynak açık Cube metrik kimliklerine eşlenir. Hesap açıklama metninden türetilmez.
3. Connect ile bağlantıları aç; Streamlit dashboard’da CDGC’den dönen metrik kaydını seç.
4. İş tanımı, sahiplik kişi/rol kimlikleri, yayın durumu ve teknik kaynak gösterilir. Beklenen owner ID’leri boşsa mevcut atamanın varlığı ölçülür; belirli kişinin doğrulandığı iddia edilmez.
5. Analizi çalıştır: CDGC yeniden okunur ve yalnız seçilen kayda eşlenmiş Cube metriği sorgulanır. catalog-analysis.json dosyasını dashboard’dan indir.
6. Negatif deney: yalnız yerel eşlemede expectedExternalId değerini yanlış yapıp Run-Governance çalıştır; ConfigMap güncellendikten sonra dashboard’ı yeniden oku. Kayıt sorgulanamaz olmalı. Gerçek Informatica kayıtlarını bozma. Sonra doğru eşlemeyi geri getir ve tekrar güncelle.

CDGC erişilemiyorsa, JWT bittiyse veya beklenen bağ yoksa bu akış Cube çağırmaz. Eski onaylı veri önbelleği yoktur. Doğrudan Cube API / Query-Metrics hâlâ yerel hesabı test eder; bu yeni kullanıcı akışı değildir. Published insan onayı değildir. Policy bize ait; Cube yerleşik CDGC entegrasyonu değildir.

## Mevcut ortamı güncelle

Yeni ZIP’i ayrı klasöre çıkar. Eski paketindeki governance/settings.json ve varsa connection-mode.txt dosyasını yeni pakete taşı; namespace aynı olmalı. Secret token’ı ZIP’e koyma. Update-Experience.ps1 veya bash update-experience.sh çalıştır. Yalnız tüketici/governance ConfigMap’leri ve dashboard Deployment güncellenir; PostgreSQL verisi yeniden yüklenmez. Güncelleme için Deploy çalıştırman gerekmez. Script dashboard’ı yeniden başlatır; Connect tüneli kapanırsa yeniden Connect çalıştır. Yeni JWT gerekiyorsa Set-InformaticaConnection kullan.

Run-Scenario raporundaki eski SQL/Cube/CDGC kontrolleri ile catalog-analysis.json farklı kanıtlardır. Eski rapor yeni dashboard akışını otomatik doğrulamış sayılmaz. Gerçek org’a bağlanmadan bu entegrasyon canlı doğrulanmış sayılmaz.

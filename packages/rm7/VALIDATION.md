# Doğrulama — 9 Kasım 2026

Windows PowerShell 7 ve Docker Desktop Kubernetes üzerinde bağımsız `komtas-rm7-check-1109` namespace'inde Deploy ve Run-Scenario çalıştırıldı. Mevcut kullanıcı namespace'leri değiştirilmedi.

Sonuç: **27 kontrolden 20 geçti, 0 başarısız, 7 denenmedi.** Dört SQL yürütmesi, 2.016 satır, referans gelir/litre/oran hesabı, salt okunur SQL rolü, dbt modelleri/testleri/dokümanı, Cube API/SQL/referans eşleşmesi, Python/dashboard tüketici kod yolları ve tokensiz ret doğrulandı. HTML ve JSON raporu üretildi; JSON uygulamanın rapor doğrulayıcısından geçti. Tek başına Job'un tamamlanması governance başarısı değildir.

Gerçek CDGC org/JWT sağlanmadı; `remoteRequestPerformed=false`. Yedi CDGC kontrolü denenmedi. Ürün API'sinin canlı uyumluluğu, org'un gerçek sahiplik yanıt yolları, kaynak taraması, kurumsal onay yetkisi ve workflow yürütümü doğrulanmadı. Published insan onayı olarak sayılmaz. Manuel onay kaydı yalnız sürüm/tarih/kayıt tutarlılığı kanıtıdır.

Altı Python sözleşme testi: olumlu örnek yanıt, Published/onay ayrımı, yanlış owner, reddedilmiş glossary eşlemesi, eski/tekrarlı manuel kayıt, geçersiz host/yanıt şeması. Bunlar kurgu test verileridir; canlı CDGC kanıtı değildir. Çalıştır: `python tests/rm7_contract.py` (repo kökünde).

22 Bash scripti `bash -n` ile doğrulandı; Linux üzerinde gerçek küme yürütümü yapılmadı. PowerShell scriptlerinin tamamı parser kontrolünden geçti. Uygulama testleri, TypeScript ve üretim build'i çalıştırıldı. RM7 paket modalı, dış erişim açıklaması, ürün logoları ve erişim komutları tarayıcıda kontrol edildi.

Rapor örneği: `docs/rm7-local-result.json` (repo kökünde). Tasarım kapsam notu 40/100'dür; 20/27 deney kontrol sonucu aynı ölçü değildir.

`Run-Scenario.ps1 -RequireComplete` aynı gerçek ortamda yeniden çalıştırıldı: yerel 20 kontrol yine geçti; dış 7 kanıt eksik kaldığı için rapor üretildikten sonra beklenen exit code 1 ile tamamlandı. Eksik dış erişim tam başarıya dönüştürülmedi.

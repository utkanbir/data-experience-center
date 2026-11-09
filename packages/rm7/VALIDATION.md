# Katalogdan analize doğrulama sınırı

Yeni dashboard akışının olumlu ve olumsuz yolları sentetik CDGC API fixture’ları ve Cube çağrı takibiyle test edilir. Kullanıcının gerçek CDGC org’u üzerinde yeni dashboard akışı bu değişiklikte çalıştırılmadı. Eski SQL/Cube/governance raporları yeni kullanıcı akışının geçtiği anlamına gelmez. Yeni kanıt dashboard’dan indirilen catalog-analysis.json dosyasıdır; uygulamadaki eski rapor yükleyicisi bunu otomatik deney kontrolü saymaz.

# Doğrulama — 9 Kasım 2026

Windows PowerShell 7 ve Docker Desktop Kubernetes üzerinde bağımsız `komtas-rm7-check-1109` namespace'inde Deploy ve Run-Scenario çalıştırıldı. Mevcut kullanıcı namespace'leri değiştirilmedi.

Sonuç: **27 kontrolden 20 geçti, 0 başarısız, 7 denenmedi.** Dört SQL yürütmesi, 2.016 satır, referans gelir/litre/oran hesabı, salt okunur SQL rolü, dbt modelleri/testleri/dokümanı, Cube API/SQL/referans eşleşmesi, Python/dashboard tüketici kod yolları ve tokensiz ret doğrulandı. HTML ve JSON raporu üretildi; JSON uygulamanın rapor doğrulayıcısından geçti. Tek başına Job'un tamamlanması governance başarısı değildir.

Gerçek CDGC org/JWT sağlanmadı; `remoteRequestPerformed=false`. Yedi CDGC kontrolü denenmedi. Ürün API'sinin canlı uyumluluğu, org'un gerçek sahiplik yanıt yolları, kaynak taraması, kurumsal onay yetkisi ve workflow yürütümü doğrulanmadı. Published insan onayı olarak sayılmaz. Manuel onay kaydı yalnız sürüm/tarih/kayıt tutarlılığı kanıtıdır.

Altı Python sözleşme testi: olumlu örnek yanıt, Published/onay ayrımı, yanlış owner, reddedilmiş glossary eşlemesi, eski/tekrarlı manuel kayıt, geçersiz host/yanıt şeması. Bunlar kurgu test verileridir; canlı CDGC kanıtı değildir. Çalıştır: `python tests/rm7_contract.py` (repo kökünde).

22 Bash scripti `bash -n` ile doğrulandı; Linux üzerinde gerçek küme yürütümü yapılmadı. PowerShell scriptlerinin tamamı parser kontrolünden geçti. Uygulama testleri, TypeScript ve üretim build'i çalıştırıldı. RM7 paket modalı, dış erişim açıklaması, ürün logoları ve erişim komutları tarayıcıda kontrol edildi.

Rapor örneği: `docs/rm7-local-result.json` (repo kökünde). Tasarım kapsam notu 40/100'dür; 20/27 deney kontrol sonucu aynı ölçü değildir.

`Run-Scenario.ps1 -RequireComplete` aynı gerçek ortamda yeniden çalıştırıldı: yerel 20 kontrol yine geçti; dış 7 kanıt eksik kaldığı için rapor üretildikten sonra beklenen exit code 1 ile tamamlandı. Eksik dış erişim tam başarıya dönüştürülmedi.

## Dış bağlantı formu ve yerel kimlik bilgisi akışı

Host/kimlik ve eşlemelerin dosyalara aktarımı, eksik/yanlış bağlantının reddi, bilinmeyen parola/token alanlarının pakete alınmaması ve bulut tanımının otomatik deploy sayılmaması test edildi. PowerShell initializer RM6/RM7/RM8 için simüle kubectl ile 12 durumda sınandı: yeni bağlantıda yalnız bir gizli token sorusu; sonra bağlan seçimi; mevcut aynı bağlantının yeniden kullanılabilmesi; farklı host/kimliğin reddi. Bu testler gerçek dış servis erişim kanıtı değildir. Üç Python yerel-only testi, mevcut örnek credentials olsa bile CDGC, yönetilen dbt ve çift katalog kodunun API istemcisini çağırmadığını doğruladı. Dış hesap/token sağlanmadı; canlı dış bağlantı hâlâ denenmedi.

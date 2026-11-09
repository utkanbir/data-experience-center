# RM6 doğrulama

2026-11-09: Docker Desktop Kubernetes üzerinde izole `komtas-rm6-check-1109` namespace kullanıldı. Yerel PostgreSQL, dbt model/test/semantic manifest ve doküman üretimi çalıştırıldı. Run-Scenario 16 başarılı, 5 denenmedi, 0 başarısız kontrol üretti (4 SQL çalıştırması + 17 rapor kontrolü). Beş dış servis kontrolü kullanıcı hesabı/token sağlanmadığı için denenmedi kaldı.

`-RequireComplete` eksik dış kanıtlarda hata kodu 1 döndürdü. Export-Demo yalnız sentetik raw şemasını yerel SQL dosyasına yazdı; harici sisteme aktarım yapılmadı. Stop ve sahiplik kontrollü Remove-Environment yalnız bu test namespace üzerinde sınandı; test namespace kaldırıldı.

Yönetilen istemcinin sekiz protokol testi: resmî HTTPS host sınırı, environment kimliği, JSON/base64 sonuç, altı referans satır, hatalı sonuç/duplicate, GraphQL hatası, polling timeout ve redirect reddi. Bunlar gerçek dbt hesabının veya Power BI connector'unun uçtan uca testi değildir.

Yönetilen servis, plan, token, ağ yolu ve Power BI preview entegrasyonu kullanıcı ortamında ayrıca doğrulanmalıdır. Power BI CSV karşılaştırması manuel kullanıcı kanıtıdır; otomatik connector çalıştırması değildir.

## Dış bağlantı formu ve yerel kimlik bilgisi akışı

Host/kimlik ve eşlemelerin dosyalara aktarımı, eksik/yanlış bağlantının reddi, bilinmeyen parola/token alanlarının pakete alınmaması ve bulut tanımının otomatik deploy sayılmaması test edildi. PowerShell initializer RM6/RM7/RM8 için simüle kubectl ile 12 durumda sınandı: yeni bağlantıda yalnız bir gizli token sorusu; sonra bağlan seçimi; mevcut aynı bağlantının yeniden kullanılabilmesi; farklı host/kimliğin reddi. Bu testler gerçek dış servis erişim kanıtı değildir. Üç Python yerel-only testi, mevcut örnek credentials olsa bile CDGC, yönetilen dbt ve çift katalog kodunun API istemcisini çağırmadığını doğruladı. Dış hesap/token sağlanmadı; canlı dış bağlantı hâlâ denenmedi.

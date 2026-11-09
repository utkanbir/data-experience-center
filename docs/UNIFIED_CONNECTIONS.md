# RM1–RM9 ortak bağlantı oturumu

`Connect.ps1` / `bash connect.sh` mimarinin yerel servis tünellerini açar. `Get-Connections.ps1` / `bash get-connections.sh` adres/kullanıcı/parola ve varsa kısa ömürlü Cube JWT’sini tek terminalde gösterir. Harici servislerin host/org/environment ayarları ve yerel kimlik bilgisi komutları ayrı gösterilir; harici tokenlar yazdırılmaz.

Gerçek RM9 testinde yedi tünel açıldı. Dolu 15440 yerine 15441 seçildi. İkinci oturum reddedildi. Disconnect PID + süreç adı + başlangıç zamanı ile yalnız sahip olunan kubectl süreçlerini durdurdu. Ayrı dinleyici etkilenmedi. Eski tek servis yardımcıları uyumluluk için saklanır. Çalışma portları ve PID bilgisi `.connections/` altında tutulur; parola/token dosyaya yazılmaz ve bu klasör paket/Git kapsamına alınmaz.

Linux scriptleri Bash ve util-linux/flock gerektirir; canlı Linux testi yapılmadı. Windows PowerShell akışı gerçek Kubernetes servisleriyle doğrulandı. UI’daki Erişim sekmesi, kurulum rehberi, Deploy sonu özeti ve ZIP içindeki BAGLANTILAR.md aynı iki komutu gösterir.

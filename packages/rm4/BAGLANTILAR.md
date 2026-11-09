# Tek komutla tüm bağlantılar

Deploy tamamlandıktan sonra paket klasöründe bir terminal açın:

Windows: `.\Connect.ps1`

Linux: `bash connect.sh` (Bash, kubectl, util-linux/flock gerekir).

Bu tek terminal bütün yerel servis tünellerini açar; açık kalsın. Port doluysa sonraki boş port seçilir. İkinci terminalde Windows `.\Get-Connections.ps1`, Linux `bash get-connections.sh` çalıştırın. Adresler, veritabanı/kullanıcı ve yerel parola/Cube JWT tek özette gösterilir. Parolalar dosyaya yazılmaz. Gizli bilgi göstermeden özet: `Get-Connections.ps1 -NoSecrets` / `bash get-connections.sh --no-secrets`.

Ctrl+C bütün bu oturum tünellerini kapatır; servisler ve veri kalır. Windows’ta kaybolmuş oturumu kapatma: `Connect.ps1 -Disconnect`; yalnız PID ve başlangıç zamanı eşleşen kubectl çocuklarını durdurur. Connect aynı pakette eşzamanlı ikinci oturumu reddeder. Açılışta bir servis başarısızsa başlatılan tüneller de kapatılır; Deploy/pod durumunu düzeltip tekrar deneyin.

Harici dbt/Informatica erişimi localhost tüneli değildir; özette host/org/environment ve ilgili yerel kimlik bilgisi komutu gösterilir. Harici tokenlar ekrana dökülmez. Eski tek servis Connect-* ve Get-Connection yardımcıları uyumluluk için pakette bulunur; günlük kullanımda bu iki komut yeterlidir. Gerçek tünel portları `.connections/` altında saklanır; bu dosyalarda parola/token yoktur.

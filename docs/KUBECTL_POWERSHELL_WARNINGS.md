# PowerShell kubectl watch uyarıları

Windows PowerShell 5.1, native stderr çıktısını NativeCommandError kaydı olarak üretir. Common.ps1 genel ErrorActionPreference=Stop kullanınca kubectl watch bağlantısını yeniden açabilse bile bir uyarı kurulumu durdurabiliyordu.

RM1–RM10 Common.ps1 komut çalıştırıcısı stderr ve stdout’u ayırır. Native komut çağrısı sırasında ErrorActionPreference yalnız yerel olarak Continue olur; önceki değer finally ile geri yüklenir. Başarı/hata kubectl çıkış koduyla belirlenir. Başarıda uyarı ayrı warning stream’ine verilir; JSON stdout’una karışmaz. TLS timeout / bağlantı kopması gibi geçici hatalar dört denemeye kadar tekrar edilir; Forbidden gibi gerçek hatalar doğrudan durdurulur. JSON apply girdisi aynı çalıştırıcıdan geçirilir. Geçici stderr dosyası her durumda kaldırılır.

Gerçek Windows PowerShell 5.1 üzerinde stderr uyarısı + geçerli JSON, iki kez TLS timeout ardından başarı, stdin JSON apply ve Forbidden/exit 2 durumları test edildi. Uyarı yutulmaz; başarılı kodda fatal sayılmaz. Bu düzeltme kümenin kapalı veya kaynaklarının tükenmiş olmasını çözmez.

# Senaryo merkezi

`/#scenarios` iş ihtiyacına göre mevcut 14 referans mimariyi karşılaştırır. Beş hazır senaryo, metinle senaryo ekleme, doküman okuma, düzenlenebilir ihtiyaç listesi, kaynak alıntıları ve JSON içe/dışa aktarımı vardır.

Her ihtiyaç bir katalog yeteneğine, hedef düzeye (1–3), önceliğe ve ağırlığa (1–5) bağlanır. Senaryo uyumu ağırlıklı hedef karşılama oranıdır; mimarinin genel kapsam notundan ve deney sonuçlarından ayrıdır. Zorunlu ihtiyaç açıkları ve yerel/açık kaynak kısıtları ayrıca gösterilir. Katalogda ölçülmeyen koşullar OTHER olur ve puan kazanmaz. Puanlama LLM tarafından yapılmaz.

Mimaride senaryo ile ilgili mevcut roller turuncu, eksik roller kesikli kırmızı, odak dışı roller gri görünür. Ürün logoları ve Komtaş 360 alanları korunur. Katalog puanı, ürün kurulum veya performans garantisi değildir.

## Dokümanlar

DOCX paragrafları ve tabloları, PPTX slayt metni, XLSX sayfa/satır/hücre metni ve kayıtlı formül sonuçları, CSV/TSV/MD/TXT metni okunur. Eski DOC/PPT/XLS, PDF, resim ve gömülü nesneler desteklenmez; PDF/OCR bu sürüme dahil değildir. PPTX özel gösteri sırası yerine slayt dosya sırası kullanılır. Excel formülleri çalıştırılmaz; tarih seri değerleri ve gizli sayfalar için uyarı gösterilir.

Dosya başına 12 MB, arşivde seçilen en fazla 300 XML parçası, parça başına 3 MB, toplam açılmış metin 24 MB sınırı vardır. Çıkarılan metin en fazla 600 birim / 100.000 karakterdir; kısaltma açıkça bildirilir. Dosyalar diske yazılmaz. XML DTD/entity reddedilir; dış referanslar veya makrolar çalıştırılmaz.

## LLM

Kurallı taslak için anahtar gerekmez. İsteğe bağlı LLM analizi mevcut BYOK bağlantısını kullanır. Kullanıcı açıkça LLM düğmesine bastığında en fazla 24.000 karakter seçilen sağlayıcıya gönderilir. Daha büyük içerik sessizce kesilmez; bölme veya kurallı taslak önerilir. Modelin JSON şeması ve alıntılarının gerçek kaynak biriminde bulunması kontrol edilir. Bu kontrol ihtiyaç yorumunun doğruluğunu kanıtlamaz; kullanıcı gözden geçirip kaydeder.

Anahtar yalnız sekme belleğinde tutulur. Kaydetme, yalnız senaryo metni, ihtiyaçlar ve alıntıları bu tarayıcıya yazar; orijinal dosyalar veya tam doküman metni saklanmaz. JSON taşınabilir yedektir. İş dokümanının sağlayıcıya gönderilmesi kullanıcının kurum politikasına göre seçilir.

## Kurulum sınırı

Özel senaryo için üretilen ZIP, `scenario-context.json` içinde ihtiyaçları taşır; çalıştırılan deney hâlâ ortak sentetik içecek deneyidir. `reference-lab-only` bağı bu ayrımı belirtir. RFI/RFP'deki iş verisi veya özel koşullar otomatik uygulanmış/test edilmiş sayılmaz.

## Doğrulama

40 Node testi: katalog ve paket sınırları, senaryo puanlama/kısıtlar, OOXML metin çıkarma, formülün çalıştırılmaması, DTD/boyut reddi, LLM alıntı kontrolü ve same-origin API. LLM protokol testleri sahte taşıyıcı kullanır; gerçek kullanıcı anahtarıyla sağlayıcı çağrısı yapılmadı. Tarayıcıda senaryo değiştirme, RM4 seçimi, metinden taslak, kayıt, anahtar eksikliği ve Word yükleme akışı kontrol edildi.

## Ekran düzeni

Senaryo merkezi, referans mimari listesi ve mimari ayrıntısı ekran yüksekliğine sığan çalışma alanlarıdır. Ana çizim içerik kaydırılırken görünür kalır; mimari listesi ve okuma alanı kendi içinde kayar. Senaryo değerlendirmesi, ihtiyaç/kaynaklar, Komtaş katkısı ve kurulum ayrı sekmelerde açılır. Yeni senaryo düzenleyicisi bağımsız bir pencere açar. Dar ekranda mimari sıralaması seçim kutusuyla erişilir. Ana referans mimari satır seçimiyle önizlenir; “Ayrıntıları aç” mimarinin çalışma ekranına geçer. Uzun tanıtım alanı kaldırılmıştır.

Çizimler ekran yüksekliğine göre daha geniş açılır. Yerel +/− kontrolleri yalnız çizimi ölçekler; Sığdır varsayılan sığdırmayı geri getirir. Tam ekran görünümü etkileşimli çizimi, filtreleri ve ürün ayrıntılarını korur; Esc ile kapanır. Büyük çizim kendi alanında kaydırılır, tarayıcı yakınlaştırması gerekmez.

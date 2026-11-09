# RM8 doğrulama — 9 Kasım 2026

Windows PowerShell 7 ve Docker Desktop Kubernetes üzerinde ayrı `komtas-rm8-check-1109` namespace'inde gerçek Deploy ve Run-Scenario çalıştırıldı. Mevcut kullanıcı ortamları değiştirilmedi.

**Başlangıç sonucu: 38 kontrolden 27 geçti, 0 başarısız, 11 denenmedi; exit 0.** Dört SQL yürütmesi, dbt modelleri/testleri/dokümanı, Cube API/SQL/referans eşleşmesi ve iki tüketici kod yolu, yetkisiz API isteğinin reddi ve yedi OpenMetadata kontrolü ölçüldü. Gerçek OM tablosu, kolonları, owner, glossary, dbt lineage, metrik SQL eşlemesi, SQL kalite sonucu ve yerel ürün kaydı doğrulandı. HTML/JSON raporu üretildi; gerçek sonuc.json uygulama rapor doğrulayıcısından geçti.

**Owner hata deneyi: 26 geçti, 1 başarısız (`om_owner`), 11 denenmedi; exit 1.** Inject-GovernanceFault gerçek yerel metrik owner kaydını kaldırdı. SQL ve Cube sonuçları geçerken sahiplik kontrolü düştü. Hata raporu korundu; Run-Scenario kaydı otomatik onarmadı.

CDGC org/JWT yokken Sync-BusinessDefinitions gerçek Job'u exit 1 verdi; business-sync.json oluşturulmadığı kontrol edildi. Yerel katalog veya test verisi gerçek CDGC kaynağı yerine kullanılmadı.

Dış org/JWT sağlanmadı: yedi CDGC ve dört çift katalog kontrolü denenmedi. Canlı CDGC API yanıt şeması, başarılı dış kaynak aktarımı, gerçek owner/rol yolları ve dış sürüm değişimi doğrulanmış sayılmaz. İnsan onayı veya onaylayanın yetkisi bağımsız doğrulanmadı. Published ve manuel kayıt tutarlılığı ayrı ölçülerdir.

Yedi Python sözleşme testi: açık kimlik eşlemesi, kaynak checkpoint ayrımı, açıklama uyuşmazlığı, CDGC sürüm değişimi, owner eksikliği, tekrar eden kimlik/checkpoint, hesap SQL sapması ve beklenen kaynak lifecycle/tanım koşulu. Bunlar kurgu test verileridir; canlı dış entegrasyon kanıtı değildir. Çalıştır: `python tests/rm8_contract.py`.

30 Bash scripti syntax kontrolünden, tüm PowerShell scriptleri parser kontrolünden geçti. Linux üzerinde gerçek küme yürütümü yapılmadı. 44 uygulama testi ve TypeScript/üretim build'i geçti. RM8 ekranı, ürün logoları, paket modalı, dış erişim talimatları ve 18588 katalog erişim bağlantısı tarayıcıda kontrol edildi.

Repo kökündeki `docs/rm8-local-result.json` ve `docs/rm8-owner-fault-result.json` gerçek yerel kontrol sonuçlarıdır. 50/100 tasarım kapsam notu, 27/38 deney kontrol sayısından farklı bir ölçüdür. İki katalog aynı çıktıyı tekrar ettiği için otomatik ek kapsam verilmez.

Restore-Governance gerçek yerel kaydı geri yükledi; ardından Verify-Catalog yedi OpenMetadata kontrolünün tamamını tekrar geçti. Stop scripti lab servislerini durdurdu. Test ortamı kaldırma adımı yalnız bağımsız test namespace'ini hedefledi.

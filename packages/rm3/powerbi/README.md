# Power BI Desktop bağlantısı

Power BI Desktop Windows'ta çalışır. Kubernetes'e Power BI Desktop kurmuyoruz. Bu paket bir PBIX içermez; veri modeli, ölçüler ve rapor düzeni aşağıdaki adımlarla oluşturulur.

1. `Connect.ps1` açık kalsın. Sunucu: `127.0.0.1:15434`, veritabanı: `komtas_rm3`.
2. Power BI Desktop > Veri al > PostgreSQL > Import. Kimlik doğrulama Database, kullanıcı `rm3_bi`. Şifreyi `Get-Connection.ps1` ile gör.
3. `dwh.fact_sales`, `dwh.dim_date`, `dwh.dim_outlet`, `dwh.dim_product`, `dwh.dim_promotion` tablolarını yükle. `raw` tablolarını veya `v_sales_detail` görünümünü bu yıldız modeline ekleme.
4. `date_key`, `outlet_key`, `product_key`, `promotion_key` üzerinden dimension tarafı 1, fact tarafı çok olacak şekilde ilişkiler kur. Filtre yönü dimension'dan fact'e tek yönlü olsun. Anahtarların veri türleri eşleşsin. `date_key` Date olsun. Otomatik kurulan çakışan ilişkileri kaldır.
5. `dim_date` tablosunu `date_key` alanı üzerinden tarih tablosu olarak işaretle. Takvim 1 Ocak–28 Şubat 2025 arasında kesintisizdir. Ocak'ın 29–31 günlerinde satış yoktur.
6. `measures.dax` dosyasındaki ölçüleri tek tek ekle. `Net Revenue`, `Gross Revenue`, `Discount Amount`, `Return Amount` EUR; `Volume` litre; `Average Price` EUR/litre; `Revenue Mix %` ve `Net Revenue MoM %` yüzde biçiminde olsun.
7. Matrix: satırlar `channel`, sütunlar `month_start`, değerler `Net Revenue`, `Volume`, `Average Price`, `Active Outlets`. `expected-results.csv` ile karşılaştır.
8. İkinci sayfada kanal filtresi HoReCa; ay bazlı Net Revenue grafiği ve distribütör/outlet/ürün/promosyon kırılımları ekle. Ülke filtresiyle TR/DE seçilebilsin.

HoReCa Net Revenue Ocak 8.164,80 EUR, Şubat 3.628,80 EUR; değişim -%55,56. Satış miktarı ve iadeler kontrollü sentetik olarak değiştirildi. Bu, gerçek bir nedensellik analizi değildir. Promosyon oranı aynı kaldı.

`Revenue Mix %`, seçili ülke/kanal/tarih içindeki ürünün gelir payıdır. Net Revenue düşüşünü fiyat/hacim/mix etkilerine ayrıştıran bir köprü analizi değildir. Hacim net litredir; satılan ve iade edilen ambalaj adetleri ayrı fact alanlarında tutulur.

Modern Power BI Desktop PostgreSQL sağlayıcısını içerir. Yerel lab PostgreSQL bağlantısında TLS yapılandırılmadı. Sürümün şifreleme uyarısı gösterirse sadece bu loopback lab bağlantısı için şifresiz bağlantıya izin ver. Kurumsal PostgreSQL'e aynı ayarı genelleme.

Import verisini yenilemek için port-forward oturumu ve PostgreSQL pod'u çalışmalı. Power BI Service yayını/gateway bu ilk mimarinin kurulum kapsamına dahil değil.

Kaynak: https://learn.microsoft.com/en-us/power-query/connectors/postgresql

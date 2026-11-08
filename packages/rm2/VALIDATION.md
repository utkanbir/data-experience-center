# RM2 doğrulaması · 2026-11-08

Docker Desktop Kubernetes v1.34.3 üzerinde ayrı komtas-rm2-check-1108 namespace'iyle gerçek kurulum yapıldı. PostgreSQL StatefulSet, iki PVC, seed Job, dbt Job ve verify Job başarılı oldu. dbt Core 1.9.10 + dbt-postgres 1.9.1 yedi model ve on iki veri testini geçti. Statik doküman ve model bağımlılık manifesti üretildi.

Windows Run-Scenario.ps1 gerçek cluster'da çalıştı. HTML, JSON ve kanıtlar üretildi. Sağlıklı çalışma: 15/15 deney kontrolü; tasarım kapsam notu bundan ayrıdır.

Geçersiz ürün anahtarı enjeksiyonu dbt ilişki testini başarısız yaptı. Eksik serving view durumunda SQL metrikleri null/denenmedi, dbt testleri failed olarak raporlandı. Düzeltme sonrasında dbt build tekrar test edildi. Uygulama içe aktarma, eksik kanıt ve RM1/RM2 paket ayrımı dahil 15 otomatik test geçti.

Linux Bash scriptleri sözdizimi ve kontrollü hata/rapor akışıyla sınandı. Linux host üzerinde gerçek kurulum ayrıca denenmelidir. Power BI Desktop bağlantısı, DAX modeli ve rapor tüketimi bu testlere dahil değildir. Kurulum/test için açılan namespace test bitiminde kaldırılır.

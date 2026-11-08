# RM3 doğrulaması · 2026-11-08

Docker Desktop Kubernetes üzerinde ayrı komtas-rm3-check-1108 namespace'iyle gerçek kurulum ve senaryo çalıştırıldı. dbt Core 1.10.15, dbt-postgres 1.9.1, dbt-metricflow 0.11.0 / MetricFlow 0.209.0 birlikte çalıştı. Sekiz model ve on iki veri testi, statik dbt dokümanı ve yerel MetricFlow sorgusu üretildi.

İki ay × üç kanal için Net Revenue, Net Liters ve Average Price sonuçları altı referans satırıyla 0.0001 toleransında eşleşti. mf_query, mf_sql ve mf_match ayrı ayrı passed oldu. Sağlıklı deney raporu 18/18 kontrolü geçti.

Brüt gelirle kasıtlı yanlış semantic tanım uygulandığında veri/model testleri, MetricFlow sorgusu ve explain başarılı kalırken mf_match failed oldu. Tanım restore edildiğinde tüm kontroller tekrar geçti. Bu ayrım teknik geçerlilik ile iş metriği doğruluğunu birbirinden ayırır.

23 uygulama/paket testi ve derleme geçti. Linux scriptleri sözdizimi kontrolünden geçti; gerçek Linux host kurulumu ayrıca doğrulanmalı. Yönetilen dbt Semantic API, ortak online servis, Power BI connector veya governance/agent akışı bu doğrulamaya dahil değildir. Geçici test namespace'i test bitiminde kaldırılır.

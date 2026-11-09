# RM9 doğrulama — 9 Kasım 2026

İzole `komtas-rm9-check-1109` namespace’inde Docker Desktop Kubernetes üzerinde gerçek Deploy ve Run-Scenario çalıştırıldı.

- Normal ve kaynak düzeltme sonrası: 29 ölçüm + 4 SQL = **33 geçti, 0 başarısız, 0 denenmedi**.
- dbt: 7 VIEW + 12 veri testi, toplam 19 başarılı; docs üretildi.
- Satış ve referans PostgreSQL fiziksel instance kimlikleri farklı; raw tabloları ayrıdır. İki catalog join’i, dağıtık EXPLAIN, yalnız VIEW oluşu ve kaynak rollerinin salt okunur oluşu ölçüldü.
- Kaynak hatası: ikinci PG’de dim_outlet geçici yeniden adlandırıldı. Rapor üretildi ve script hata kodu 1 verdi: 14 geçti, 9 başarısız (4 SQL dahil), 10 denenmedi. Restore sonrasında 33/33 başarı tekrarlandı.
- Ek cache kontrolü: REST `cache=must-revalidate` + UUID refreshKey ile kaynak erişimi bozukken Cube API kontrolü başarısız oldu; cache arkasında başarı sayılmadı. Kaynak düzeltildikten sonra tam senaryo yeniden geçti.
- OpenMetadata: 7 katalog/owner/glossary/lineage/metrik/kalite/ürün kontrolü geçti. Native connector/Airflow kurulmaz.
- Ortak Connect: yedi tünel hazır; dbt dokümanı, OM, Trino ve Streamlit HTTP 200. Cube tokensiz 403 beklenen ret. Toplu bağlantı çıktısı yerel PG/OM parolalarını ve kısa ömürlü Cube JWT’sini aldı; gizli değerler kanıt dosyalarına konmadı.
- Port 15440 kasıtlı doluyken 15441 seçildi; diğer altı tünel de hazırdı. İkinci Connect engellendi. Disconnect yalnız oturumun yedi kubectl çocuğunu kapattı; ayrı test port dinleyicisi çalışmaya devam etti.

Uygulama: 58 Node testi ve üretim derlemesi geçti. Beş Python toplam/referans testi geçti. PowerShell scriptleri ve ortak Bash scriptleri sözdizimi kontrolünden geçti. Linux kurulumu canlı Linux Kubernetes ortamında çalıştırılmadı; Windows üzerinde gerçek bağlantı/kurulum testleri yapıldı. Üretim TLS/auth/RLS, HA, performans ve maliyet testi yapılmadı. Tarayıcıda RM9 mimarisi, bileşen görevleri ve ZIP üretimi kontrol edildi.

Gizli bilgi içermeyen kanıtlar: docs/rm9-local-result.json, docs/rm9-federation-evidence.json, docs/rm9-source-fault-result.json. Tasarım kapsam notu çalışma testinden ayrıdır.

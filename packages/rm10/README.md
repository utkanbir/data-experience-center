# RM10 — Ontology + Neo4j knowledge graph

Ortak iş sorusu: Ocak–Şubat HoReCa net gelir düşüşü hangi outlet, müşteri, distribütör, ürün ve promosyon bağlamında görülüyor? Kanonik net gelir/hacim/fiyat hesabı Cube’dadır. Neo4j ilişki yollarını ve kaynak kimliğini gösterir. Bu mimari RM5’in tek PostgreSQL + dbt + Cube + OpenMetadata temelini genişletir; RM9 federasyonu burada yoktur. LLM/agent kurulmaz.

## Kurulum

Docker Desktop Linux containers + Kubernetes, kubectl, docker-desktop context’i ve varsayılan StorageClass gerekir. Linux: Bash, OpenSSL ve util-linux/flock. İmaj/PyPI indirmeleri için internet gerekir. Yerel Python/dbt/Neo4j kurmayın. Neo4j, OpenMetadata, Elasticsearch ve PostgreSQL birlikte bellek tüketir; Docker kaynaklarını kontrol edin.

ZIP’i çıkarıp rm10-kubernetes klasöründe terminal açın:

| Adım | Windows | Linux |
|---|---|---|
| Ortamı kur | `.\Deploy.ps1` | `bash deploy.sh` |
| Senaryo ve rapor | `.\Run-Scenario.ps1` | `bash run-scenario.sh` |
| Tüm servisleri aç | `.\Connect.ps1` | `bash connect.sh` |
| Adres/kullanıcı/parola | `.\Get-Connections.ps1` | `bash get-connections.sh` |
| Graph’ı açıkça yenile | `.\Sync-Graph.ps1` | `bash sync-graph.sh` |
| Yalnız graph’ı kontrol et | `.\Verify-Graph.ps1` | `bash verify-graph.sh` |
| Bir ilişkiyi kaldır | `.\Break-Graph.ps1` | `bash break-graph.sh` |
| İlişkileri geri yükle | `.\Restore-Graph.ps1` | `bash restore-graph.sh` |
| Veriyi koruyarak durdur | `.\Stop.ps1` | `bash stop.sh` |
| Namespace’i tamamen sil | `.\Remove-Environment.ps1` | `bash remove-environment.sh` |

Connect tek terminalde bütün yerel tünelleri açar; terminal açık kalsın. Ctrl+C yalnız bu oturum tünellerini kapatır. Dolu portta uygun alternatif seçilir; gerçek adres Get-Connections çıktısıdır. Ayrıntılar BAGLANTILAR.md. Parolalar kurulumda yerel Secret olarak üretilir; gerçek token/parola pakette yoktur. İmza engelinde paket klasöründe `Get-ChildItem -LiteralPath . -Filter '*.ps1' -File | Unblock-File` çalıştırın. Kurum AllSigned politikası varsa imzalı script gerekir.

Varsayılan servisler: PG 15441 / komtas_rm10 / rm10_bi; dbt docs 18090; Cube 4010; Streamlit 8510; OpenMetadata 18590; Neo4j Browser http://127.0.0.1:17484/browser/; Bolt bolt://127.0.0.1:17697 / neo4j. Browser’da Bolt URI alanına gerçek seçilen Bolt portunu girin. Neo4j kullanıcı adı neo4j; parola Get-Connections çıktısındadır. Bu kullanıcı yerel graph yöneticisidir, üretim read-only RBAC değildir. Metadata PostgreSQL, Elasticsearch ve Cube Store küme içi destek servisleridir.

## Bileşenler ne yapar?

- PostgreSQL: raw/dwh kaynak ve raporlama verisi. Sentetik raw.dim_customer ve raw.dim_outlet.customer_key müşteri bağını açıkça taşır; sonradan isimden müşteri tahmin edilmez.
- dbt Core: fact/dimension/view, 12 veri testi ve model dokümanı. Sürekli metric API değildir.
- Cube: ortak net gelir, net litre ve ağırlıklı fiyat tanımı. Streamlit/Python aynı API’yi kullanır. Deney sorgularında must-revalidate ve değişken refreshKey cache arkasında kaynak hatası gizlenmesini önler; performans benchmark’ı değildir.
- OpenMetadata: business glossary/owner, model metadata’sı, dbt manifest lineage ve SQL kalite sonucu. Açık API Job ile yüklenir; native connector/Airflow veya Neo4j connector kurulmaz.
- Neo4j Community 5.26.18: açık kavram modeli ve gerçek instance graph. Python neo4j 6.0.3 sürücüsü yükler/sorgular. Graph verisi ayrı bir kopyadır; kaynak değişince açık Sync-Graph gerekir.

## Ontology ile instance graph ayrımı

`graph/ontology.json` yedi kavramı tanımlar: Customer, Outlet, Distributor, Product, Promotion, Sale, Metric. Beş iş ilişkisi ve domain/range vardır: Customer OWNS_OUTLET Outlet; Outlet SERVED_BY Distributor; Sale AT_OUTLET Outlet; Sale OF_PRODUCT Product; Sale WITH_PROMOTION Promotion. Concept/RelationType metadata’sı bu tanımı, LabEntity instance’ları ise gerçek kaynak kayıtlarını temsil eder. INSTANCE_OF ikisini bağlar.

Kimlik: rm10:<tip>:<kaynak-anahtar>. Her varlık sourceTable/sourceKey taşır; satışlar sourceReference da taşır. Distribütör kimliği raw.dim_outlet içindeki distinct distributor_key alanından gelir. Sync, yalnız bu deneyin dataset etiketiyle oluşturulmuş graph kayıtlarını tek transaction içinde yeniler. Başka dataset’lere dokunmaz; Neo4j PVC’si ve parolası yeniden Deploy sırasında korunur.

Bu açık property graph modeli OWL/DL reasoner, SHACL motoru veya otomatik entity resolution değildir. Kaynak kimlikleri bu sentetik veri setinde zaten uyumludur. İlişki görülmesi nedensellik kanıtı değildir.

## Deneyi anlama

Run-Scenario dbt, Cube, katalog ve graph’ı ölçer; graph’ı otomatik onarmaz. 31 ölçüm + 4 SQL = 35 kontrol. Her çalıştırma yeni reports/run-… klasöründe rapor.html, sonuc.json ve kanitlar/ üretir. HTML’i açın; JSON’u uygulamada deney sonucuna yükleyin. Başarısız kontrol varsa rapor korunur ve script hata kodu döndürür.

Sekiz graph kontrolü: kavram modeli hash/domain-range eşleşmesi; kaynak varlıkları ve INSTANCE_OF; gerçek ilişki kümesi; kaynak provenance; kaynak/graph içerik hash güncelliği; müşteri→outlet→distribütör yolları; graph bağlam toplamları ile gerçek Cube sonucu; metrik kimliği ve güncel Cube SQL bağı. Kaynak hash eşleşmesi sürekli CDC veya zamanlanmış tazelik izleme değildir.

`kanitlar/graph-results.json` HoReCa outlet/müşteri/distribütör yollarını ve ay/outlet/ürün bağlamını gösterir. Neo4j Browser’da `graph/inspect.cypher` sorgularını çalıştırın. Kanonik ölçü Cube’dadır; graph’taki satır bileşenleri yalnız bağlam uzlaştırması için toplanır.

## Hata ve toparlanma

Break-Graph outlet 1’in tek SERVED_BY bağını kaldırır. Run-Scenario’yu çalıştırın: SQL ve Cube doğru kalırken ilişki kapsamı, graph güncelliği, yol sorgusu ve bağlam uzlaştırması başarısız olmalıdır. Restore-Graph açık sync ile kaydı yeniler. Deneyi yeniden çalıştırın. Veri/model değişirse önce Build-Models, sonra Sync-Graph, sonra Run-Scenario sırasını izleyin.

## Sınırlar ve kaynak belgeler

Üretim auth/TLS/RBAC/HA, büyük graph performansı, maliyet, otomatik graph CDC, formal ontology çıkarımı ve agent akışı bu paketle kanıtlanmaz. CDGC/Power BI/Trino bu varyantta yoktur. Tasarım kapsam notu 63,3/100, çalışma başarısından ayrıdır. Gerçek test sınırları VALIDATION.md’dedir.

https://neo4j.com/docs/operations-manual/current/docker/introduction/
https://neo4j.com/docs/python-manual/current/
https://neo4j.com/docs/cypher-manual/current/constraints/managing-constraints/

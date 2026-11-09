# RM10 graph deneyi

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

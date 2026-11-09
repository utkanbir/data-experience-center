# Komtaş Data Experience Center

Bağımsız React + TypeScript + Vite web uygulaması ve Node.js API sunucusu. ChatGPT, OpenAI Sites, Cloudflare Workers veya bir oturum açma sistemine bağımlı değildir.

## Senaryo merkezi ve paketler

`/#scenarios`: senaryo seç, mimari uyumunu ve ilgili katmanları karşılaştır. Yeni senaryoyu metinle veya DOCX/PPTX/XLSX/CSV/MD/TXT yükleyerek oluştur; ihtiyaçları gözden geçirip kaydet. İsteğe bağlı LLM kendi API anahtarını kullanır. Ayrıntılar: [Senaryo merkezi](docs/SCENARIO_CENTER.md).

RM1–RM5 yerel, RM6 yerel hazırlık + dış dbt servisi paketleri hazırdır. Özel senaryo JSON bağlamı ZIP’e eklenir; çalışan deney ortak sentetik referans lab olarak kalır. RM6 dış hesabı/token ve ağ erişimi olmadan dış servis kanıtları denenmedi görünür.

## Başlatma

Node.js 22.13 veya üstü gerekir; CI ve Docker Node.js 24 kullanır.

```powershell
npm ci
npm run dev
```

Arayüz: http://127.0.0.1:5173. API: http://127.0.0.1:3001. Geliştirme sırasında Vite `/api` isteklerini yerel Node sunucusuna yönlendirir.

Üretim sürümü:

```powershell
npm run build
npm start
```

Uygulama http://127.0.0.1:3001 üzerinden hem arayüzü hem API'yi sunar. Sunucuda dışarıdan erişim gerekiyorsa `HOST=0.0.0.0` ve uygun `PORT` tanımlanır. İnternet yayını için HTTPS sağlayan reverse proxy/hosting kullan. Repo GitHub'da saklanır; GitHub repo adresi tek başına çalışan bir uygulama adresi değildir.

Docker:

```powershell
docker compose up --build -d
```

Docker image build ve container çalışması bu hazırlama oturumunda test edilmedi.

## LLM: kendi anahtarını kullan

Uygulamada **Bağlantılar & durum** ekranını aç. OpenAI, Groq veya OpenRouter sağlayıcısını seç, modelini ve kendi API anahtarını gir; **Bağlantıyı test et ve kullan** düğmesine bas.

Model adları düzenlenebilir örneklerdir. Kullanılabilir modeller ve erişim koşulları sağlayıcı hesabına bağlıdır. Bağlantı testi de sağlayıcı kotasını kullanabilir.

Anahtar sadece sekmenin React belleğinde tutulur. LocalStorage, SessionStorage, cookie, dosya, GitHub veya mimari JSON'una yazılmaz. Sayfa yenilenince veya **Anahtarı temizle** seçilince silinir. İstek sırasında uygulamanın Node API sunucusuna ve seçilen sağlayıcıya iletilir; sunucu anahtarı saklamaz veya loglamaz. Başkalarının yönettiği bir kurulumda o sunucunun işletmecisine de güvenmek gerekir.

Sunucu yalnız sabit, izinli sağlayıcı HTTPS adreslerine gider. Kullanıcının serbest URL girebildiği bir proxy yoktur. Origin kontrolü, JSON boyut sınırı, süre sınırı ve temel istek sınırı uygulanır. Uygulama girişi yoktur; LLM isteği için kullanıcının geçerli sağlayıcı anahtarı gerekir.

Gerçek sağlayıcı anahtarı verilmediğinden canlı ücretli LLM çağrısı test edilmedi. Otomatik testler sahte sağlayıcı yanıtlarıyla anahtar iletimi ve hata sınırlarını doğrular.

## İçerik ve özellikler

- 14 referans mimari, 15 teknoloji kartı ve ortak iş senaryosu.
- Ana ekranda sunumdaki en zengin kanonik çizim. Referans seçilince aynı yerleşimde kullanılan alanlar renkli, diğerleri gri.
- Üç mimariyi karşılaştırma; S1–S11 kapsam matrisi. S4 yerleşim tercihi puan toplamına girmez.
- Özel mimari oluşturma, yeni teknolojiyi doğrulanmamış taslak olarak ekleme, JSON içe/dışa aktarımı.
- Taslaklar kullanıcı tarayıcısında saklanır. Sunucuda ortak veritabanı yoktur.
- Soru-cevap tercihlerine göre açıklanabilir katalog önerileri; isteğe bağlı LLM yorumu.
- RM1 için namespace/port uyarlamalı Kubernetes ZIP'i. Diğer profillerde yalnız ortam JSON'u; henüz hazır deploy şablonları yoktur.

Kapsam notu tasarım değerlendirmesidir; çalıştırılmış test sonucu veya ürün kalitesi notu değildir. LLM teknoloji yanıtları kaynak kontrolü gerektiren araştırma taslağıdır; bu sürüm otomatik web araştırması yapmış gibi davranmaz.

## Kontroller

```powershell
npm test
npm run build
```

GitHub Actions aynı kontrolleri push ve pull request üzerinde çalıştırır. Gerçek Kubernetes kurulumu, Power BI raporu ve ücretli LLM çağrısı ayrıca uçtan uca doğrulanmalıdır.

## Proje yapısı

| Dizin | İçerik |
| --- | --- |
| `src/components` | React ekranları, mimari çizimi ve LLM bağlantı formu |
| `src/lib` | Mimari/teknoloji kataloğu, değerlendirme kuralları, ZIP üretimi |
| `public/architectures` | Sunumdan alınan gerçek çizimler |
| `server` | Bağımsız Node HTTP API ve sağlayıcı adapter'ı |
| `tests` | BYOK güvenlik sınırları ve HTTP API kontrolleri |
| `scripts` | Geliştirme sunucuları ve domain kontrolleri |

Marka görselleri ve sunum içerikleri Komtaş çalışma içeriğidir; bu proje genel bir açık kaynak lisansı atamaz. Kullanılan üçüncü taraf paket ve logoların kendi lisans/marka koşulları geçerlidir.

## Ortak senaryo ve deney

Ortak iş senaryosu menüsü ve her referans mimarideki Senaryo & deney sekmesi aynı iş sorusunu, beklenen sonuçları ve kapsam sınırlarını gösterir. RM1 ZIP'i DENEY.md, Run-Scenario.ps1 ve üç iş SQL sorgusu içerir. Script pod içindeki psql ile SET ROLE rm1_bi kullanır; yerel psql gerektirmez. Hedef Kubernetes uçtan uca testi henüz yapılmadı.


RM1 ZIP artık Windows PowerShell ve Linux Bash scriptlerini birlikte içerir. Kurulum ekranında ve Bileşenler & kurulum sekmesinde ZIP sonrası adımlar gösterilir: önce Deploy / deploy.sh, sonra Run-Scenario / run-scenario.sh. Linux profili Docker Desktop Kubernetes, kubectl, Bash ve OpenSSL gerektirir; Power BI Desktop Windows'ta kalır. Ayrıntılar paket içindeki KURULUM.md dosyasındadır.


## Deney raporu ve ortam kaldırma

RM1 Run-Scenario artık reports/run-… altında çevrimdışı HTML raporu, sonuc.json ve kanıt dosyaları üretir. JSON, uygulamanın ortak senaryo veya RM1 Senaryo & deney bölümünden içe aktarılır. Tasarım puanı ile deney kontrolleri ayrı gösterilir; Power BI otomatik doğrulanmaz. Windows Remove-Environment.ps1 ve Linux remove-environment.sh lab sahiplik etiketi ve yazılı namespace onayıyla ortamı kaldırır. Stop veriyi koruyarak durdurur. Rapor üretimi ve silme akışı simüle kubectl ile test edildi; gerçek cluster üzerinde bu yeni adımlar henüz çalıştırılmadı.

## Deney rehberi

Sol menüde Deney rehberi (#guide) mimari seçimi → paket → kurulum/deney → HTML raporu → JSON içe aktarımı → karşılaştırma akışını görsel olarak anlatır. Kurulum modalında rapor.html, sonuc.json ve kanitlar için görünür adımlar ve ilgili bölüme geçiş düğmeleri bulunur. Rehber aynı kurulum bileşenini kullanır; komutlar iki yerde birlikte güncellenir.

## Referans Mimari 2

RM2 için Kurulum paketini hazırla ZIP üretir. Namespace komtas-rm2 ve port 15433 varsayılandır. packages/rm2 kaynakları build/test öncesi otomatik olarak paket şablonuna aktarılır. PostgreSQL kaynak veriyi saklar; Kubernetes Job içinde dbt-core 1.9.10 ve dbt-postgres 1.9.1 yedi model ve on iki veri testi çalıştırır. İlk Job çalışmasında PyPI internet erişimi gerekir. Manifest, build_results, katalog ve statik dbt dokümanı rapor kanıtlarına alınır. Ortak semantic API ve merkezi governance kapsam dışında kalır. Windows/Linux lifecycle scriptleri ve isteğe bağlı bozuk ürün anahtarı deneyi KURULUM.md içinde açıklanır.

## Tasarım ve bileşen erişimi

Ana ekran Komtaş renklerinde yeniden düzenlendi; mimari haritası önceliklidir. Hazır RM1/RM2 paketlerine hızlı geçiş, okunaklı kartlar, mobil görünüm ve kurulum/rapor stilleri güncellendi. Deploy sonunda Show-Access ile PostgreSQL bağlantısı ve Power BI veri alma adımları gösterilir. RM2 dbt dokümanı ClusterIP servisi ve yalnız localhost port-forward üzerinden açılır: Connect-Docs.ps1 / connect-docs.sh. dbt Core yönetim UI olarak sunulmaz. Seçilen PostgreSQL portuna göre doküman portu türetilir. Var olan RM2 ortamına docs servisini eklemek için güncel paketle Deploy tekrar çalıştırılır.

## Mimari üzerindeki ürün logoları

Seçili referans mimari ve özel taslak çizimlerinde aktif rol kutuları ürün logolarıyla gösterilir. Kullanılmayan alanlarda logo görünmez. Teknoloji anahtarı her mimarinin seçili bileşenlerinden üretilir. PostgreSQL, Power BI, dbt, OpenMetadata, Informatica, Cube, Trino, Neo4j, BigQuery, Snowflake, Databricks, Python ve Streamlit SVG varlıkları yerelde tutulur; kaynaklar docs/brand-assets.md içindedir. Tam kapsam kanonik görünüm teknoloji seçimi belirtmediği için rol çizimi olarak kalır.


## Komtaş değer haritası

Mimari çizimindeki Tümü / Data360 / Business360 / Agent360 odak seçicisi Data360, Business360 ve Agent360 yeteneklerini aynı rol modeli üzerinde gösterir. Strategy ve Governance kesen şeritlerdir. Katkı bir ürün adına göre otomatik tamamlanmış sayılmaz; mevcut profillerde Python/LLM erişimi Agent360 kanıtı değildir. Deney JSON'u yüklenince değer kartları gerçek kontrol durumlarını ayrı anlatır. Aynı hesaplama modülü RM1/RM2 çevrimdışı HTML raporlarına build/test öncesi eklenir. Kaynak çerçeve: Komtas_Salesforce_AI_Innovation_Day_11.11.2026.pptx, slayt 6–9. Eşleme laboratuvar yorumudur; yeni yüzde puanı yoktur.

PostgreSQL portu, Kubernetes içindeki 5432 portunu değiştirmez; localhost port-forward erişimini belirler. Bu ayar kurulum modalında Gelişmiş bağlantı ayarları altında varsayılanıyla sunulur. dbt doküman bağlantısı Connect-Docs tüneli açıkken erişilebilir; rehber bu iki adımı ayrı gösterir.

Ana kanonik mimari, canonical-roles.json üzerinden üretilen vendor agnostic SVG kullanır. Genel mimaride ürün veya vendor adı bulunmaz; ürün isimleri ve logoları yalnız seçili referans mimarilerde ve kullanıcı taslaklarında gösterilir.

Mimari gösterimi artık tektir: üstte Tümü / Data360 / Business360 / Agent360 odak filtresi, kutularda kalıcı yetenek etiketleri ve tüm mimariyi kesen Strategy/Governance şeritleri bulunur. Birden fazla alana ait roller iki etiket taşır. Etiketler rol alanını belirtir, kurulum veya deney doğrulaması iddiası değildir. Arayüz Komtaş turuncusu, beyaz/açık gri zemin ve koyu nötr menüyle düzenlenmiştir.

## Referans Mimari 3 · yerel MetricFlow

RM3 paketinde dbt Core 1.10.15, dbt-postgres 1.9.1, dbt-metricflow 0.11.0 ve MetricFlow 0.209.0 birlikte sabittir. SQL modellerinin üstüne metrik YAML tanımı eklenir. Yerel CLI sorgusu, explain SQL ve altı ay/kanal satırının gelir/litre/oran eşleşmesi raporlanır. Yönetilen metric API veya hazır Power BI bağlantısı kurulmaz; S2 kısmi puanı korunur. Set-MetricFault ile brüt/net tanım hatası, dbt testleri geçerken semantik karşılaştırmanın başarısız olması üzerinden gösterilir. Kurulum, erişim ve kaldırma akışı RM1/RM2 ile aynıdır.

RM4: PostgreSQL + dbt Core + authenticated Cube Core REST service + Cube Store + Streamlit/Python consumers. Lifecycle scripts, SQL/API reference checks and offline HTML/JSON evidence are included under packages/rm4. See VALIDATION.md for measured scope.

RM5: OpenMetadata governance extension with PostgreSQL metadata, dbt manifest lineage, business terms, metric ownership, SQL quality results and demo data-product registration. Includes an ownership fault experiment and independent governance evidence. See packages/rm5/VALIDATION.md.

## Referans Mimari 7 — harici Informatica CDGC

Yerel PostgreSQL, dbt Core, Cube Core/Store ve Streamlit/Python paketi hazır. CDGC dış org/JWT ve gerçek varlık eşlemesi ister; yerel Docker servisi olarak kurulmaz. Yedi bağımsız governance kontrolü, erişim yokken denenmedi kalır. Published insan onayı değildir; manuel workflow kaydının sürüm/tarih tutarlılığı ayrıca ölçülür. Kurulum, erişim, rapor ve silme adımları: packages/rm7/README.md.

## Referans Mimari 8 — CDGC ve OpenMetadata

RM8 yerel teknik katalog/lineage/SQL kalite kanıtını CDGC iş bağlamından ayırır. Açık CDGC → yerel OM iş tanımı kopyası, kimlik/hesap/owner eşlemesi ve kaynak sürümü kontrolü içerir. Dış erişim yoksa 11 kontrol denenmedi kalır. Kurulum ve sınırlar: packages/rm8/README.md.

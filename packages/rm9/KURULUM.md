# RM9 kurulum akışı

## Kurulum ve deney

Docker Desktop Linux containers, etkin Kubernetes, `kubectl`, `docker-desktop` context’i ve varsayılan StorageClass gerekir. Linux: Bash/OpenSSL. İmaj ve PyPI indirmeleri için internet gerekir; yerel dbt/Python kurulmaz. İki iş PostgreSQL’i, katalog metadata PostgreSQL’i, Elasticsearch ve Trino birlikte bellek tüketir; Docker kaynaklarını kontrol edin.

ZIP’i çıkarın ve `rm9-kubernetes` klasöründe terminal açın:

| İşlem | Windows PowerShell | Linux Bash |
|---|---|---|
| Kur | `.\Deploy.ps1` | `bash deploy.sh` |
| Deneyi çalıştır | `.\Run-Scenario.ps1` | `bash run-scenario.sh` |
| Modelleri yeniden kur | `.\Build-Models.ps1` | `bash build-models.sh` |
| Katalog güncelle | `.\Sync-Catalog.ps1` | `bash sync-catalog.sh` |
| Erişim özeti | `.\Show-Access.ps1` | `bash show-access.sh` |
| Kaynağı boz | `.\Break-Reference.ps1` | `bash break-reference.sh` |
| Kaynağı düzelt | `.\Restore-Reference.ps1` | `bash restore-reference.sh` |
| Kaynakları durdur | `.\Stop.ps1` | `bash stop.sh` |
| Tamamen sil | `.\Remove-Environment.ps1` | `bash remove-environment.sh` |

Her Run-Scenario yeni `reports/run-…` klasörüne `rapor.html`, `sonuc.json` ve `kanitlar/` üretir. HTML’i tarayıcıda açın; JSON’u uygulamadaki deney sonucuna yükleyin. Başarısız kontrol varsa rapor korunur ve script hata kodu döndürür. Önceki aşamadan kalan dosyalar yeni başarı sayılmaz.

PowerShell indirme imzası engelinde paket klasöründe `Get-ChildItem -LiteralPath . -Filter '*.ps1' -File | Unblock-File` çalıştırın. Kurumsal AllSigned politikası varsa imzalı script gerekir. Yönetici açmak tek başına imza sorununu çözmez.

## Erişim

Tek Connect komutu bütün yerel tünelleri açar; bu terminal açık kalmalıdır; tüm tüneller localhost’a bağlanır. Port doluysa ilgili Connect komutuna `-Port` veya Bash komutuna farklı port verin. Docker backend/WSL relay işlemini sonlandırmayın.

| Bileşen | Komut (Windows / Linux) | Varsayılan erişim |
|---|---|---|
| Satış PostgreSQL | Connect.ps1 / connect.sh | 127.0.0.1:15440; komtas_rm9; rm9_bi |
| Referans PostgreSQL | Connect.ps1 / connect.sh | 127.0.0.1:16440; komtas_rm9_reference; rm9_bi |
| Trino | Connect.ps1 / connect.sh | http://127.0.0.1:18099; JDBC jdbc:trino://127.0.0.1:18099/models/dwh; user rm9_reader |
| dbt dokümanı | Connect.ps1 / connect.sh | http://127.0.0.1:18089/static_index.html |
| Cube | Connect.ps1 / connect.sh | http://127.0.0.1:4009/cubejs-api/v1/meta; JWT gerekir |
| Streamlit | Connect.ps1 / connect.sh | http://127.0.0.1:8509 |
| OpenMetadata | Connect.ps1 / connect.sh | http://127.0.0.1:18589 |

PostgreSQL parolası: Get-Connections.ps1 / get-connections.sh (iki iş kaynağında aynı demo Secret). Katalog hesabı: Get-Connections.ps1 / get-connections.sh. Cube kısa ömürlü JWT: Get-ApiToken.ps1 / get-api-token.sh. Parolalar kurulumda yerel Secret olarak üretilir; pakette gerçek kimlik bilgisi yoktur. RM9’da Informatica veya Power BI kurulmaz/istenmez.


## Tek bağlantı oturumu

Kurulumdan sonra Windows `.\Connect.ps1`, Linux `bash connect.sh` bütün yerel servisleri tek terminalden bağlar. İkinci terminalde `.\Get-Connections.ps1` / `bash get-connections.sh` adresleri ve giriş bilgilerini toplu gösterir. Dolu port otomatik değiştirilir; gerçek adres için bu özeti kullanın. Ctrl+C bu oturumun bütün tünellerini kapatır. Ayrıntılar: BAGLANTILAR.md.

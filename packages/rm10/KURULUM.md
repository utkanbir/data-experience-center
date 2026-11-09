# RM10 kurulum

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


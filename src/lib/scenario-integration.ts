export const scenarioIntegration:Record<number,{state:string;detail:string}>={
  "1": {
    "state": "Akışta",
    "detail": "PostgreSQL → Power BI kullanıcı akışının parçası. Power BI hazırlığı ve görsel analizi manuel; otomatik uçtan uca BI testi yok."
  },
  "2": {
    "state": "Akışta",
    "detail": "dbt modelleri Power BI’ın kullandığı PostgreSQL verisini hazırlar. Power BI ölçüleri yereldir; ortak metrik servisi yok."
  },
  "3": {
    "state": "Akışta",
    "detail": "CLI/Python MetricFlow’dan üretilen SQL’i PostgreSQL’de çalıştırır. Yönetilen semantic servis veya BI dashboard entegrasyonu yok."
  },
  "4": {
    "state": "Akışta",
    "detail": "Streamlit/Python → Cube → dbt/PostgreSQL gerçek hesap yoludur. Katalog ve kurumsal iş bağlamı yok."
  },
  "5": {
    "state": "Kısmi entegrasyon",
    "detail": "OpenMetadata ingestion/lineage/kalite kontrollerinde kullanılıyor. Mevcut dashboard katalogdan metrik keşfetmiyor; OpenMetadata kapalıyken Cube hesabı sürebilir. Kullanıcı akışına katalog seçimi eklenmeli."
  },
  "6": {
    "state": "Koşullu dış akış",
    "detail": "Gerçek yönetilen dbt API yolu dış erişim sağlanınca kullanılıyor. Yerel-only sonuç bu yolun yerine geçmez. Power BI CSV kanıtı manuel, kesintisiz connector deneyimi olarak sunulmamalı."
  },
  "7": {
    "state": "Katalogdan analize",
    "detail": "Yeni dashboard gerçek CDGC kaydını seçtirir, iş tanımı/sahiplik/yayın/kaynak bağını yeniden doğrular ve yalnız eşlenmiş Cube metriğini çağırır. Bu uygulama politikasıdır; insan onayı/sertifika veya doğrudan Cube erişim kontrolü değildir. Eski kontrol raporu bu yeni akışın otomatik kanıtı sayılmaz."
  },
  "8": {
    "state": "Kısmi entegrasyon",
    "detail": "CDGC → OpenMetadata tek yönlü iş tanımı senkronizasyonu mevcut. Dashboard hâlâ Cube’a doğrudan gidiyor; iki kataloğun katkısı aynı kullanıcı akışında gösterilmiyor. RM7 yaklaşımının iki kataloglu karşılığı geliştirilmeli."
  },
  "9": {
    "state": "Kısmi entegrasyon",
    "detail": "Trino iki fiziksel PostgreSQL’i gerçek Cube sorgusunda birleştiriyor; federasyon hesap yolunun parçası. OpenMetadata ise ayrı katalog/kontrol akışı; dashboard için zorunlu değil."
  },
  "10": {
    "state": "Kısmi entegrasyon",
    "detail": "Neo4j’ye gerçek kaynak verisi yükleniyor ve ayrı çok adımlı graph sorguları çalışıyor. Dashboard’daki metrik sonucu graph keşfine bağlı değil; metrikten müşteri/outlet/ürün bağlamına kullanıcı geçişi eklenmeli. OpenMetadata da ayrı akışta."
  }
};

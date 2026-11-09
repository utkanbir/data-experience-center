import json
import streamlit as st
from client import request
from catalog_flow import load_catalog, execute_selected

st.set_page_config(page_title='Komtaş RM7 — Katalogdan analize', layout='wide')
st.title('RM7 — Kurumsal tanımı seç, ortak hesapla analiz et')
st.caption('CDGC: keşif ve iş bağlamı → açık CDGC/Cube eşlemesi → Cube: hesap → dbt/PostgreSQL: veri')
st.write('HoReCa kanalında Şubat net geliri Ocak’a göre nasıl değişti? Hangi tanım, sorumlu ve teknik kaynak kullanılıyor?')
st.info('Uygulama politikası yayımlanmış tanım, sahiplik ve kabul edilmiş kaynak bağını gerektirir. Published insan onayı veya sertifika değildir. Bu, Cube’un yerleşik CDGC özelliği değildir; doğrudan Cube API erişimi bu politikayı uygulamaz.')
if st.button('Kataloğu yeniden oku'):
    st.rerun()
try:
    entries = load_catalog()
except Exception:
    st.error('Kurumsal katalog okunamadı. CDGC erişimini, JWT süresini, eşlemeleri ve bağlantı modunu kontrol et. Cube sorgulanmadı; eski katalogdan onaylı sonuç gösterilmez.')
    st.stop()
chosen = st.selectbox('Kurumsal katalogdan metrik seç', entries, format_func=lambda e: e['name'], index=None, placeholder='Önce gerçek CDGC kaydını seç')
if chosen:
    st.subheader(chosen['name'])
    st.write(chosen['description'])
    st.json({k: chosen[k] for k in ['assetId', 'metricId', 'ownerId', 'ownerRoleId', 'lifecycle', 'technicalExternalId', 'observedAt']})
    if chosen['reasons']:
        st.warning('Bu kayıt henüz uygulamanın sorgulama koşullarını sağlamıyor.')
        for reason in chosen['reasons']:
            st.write('• '+reason)
    if st.button('Seçili tanımla HoReCa analizini çalıştır', disabled=not chosen['queryable']):
        try:
            result = execute_selected(chosen['assetId'], chosen['metricId'], load_catalog, request)
            st.success('Katalog tekrar doğrulandı; seçilen kayda eşlenmiş Cube metriği sorgulandı.')
            st.dataframe(result['data'], use_container_width=True)
            st.bar_chart([{'Ay': row['Sales.month'], 'Değer': float(row[chosen['metricId']])} for row in result['data']], x='Ay', y='Değer')
            st.download_button('Akış kanıtını indir', json.dumps(result, ensure_ascii=False, indent=2), 'catalog-analysis.json', 'application/json')
            st.caption('Aylık sonuçlar sayısal değişimi gösterir; neden-sonuç veya otomatik kök neden analizi değildir. Sahiplik kimlikleri gerçek CDGC API yanıtından gelir.')
        except Exception:
            st.error('Güncel katalog doğrulaması veya Cube sorgusu başarısız. Eski sonuç geçerli sayılmadı; bağlantı ve eşlemeleri kontrol et.')

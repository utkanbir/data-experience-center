import streamlit as st
from client import run_query
def fetch_rows():return run_query()
st.set_page_config(page_title='Komtaş RM9 · Ortak metrik servisi',layout='wide')
st.title('RM9 · Aynı metrik, ortak servis')
st.caption('PostgreSQL → dbt Core → Cube REST API → Streamlit / Python')
if st.button('API’den yeniden sorgula'):st.rerun()
try:
    rows=fetch_rows()
    st.dataframe(rows,use_container_width=True)
    horeca=[x for x in rows if x['Sales.channel']=='HoReCa']
    st.bar_chart({'Ay':[x['Sales.month'] for x in horeca],'Net gelir (EUR)':[float(x['Sales.netRevenue']) for x in horeca]},x='Ay',y='Net gelir (EUR)')
    st.write('Net gelir = brüt − iskonto − iade. Hesap Cube modelinde; bu ekran hesap formülü içermez.')
    st.code('cube/schema/Sales.js → consumers/query.json → /cubejs-api/v1/load')
except Exception:
    st.error('Cube API sorgulanamadı. Cube servisini, dbt modellerini ve Job loglarını kontrol et.')

cube('Sales', {
  sql: `SELECT * FROM models.dwh.v_sales_detail`,
  refreshKey: {sql: `SELECT CAST(uuid() AS VARCHAR)`},
  measures: {
    netRevenue: {sql: `gross_revenue_eur - discount_amount_eur - return_amount_eur`, type: 'sum', title: 'Net gelir (EUR)'},
    netLiters: {sql: `net_volume_liters`, type: 'sum', title: 'Net hacim (litre)'},
    averagePrice: {sql: `${netRevenue} / NULLIF(CAST(${netLiters} AS DOUBLE), 0)`, type: 'number', title: 'Ortalama fiyat (EUR/litre)'}
  },
  dimensions: {
    id: {sql: `sales_line_key`, type: 'number', primaryKey: true},
    month: {sql: `CAST(month_start AS VARCHAR)`, type: 'string'},
    channel: {sql: `channel`, type: 'string'},
    country: {sql: `country`, type: 'string'}
  }
});

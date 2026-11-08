cube('Sales', {
  sql: `SELECT * FROM dwh.v_sales_detail`,
  measures: {
    netRevenue: {sql: `gross_revenue_eur - discount_amount_eur - return_amount_eur`, type: 'sum', title: 'Net gelir (EUR)'},
    netLiters: {sql: `net_volume_liters`, type: 'sum', title: 'Net hacim (litre)'},
    averagePrice: {sql: `${netRevenue} / NULLIF(${netLiters}, 0)`, type: 'number', title: 'Ortalama fiyat (EUR/litre)'}
  },
  dimensions: {
    id: {sql: `sales_line_key`, type: 'number', primaryKey: true},
    month: {sql: `to_char(month_start, 'YYYY-MM-DD')`, type: 'string'},
    channel: {sql: `channel`, type: 'string'},
    country: {sql: `country`, type: 'string'}
  }
});

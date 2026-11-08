SELECT month_start, country, channel,
       sum(gross_revenue_eur-discount_amount_eur-return_amount_eur) AS net_revenue_eur,
       sum(net_volume_liters) AS net_liters,
       round(sum(gross_revenue_eur-discount_amount_eur-return_amount_eur)/nullif(sum(net_volume_liters),0),6) AS average_price_eur_per_liter
FROM dwh.v_sales_detail
GROUP BY month_start,country,channel ORDER BY country,channel,month_start;

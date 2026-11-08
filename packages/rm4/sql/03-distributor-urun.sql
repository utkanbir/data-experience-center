SELECT month_start,country,distributor_name,product_name,
 sum(gross_revenue_eur-discount_amount_eur-return_amount_eur) AS net_revenue_eur,
 sum(net_volume_liters) AS net_liters
FROM dwh.v_sales_detail WHERE channel='HoReCa'
GROUP BY month_start,country,distributor_name,product_name
ORDER BY country,distributor_name,product_name,month_start;

WITH monthly AS (
 SELECT month_start,sum(gross_revenue_eur-discount_amount_eur-return_amount_eur) AS revenue,sum(net_volume_liters) AS liters
 FROM dwh.v_sales_detail WHERE channel='HoReCa' GROUP BY month_start
), paired AS (
 SELECT *,lag(revenue) OVER(ORDER BY month_start) AS prior_revenue,lag(liters) OVER(ORDER BY month_start) AS prior_liters FROM monthly
)
SELECT month_start,revenue,liters,round(revenue/nullif(liters,0),6) AS price_per_liter,
 revenue-prior_revenue AS revenue_change,round(100*(revenue-prior_revenue)/nullif(prior_revenue,0),2) AS change_pct,
 round((liters-prior_liters)*(prior_revenue/nullif(prior_liters,0)),2) AS volume_effect_eur,
 round(liters*(revenue/nullif(liters,0)-prior_revenue/nullif(prior_liters,0)),2) AS price_effect_eur
FROM paired ORDER BY month_start;

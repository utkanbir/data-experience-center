WITH totals AS (
 SELECT month_start,channel,sum(gross_revenue_eur-discount_amount_eur-return_amount_eur) AS revenue,sum(net_volume_liters) AS liters
 FROM dwh.v_sales_detail GROUP BY month_start,channel
), h AS (
 SELECT max(revenue) FILTER(WHERE month_start=date '2025-01-01') AS jan,
 max(revenue) FILTER(WHERE month_start=date '2025-02-01') AS feb,
 max(liters) FILTER(WHERE month_start=date '2025-01-01') AS jan_liters,
 max(liters) FILTER(WHERE month_start=date '2025-02-01') AS feb_liters FROM totals WHERE channel='HoReCa'
), checks AS (
 SELECT 'schemas' AS id, (SELECT count(*)=2 FROM pg_namespace WHERE nspname IN ('raw','dwh')) AS passed
 UNION ALL SELECT 'rows',(SELECT count(*)=2016 FROM dwh.fact_sales)
 UNION ALL SELECT 'months',(SELECT sum(revenue) FILTER(WHERE month_start=date '2025-01-01')=27820.80 AND sum(revenue) FILTER(WHERE month_start=date '2025-02-01')=23284.80 FROM totals)
 UNION ALL SELECT 'horeca',jan=8164.80 AND feb=3628.80 FROM h
 UNION ALL SELECT 'volume',jan_liters=1844.640 AND feb_liters=819.840 FROM h
 UNION ALL SELECT 'price',abs(jan/nullif(jan_liters,0)-feb/nullif(feb_liters,0))<0.000001 AND feb-jan=-4536.00 FROM h
 UNION ALL SELECT 'dbt_models',CASE WHEN '__DBT_MODELS__'='not_tested' THEN NULL ELSE '__DBT_MODELS__'='passed' END
 UNION ALL SELECT 'dbt_tests',CASE WHEN '__DBT_TESTS__'='not_tested' THEN NULL ELSE '__DBT_TESTS__'='passed' END
 UNION ALL SELECT 'dbt_docs',CASE WHEN '__DBT_DOCS__'='not_tested' THEN NULL ELSE '__DBT_DOCS__'='passed' END
 UNION ALL SELECT 'bi_role',current_user='rm2_bi'
 UNION ALL SELECT 'no_insert',NOT has_table_privilege(current_user,'dwh.fact_sales','INSERT')
)
SELECT json_build_object('checks',(SELECT json_agg(json_build_object('id',id,'status',CASE WHEN passed IS NULL THEN 'not_tested' WHEN passed IS TRUE THEN 'passed' ELSE 'failed' END)) FROM checks),
 'metrics',(SELECT json_build_object('janRevenue',jan,'febRevenue',feb,'janLiters',jan_liters,'febLiters',feb_liters,'change',feb-jan) FROM h));

{{ config(materialized='view') }}
select f.*,d.month_start,o.country,o.channel,o.distributor_key,o.distributor_name,o.outlet_name,
 p.product_name,p.category,r.promotion_name
from {{ ref('fact_sales') }} f join {{ ref('dim_date') }} d ON f.date_key=d.date_key
join {{ ref('dim_outlet') }} o ON f.outlet_key=o.outlet_key
join {{ ref('dim_product') }} p ON f.product_key=p.product_key
join {{ ref('dim_promotion') }} r ON f.promotion_key=r.promotion_key

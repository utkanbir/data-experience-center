{{ config(materialized='view') }}
select f.*,d.month_start,o.country,o.channel,o.distributor_key,o.distributor_name,o.outlet_name,
 p.product_name,p.category,r.promotion_name
from {{ ref('fact_sales') }} f join {{ ref('dim_date') }} d using(date_key)
join {{ ref('dim_outlet') }} o using(outlet_key)
join {{ ref('dim_product') }} p using(product_key)
join {{ ref('dim_promotion') }} r using(promotion_key)

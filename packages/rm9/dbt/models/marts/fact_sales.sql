select s.sales_line_key,s.sale_date as date_key,s.outlet_key,s.product_key,s.promotion_key,
 s.sold_units,s.returned_units,
 s.sold_units*s.unit_price_eur as gross_revenue_eur,
 s.sold_units*s.unit_price_eur*s.discount_rate as discount_amount_eur,
 s.returned_units*s.unit_price_eur*(1-s.discount_rate) as return_amount_eur,
 (s.sold_units-s.returned_units)*p.liters_per_unit as net_volume_liters,
 s.source_reference
from {{ ref('stg_sales') }} s join {{ ref('dim_product') }} p ON s.product_key=p.product_key

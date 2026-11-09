select * from {{ source('raw', 'dim_product') }}

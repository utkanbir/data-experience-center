select * from {{ source('raw', 'sales_line') }}

select * from {{ source('sales', 'sales_line') }}

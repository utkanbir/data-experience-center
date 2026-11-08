UPDATE raw.sales_line SET product_key=(sales_line_key % 10)::integer WHERE product_key=999999;

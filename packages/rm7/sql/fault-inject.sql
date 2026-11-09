UPDATE raw.sales_line SET product_key=999999 WHERE sales_line_key=(SELECT min(sales_line_key) FROM raw.sales_line);

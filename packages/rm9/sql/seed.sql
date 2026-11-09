\getenv bi_password PBI_PASSWORD
\getenv dbt_password DBT_PASSWORD
BEGIN;
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS dwh;
CREATE TABLE IF NOT EXISTS raw.sales_line (
    sales_line_key bigint PRIMARY KEY,
    sale_date date NOT NULL,
    outlet_key integer NOT NULL,
    product_key integer NOT NULL,
    promotion_key integer NOT NULL,
    sold_units integer NOT NULL CHECK (sold_units > 0),
    returned_units integer NOT NULL CHECK (returned_units BETWEEN 0 AND sold_units),
    unit_price_eur numeric(12,2) NOT NULL,
    discount_rate numeric(5,4) NOT NULL,
    source_reference text NOT NULL
);
INSERT INTO raw.sales_line
WITH dates AS (SELECT d::date AS date_key,extract(month FROM d)::integer AS month_number FROM generate_series(timestamp '2025-01-01',timestamp '2025-02-28',interval '1 day') d), outlets AS (SELECT n AS outlet_key,(ARRAY['HoReCa','Retail','Online'])[1+(n-1)%3] AS channel FROM generate_series(1,12) n), products AS (SELECT generate_series(1,3) AS product_key)
SELECT ((d.date_key-date '2025-01-01')*1000+o.outlet_key*10+p.product_key)::bigint,
       d.date_key,o.outlet_key,p.product_key,
       CASE o.channel WHEN 'HoReCa' THEN 1 WHEN 'Retail' THEN 2 ELSE 0 END,
       CASE WHEN o.channel='HoReCa' AND d.month_number=2 THEN 6 ELSE 10 END,
       CASE WHEN o.channel='HoReCa' THEN CASE WHEN d.month_number=2 THEN 2 ELSE 1 END ELSE 0 END,
       (p.product_key+1)::numeric,
       CASE o.channel WHEN 'HoReCa' THEN 0.10 WHEN 'Retail' THEN 0.05 ELSE 0 END,
       'SYNTH-RM9-'||d.date_key||'-'||o.outlet_key||'-'||p.product_key
FROM dates d CROSS JOIN outlets o CROSS JOIN products p
WHERE extract(day FROM d.date_key)<=28
ON CONFLICT DO NOTHING;
SELECT format('CREATE ROLE rm9_bi LOGIN PASSWORD %L', :'bi_password') WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rm9_bi')
\gexec
SELECT format('ALTER ROLE rm9_bi PASSWORD %L', :'bi_password')
\gexec
SELECT format('CREATE ROLE rm9_dbt LOGIN PASSWORD %L', :'dbt_password') WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rm9_dbt')
\gexec
SELECT format('ALTER ROLE rm9_dbt PASSWORD %L', :'dbt_password')
\gexec
ALTER ROLE rm9_bi SET default_transaction_read_only=on;
GRANT CONNECT ON DATABASE komtas_rm9 TO rm9_bi,rm9_dbt;
GRANT USAGE ON SCHEMA raw TO rm9_dbt;
GRANT SELECT ON ALL TABLES IN SCHEMA raw TO rm9_dbt;
GRANT USAGE,CREATE ON SCHEMA dwh TO rm9_dbt;
GRANT USAGE ON SCHEMA dwh,raw TO rm9_bi;
GRANT SELECT ON ALL TABLES IN SCHEMA raw TO rm9_bi;
ALTER DEFAULT PRIVILEGES FOR ROLE rm9_dbt IN SCHEMA dwh GRANT SELECT ON TABLES TO rm9_bi;
COMMIT;
SELECT count(*) FROM raw.sales_line;

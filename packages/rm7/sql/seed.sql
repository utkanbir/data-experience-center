\getenv bi_password PBI_PASSWORD
\getenv dbt_password DBT_PASSWORD
BEGIN;
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS dwh;
CREATE TABLE IF NOT EXISTS raw.dim_date (
    date_key date PRIMARY KEY,
    year_number integer NOT NULL,
    month_number integer NOT NULL,
    month_start date NOT NULL
);
CREATE TABLE IF NOT EXISTS raw.dim_product (
    product_key integer PRIMARY KEY,
    product_name text NOT NULL,
    category text NOT NULL,
    liters_per_unit numeric(8,3) NOT NULL CHECK (liters_per_unit > 0)
);
CREATE TABLE IF NOT EXISTS raw.dim_outlet (
    outlet_key integer PRIMARY KEY,
    outlet_name text NOT NULL,
    country text NOT NULL,
    channel text NOT NULL,
    distributor_key integer NOT NULL,
    distributor_name text NOT NULL
);
CREATE TABLE IF NOT EXISTS raw.dim_promotion (
    promotion_key integer PRIMARY KEY,
    promotion_name text NOT NULL
);
INSERT INTO raw.dim_date
SELECT d::date, 2025, extract(month FROM d)::integer, date_trunc('month',d)::date
FROM generate_series(timestamp '2025-01-01',timestamp '2025-02-28',interval '1 day') d
ON CONFLICT DO NOTHING;
INSERT INTO raw.dim_product VALUES
(1,'Sparkling Water 1L','Water',1.000),
(2,'Juice 500ml','Juice',0.500),
(3,'Soft Drink 330ml','Soft Drink',0.330)
ON CONFLICT DO NOTHING;
INSERT INTO raw.dim_outlet
SELECT n, 'Outlet '||n,
       CASE WHEN n <= 6 THEN 'TR' ELSE 'DE' END,
       (ARRAY['HoReCa','Retail','Online'])[1+(n-1)%3],
       1+(n-1)/3, 'Distributor '||(1+(n-1)/3)
FROM generate_series(1,12) n
ON CONFLICT DO NOTHING;
INSERT INTO raw.dim_promotion VALUES
(0,'No promotion'),(1,'HoReCa 10 percent'),(2,'Retail 5 percent')
ON CONFLICT DO NOTHING;
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
SELECT ((d.date_key-date '2025-01-01')*1000+o.outlet_key*10+p.product_key)::bigint,
       d.date_key,o.outlet_key,p.product_key,
       CASE o.channel WHEN 'HoReCa' THEN 1 WHEN 'Retail' THEN 2 ELSE 0 END,
       CASE WHEN o.channel='HoReCa' AND d.month_number=2 THEN 6 ELSE 10 END,
       CASE WHEN o.channel='HoReCa' THEN CASE WHEN d.month_number=2 THEN 2 ELSE 1 END ELSE 0 END,
       (p.product_key+1)::numeric,
       CASE o.channel WHEN 'HoReCa' THEN 0.10 WHEN 'Retail' THEN 0.05 ELSE 0 END,
       'SYNTH-RM7-'||d.date_key||'-'||o.outlet_key||'-'||p.product_key
FROM raw.dim_date d CROSS JOIN raw.dim_outlet o CROSS JOIN raw.dim_product p
WHERE extract(day FROM d.date_key)<=28
ON CONFLICT DO NOTHING;
SELECT format('CREATE ROLE rm7_bi LOGIN PASSWORD %L', :'bi_password') WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rm7_bi')
\gexec
SELECT format('ALTER ROLE rm7_bi PASSWORD %L', :'bi_password')
\gexec
SELECT format('CREATE ROLE rm7_dbt LOGIN PASSWORD %L', :'dbt_password') WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rm7_dbt')
\gexec
SELECT format('ALTER ROLE rm7_dbt PASSWORD %L', :'dbt_password')
\gexec
ALTER ROLE rm7_bi SET default_transaction_read_only=on;
GRANT CONNECT ON DATABASE komtas_rm7 TO rm7_bi,rm7_dbt;
GRANT USAGE ON SCHEMA raw TO rm7_dbt;
GRANT SELECT ON ALL TABLES IN SCHEMA raw TO rm7_dbt;
GRANT USAGE,CREATE ON SCHEMA dwh TO rm7_dbt;
GRANT USAGE ON SCHEMA dwh TO rm7_bi;
ALTER DEFAULT PRIVILEGES FOR ROLE rm7_dbt IN SCHEMA dwh GRANT SELECT ON TABLES TO rm7_bi;
COMMIT;
SELECT 'RM7 raw seed complete' AS status,count(*) AS rows FROM raw.sales_line;

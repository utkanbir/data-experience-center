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
SELECT format('CREATE ROLE rm9_bi LOGIN PASSWORD %L', :'bi_password') WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rm9_bi')
\gexec
SELECT format('ALTER ROLE rm9_bi PASSWORD %L', :'bi_password')
\gexec
SELECT format('CREATE ROLE rm9_dbt LOGIN PASSWORD %L', :'dbt_password') WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rm9_dbt')
\gexec
SELECT format('ALTER ROLE rm9_dbt PASSWORD %L', :'dbt_password')
\gexec
ALTER ROLE rm9_bi SET default_transaction_read_only=on;
GRANT CONNECT ON DATABASE komtas_rm9_reference TO rm9_bi,rm9_dbt;
GRANT USAGE ON SCHEMA raw TO rm9_dbt;
GRANT SELECT ON ALL TABLES IN SCHEMA raw TO rm9_dbt;
GRANT USAGE,CREATE ON SCHEMA dwh TO rm9_dbt;
GRANT USAGE ON SCHEMA dwh,raw TO rm9_bi;
GRANT SELECT ON ALL TABLES IN SCHEMA raw TO rm9_bi;
ALTER DEFAULT PRIVILEGES FOR ROLE rm9_dbt IN SCHEMA dwh GRANT SELECT ON TABLES TO rm9_bi;
COMMIT;
SELECT count(*) FROM raw.dim_outlet;

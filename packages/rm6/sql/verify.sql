\pset pager off
BEGIN READ ONLY;
DO $$
DECLARE
    actual numeric;
BEGIN
    SELECT count(*) INTO actual FROM dwh.fact_sales;
    IF actual<>2016 THEN RAISE EXCEPTION 'Expected 2016 fact rows, got %',actual; END IF;
    SELECT sum(gross_revenue_eur-discount_amount_eur-return_amount_eur) INTO actual
    FROM dwh.v_sales_detail WHERE month_start=date '2025-01-01';
    IF actual<>27820.80 THEN RAISE EXCEPTION 'January revenue mismatch: %',actual; END IF;
    SELECT sum(gross_revenue_eur-discount_amount_eur-return_amount_eur) INTO actual
    FROM dwh.v_sales_detail WHERE month_start=date '2025-02-01';
    IF actual<>23284.80 THEN RAISE EXCEPTION 'February revenue mismatch: %',actual; END IF;
    SELECT sum(gross_revenue_eur-discount_amount_eur-return_amount_eur) INTO actual
    FROM dwh.v_sales_detail WHERE month_start=date '2025-01-01' AND channel='HoReCa';
    IF actual<>8164.80 THEN RAISE EXCEPTION 'January HoReCa mismatch: %',actual; END IF;
    SELECT sum(gross_revenue_eur-discount_amount_eur-return_amount_eur) INTO actual
    FROM dwh.v_sales_detail WHERE month_start=date '2025-02-01' AND channel='HoReCa';
    IF actual<>3628.80 THEN RAISE EXCEPTION 'February HoReCa mismatch: %',actual; END IF;
    SELECT sum(net_volume_liters) INTO actual FROM dwh.v_sales_detail
    WHERE month_start=date '2025-02-01' AND channel='HoReCa';
    IF actual<>819.840 THEN RAISE EXCEPTION 'February HoReCa volume mismatch: %',actual; END IF;
    SELECT count(DISTINCT country) INTO actual FROM dwh.dim_outlet;
    IF actual<>2 THEN RAISE EXCEPTION 'Country count mismatch'; END IF;
    IF has_table_privilege(current_user,'dwh.fact_sales','INSERT') THEN
        RAISE EXCEPTION 'BI user must not have INSERT permission';
    END IF;
    RAISE NOTICE 'PASS: row counts, reference totals, volume and BI read-only access';
END $$;
SELECT month_start,channel,
       sum(gross_revenue_eur-discount_amount_eur-return_amount_eur) AS net_revenue_eur,
       sum(net_volume_liters) AS volume_liters,
       round(sum(gross_revenue_eur-discount_amount_eur-return_amount_eur)/nullif(sum(net_volume_liters),0),6) AS average_price_eur_per_liter,
       count(DISTINCT outlet_key) FILTER (WHERE sold_units>returned_units) AS active_outlets
FROM dwh.v_sales_detail
GROUP BY month_start,channel ORDER BY month_start,channel;
COMMIT;

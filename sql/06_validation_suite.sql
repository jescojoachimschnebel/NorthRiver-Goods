-- Datenbank: northriver_warehouse
-- Schema: public
-- Bereinigte Reviewfassung: 9. Oktober 2026
-- PostgreSQL; Schema und Datentypen vor Ausführung prüfen.
-- Nur synthetische Daten verwenden; Abfrageergebnisse nicht veröffentlichen.
-- Die Abschnitte einzeln ausführen.

-- NorthRiver Capstone
-- Validierung der fehlerhaften Übungstabellen

WITH pruefungen AS (
    SELECT 'null_customer_sk' AS pruefung, COUNT(*) AS fail_count
    FROM public.dq_fact_orders WHERE customer_sk IS NULL
    UNION ALL
    SELECT 'orphan_channel_sk', COUNT(*)
    FROM public.dq_fact_orders AS fo
    WHERE fo.channel_sk IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.dim_channel AS dc
        WHERE dc.channel_sk = fo.channel_sk
    )
    UNION ALL
    SELECT 'duplicate_customer_sk', COUNT(*)
    FROM (
        SELECT customer_sk FROM public.dq_dim_customer
        GROUP BY customer_sk HAVING COUNT(*) > 1
    ) AS doppelte_schluessel
)
SELECT pruefung, fail_count,
       CASE WHEN fail_count = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM pruefungen ORDER BY pruefung;


-- NorthRiver Capstone
-- Validierung des sauberen Star Schemas

WITH pruefungen AS (
    SELECT 'null_customer_sk' AS pruefung, COUNT(*) AS fail_count
    FROM public.fact_orders WHERE customer_sk IS NULL
    UNION ALL
    SELECT 'orphan_channel_sk', COUNT(*)
    FROM public.fact_orders AS fo
    WHERE fo.channel_sk IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.dim_channel AS dc
        WHERE dc.channel_sk = fo.channel_sk
    )
    UNION ALL
    SELECT 'duplicate_customer_sk', COUNT(*)
    FROM (
        SELECT customer_sk FROM public.dim_customer
        GROUP BY customer_sk HAVING COUNT(*) > 1
    ) AS doppelte_schluessel
)
SELECT pruefung, fail_count,
       CASE WHEN fail_count = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM pruefungen ORDER BY pruefung;

-- Zusätzliche Integritätsdiagnosen des Analyseschemas.
WITH pruefungen AS (
SELECT 'fact_orders_null_order_item_sk' AS pruefung, (SELECT COUNT(*) FROM public.fact_orders WHERE order_item_sk IS NULL) AS fail_count
UNION ALL
SELECT 'fact_orders_duplicate_order_item_sk' AS pruefung, (SELECT COUNT(*) FROM (SELECT order_item_sk FROM public.fact_orders GROUP BY order_item_sk HAVING COUNT(*) > 1) d) AS fail_count
UNION ALL
SELECT 'dim_customer_null_customer_sk' AS pruefung, (SELECT COUNT(*) FROM public.dim_customer WHERE customer_sk IS NULL) AS fail_count
UNION ALL
SELECT 'dim_customer_duplicate_customer_sk' AS pruefung, (SELECT COUNT(*) FROM (SELECT customer_sk FROM public.dim_customer GROUP BY customer_sk HAVING COUNT(*) > 1) d) AS fail_count
UNION ALL
SELECT 'dim_product_null_product_sk' AS pruefung, (SELECT COUNT(*) FROM public.dim_product WHERE product_sk IS NULL) AS fail_count
UNION ALL
SELECT 'dim_product_duplicate_product_sk' AS pruefung, (SELECT COUNT(*) FROM (SELECT product_sk FROM public.dim_product GROUP BY product_sk HAVING COUNT(*) > 1) d) AS fail_count
UNION ALL
SELECT 'dim_channel_null_channel_sk' AS pruefung, (SELECT COUNT(*) FROM public.dim_channel WHERE channel_sk IS NULL) AS fail_count
UNION ALL
SELECT 'dim_channel_duplicate_channel_sk' AS pruefung, (SELECT COUNT(*) FROM (SELECT channel_sk FROM public.dim_channel GROUP BY channel_sk HAVING COUNT(*) > 1) d) AS fail_count
UNION ALL
SELECT 'dim_date_null_date_sk' AS pruefung, (SELECT COUNT(*) FROM public.dim_date WHERE date_sk IS NULL) AS fail_count
UNION ALL
SELECT 'dim_date_duplicate_date_sk' AS pruefung, (SELECT COUNT(*) FROM (SELECT date_sk FROM public.dim_date GROUP BY date_sk HAVING COUNT(*) > 1) d) AS fail_count
UNION ALL
SELECT 'dim_user_null_user_sk' AS pruefung, (SELECT COUNT(*) FROM public.dim_user WHERE user_sk IS NULL) AS fail_count
UNION ALL
SELECT 'dim_user_duplicate_user_sk' AS pruefung, (SELECT COUNT(*) FROM (SELECT user_sk FROM public.dim_user GROUP BY user_sk HAVING COUNT(*) > 1) d) AS fail_count
UNION ALL
SELECT 'fact_orders_invalid_customer_sk' AS pruefung, (SELECT COUNT(*) FROM public.fact_orders f WHERE f.customer_sk IS NULL OR NOT EXISTS (SELECT 1 FROM public.dim_customer d WHERE d.customer_sk = f.customer_sk)) AS fail_count
UNION ALL
SELECT 'fact_orders_invalid_product_sk' AS pruefung, (SELECT COUNT(*) FROM public.fact_orders f WHERE f.product_sk IS NULL OR NOT EXISTS (SELECT 1 FROM public.dim_product d WHERE d.product_sk = f.product_sk)) AS fail_count
UNION ALL
SELECT 'fact_orders_invalid_channel_sk' AS pruefung, (SELECT COUNT(*) FROM public.fact_orders f WHERE f.channel_sk IS NULL OR NOT EXISTS (SELECT 1 FROM public.dim_channel d WHERE d.channel_sk = f.channel_sk)) AS fail_count
UNION ALL
SELECT 'fact_orders_invalid_date_sk' AS pruefung, (SELECT COUNT(*) FROM public.fact_orders f WHERE f.date_sk IS NULL OR NOT EXISTS (SELECT 1 FROM public.dim_date d WHERE d.date_sk = f.date_sk)) AS fail_count
UNION ALL
SELECT 'fact_events_invalid_user_sk' AS pruefung, (SELECT COUNT(*) FROM public.fact_events f WHERE f.user_sk IS NULL OR NOT EXISTS (SELECT 1 FROM public.dim_user d WHERE d.user_sk = f.user_sk)) AS fail_count
UNION ALL
SELECT 'orders_null_measures' AS pruefung, (SELECT COUNT(*) FROM public.fact_orders WHERE revenue IS NULL OR quantity IS NULL OR unit_price IS NULL) AS fail_count
UNION ALL
SELECT 'users_null_signup' AS pruefung, (SELECT COUNT(*) FROM public.dim_user WHERE signup_date IS NULL) AS fail_count
UNION ALL
SELECT 'events_null_fields' AS pruefung, (SELECT COUNT(*) FROM public.fact_events WHERE event_date IS NULL OR event_type IS NULL) AS fail_count
UNION ALL
SELECT 'events_before_signup' AS pruefung, (SELECT COUNT(*) FROM public.fact_events f JOIN public.dim_user d USING (user_sk) WHERE f.event_date < d.signup_date) AS fail_count
UNION ALL
SELECT 'inconsistent_order_dimensions' AS pruefung, (SELECT COUNT(*) FROM (SELECT order_id FROM public.fact_orders GROUP BY order_id HAVING COUNT(DISTINCT customer_sk)>1 OR COUNT(DISTINCT date_sk)>1 OR COUNT(DISTINCT channel_sk)>1) d) AS fail_count
)
SELECT *, CASE WHEN fail_count = 0 THEN 'PASS' ELSE 'FAIL' END AS status FROM pruefungen ORDER BY pruefung;

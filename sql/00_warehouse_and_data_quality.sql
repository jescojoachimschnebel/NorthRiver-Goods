-- Datenbank: northriver_warehouse
-- Schema: public
-- Bereinigte Reviewfassung: 9. Oktober 2026
-- PostgreSQL; Schema und Datentypen vor Ausführung prüfen.
-- Nur synthetische Daten verwenden; Abfrageergebnisse nicht veröffentlichen.
-- Die Abschnitte einzeln ausführen.

-- NorthRiver Capstone
-- Tabellen im Schema public

SELECT table_name AS tabelle
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;


-- NorthRiver Capstone
-- Granularität der Faktentabelle

SELECT COUNT(*) AS positionen,
       COUNT(DISTINCT order_item_sk) AS eindeutige_positions_ids,
       COUNT(DISTINCT order_id) AS bestellungen
FROM public.fact_orders;


-- NorthRiver Capstone
-- Produktverweise prüfen

SELECT COUNT(*) AS positionen_ohne_produkt
FROM public.fact_orders AS fo
WHERE NOT EXISTS (
    SELECT 1 FROM public.dim_product AS dp
    WHERE dp.product_sk = fo.product_sk
);


-- NorthRiver Capstone
-- Auswirkung fehlender Kunden und Channels

SELECT
    COUNT(*) FILTER (WHERE customer_sk IS NULL) AS null_customer_rows,
    SUM(revenue::numeric) FILTER (WHERE customer_sk IS NULL) AS revenue_ohne_kunde,
    COUNT(*) FILTER (WHERE channel_sk IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.dim_channel dc
        WHERE dc.channel_sk = dq_fact_orders.channel_sk)) AS orphan_channel_rows
FROM public.dq_fact_orders;


-- NorthRiver Capstone
-- Doppelte Kundenschlüssel finden

SELECT customer_sk, COUNT(*) AS dimensionszeilen
FROM public.dq_dim_customer
GROUP BY customer_sk
HAVING COUNT(*) > 1;


-- NorthRiver Capstone
-- Zeilenvermehrung beim Kunden Join

SELECT
    (SELECT COUNT(*) FROM public.dq_fact_orders
     WHERE customer_sk IS NOT NULL) AS positionen_mit_kundenschluessel,
    (SELECT COUNT(*) FROM public.dq_fact_orders AS fo
     INNER JOIN public.dq_dim_customer AS dc
       ON fo.customer_sk = dc.customer_sk) AS positionen_nach_join;


-- NorthRiver Capstone
-- Join mit eindeutigen Kundenschlüsseln

WITH eindeutige_kunden AS (
    SELECT DISTINCT customer_sk
    FROM public.dq_dim_customer
)
SELECT COUNT(*) AS positionen_nach_bereinigtem_join
FROM public.dq_fact_orders AS fo
INNER JOIN eindeutige_kunden AS dc ON fo.customer_sk = dc.customer_sk;


-- NorthRiver Capstone
-- Channel Treffer mit LEFT JOIN messen

SELECT COUNT(*) AS alle_positionen,
       COUNT(dc.channel_sk) AS positionen_mit_channel,
       COUNT(*) - COUNT(dc.channel_sk) AS positionen_ohne_channel
FROM public.dq_fact_orders AS fo
LEFT JOIN public.dim_channel AS dc ON fo.channel_sk = dc.channel_sk;


-- NorthRiver Capstone
-- Unbekannten Channel sichtbar halten

SELECT COALESCE(dc.channel_name, 'Unbekannter Channel') AS channel,
       COUNT(*) AS positionen, SUM(fo.revenue::numeric) AS umsatz
FROM public.dq_fact_orders AS fo
LEFT JOIN public.dim_channel AS dc ON fo.channel_sk = dc.channel_sk
GROUP BY COALESCE(dc.channel_name, 'Unbekannter Channel')
ORDER BY umsatz DESC;

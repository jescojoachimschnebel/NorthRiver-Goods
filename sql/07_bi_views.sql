-- Datenbank: northriver_warehouse
-- Schema: public
-- Bereinigte Reviewfassung: 9. Oktober 2026
-- PostgreSQL; Schema und Datentypen vor Ausführung prüfen.
-- Nur synthetische Daten verwenden; Abfrageergebnisse nicht veröffentlichen.
-- Die Abschnitte einzeln ausführen.

-- NorthRiver Capstone
-- View vw_order_details erstellen

CREATE OR REPLACE VIEW public.vw_order_details AS
SELECT fo.order_item_sk AS bestellposition_id, fo.order_id AS bestellung_id,
       dc.region, dc.segment, dp.category, dch.channel_name,
       dd.date AS bestelldatum, dd.year, dd.month,
       fo.quantity, fo.unit_price, fo.revenue
FROM public.fact_orders AS fo
LEFT JOIN public.dim_customer AS dc ON fo.customer_sk = dc.customer_sk
LEFT JOIN public.dim_product AS dp ON fo.product_sk = dp.product_sk
LEFT JOIN public.dim_channel AS dch ON fo.channel_sk = dch.channel_sk
LEFT JOIN public.dim_date AS dd ON fo.date_sk = dd.date_sk;


-- NorthRiver Capstone
-- View vw_region_month_summary erstellen

CREATE OR REPLACE VIEW public.vw_region_month_summary AS
SELECT region, EXTRACT(YEAR FROM bestelldatum)::integer AS year,
       EXTRACT(MONTH FROM bestelldatum)::integer AS month,
       SUM(revenue::numeric) AS total_revenue,
       COUNT(DISTINCT bestellung_id) AS orders
FROM public.vw_order_details
GROUP BY region, EXTRACT(YEAR FROM bestelldatum), EXTRACT(MONTH FROM bestelldatum);


-- NorthRiver Capstone
-- View vw_region_category_pivot erstellen

CREATE OR REPLACE VIEW public.vw_region_category_pivot AS
SELECT region,
       SUM(CASE WHEN category = 'Furniture' THEN revenue ELSE 0 END) AS furniture,
       SUM(CASE WHEN category = 'Lighting' THEN revenue ELSE 0 END) AS lighting,
       SUM(CASE WHEN category = 'Electronics' THEN revenue ELSE 0 END) AS electronics,
       SUM(CASE WHEN category = 'Office Supplies' THEN revenue ELSE 0 END) AS office_supplies,
       SUM(CASE WHEN category IS NULL OR category NOT IN
           ('Furniture', 'Lighting', 'Electronics', 'Office Supplies')
           THEN revenue ELSE 0 END) AS other_categories
FROM public.vw_order_details GROUP BY region;


-- NorthRiver Capstone
-- View vw_channel_metrics_long erstellen

CREATE OR REPLACE VIEW public.vw_channel_metrics_long AS
WITH channel_kennzahlen AS (
    SELECT channel_name, SUM(revenue::numeric) AS total_revenue,
           SUM(quantity) AS total_quantity,
           COUNT(DISTINCT bestellung_id) AS order_count
    FROM public.vw_order_details GROUP BY channel_name
)
SELECT channel_name, 'total_revenue' AS metric, total_revenue::numeric AS value
FROM channel_kennzahlen
UNION ALL
SELECT channel_name, 'total_quantity' AS metric, total_quantity::numeric AS value
FROM channel_kennzahlen
UNION ALL
SELECT channel_name, 'order_count' AS metric, order_count::numeric AS value
FROM channel_kennzahlen;


-- NorthRiver Capstone
-- Detail View kontrollieren

SELECT COUNT(*) AS bestellpositionen,
       COUNT(DISTINCT bestellposition_id) AS eindeutige_positionen,
       COUNT(DISTINCT bestellung_id) AS bestellungen,
       SUM(quantity) AS verkaufte_stueckzahl, SUM(revenue::numeric) AS gesamtumsatz
FROM public.vw_order_details;


-- NorthRiver Capstone
-- Region Monat View kontrollieren

SELECT year AS jahr, SUM(total_revenue) AS gesamtumsatz,
       SUM(orders) AS summe_region_monat_bestellungen
FROM public.vw_region_month_summary GROUP BY year ORDER BY year;


-- NorthRiver Capstone
-- Region Kategorie Pivot kontrollieren

SELECT region, furniture, lighting, electronics, office_supplies, other_categories,
       furniture + lighting + electronics + office_supplies + other_categories AS regionsumsatz
FROM public.vw_region_category_pivot ORDER BY regionsumsatz DESC;


-- NorthRiver Capstone
-- Lange Channel Kennzahlen kontrollieren

SELECT metric AS kennzahl, COUNT(*) AS zeilen, SUM(value) AS gesamtsumme
FROM public.vw_channel_metrics_long GROUP BY metric ORDER BY metric;

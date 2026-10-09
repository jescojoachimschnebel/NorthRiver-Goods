-- Datenbank: northriver_warehouse
-- Schema: public
-- Bereinigte Reviewfassung: 9. Oktober 2026
-- PostgreSQL; Schema und Datentypen vor Ausführung prüfen.
-- Nur synthetische Daten verwenden; Abfrageergebnisse nicht veröffentlichen.
-- Die Abschnitte einzeln ausführen.

-- NorthRiver Capstone
-- Basiswerte des Datensatzes

SELECT COUNT(*) AS bestellpositionen,
       COUNT(DISTINCT order_id) AS bestellungen,
       SUM(revenue::numeric) AS gesamtumsatz
FROM public.fact_orders;


-- NorthRiver Capstone
-- Umsatz nach Region

SELECT dc.region, SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
INNER JOIN public.dim_customer AS dc ON fo.customer_sk = dc.customer_sk
GROUP BY dc.region ORDER BY umsatz DESC;


-- NorthRiver Capstone
-- Umsatz nach Produktkategorie

SELECT dp.category, SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
INNER JOIN public.dim_product AS dp ON fo.product_sk = dp.product_sk
GROUP BY dp.category ORDER BY umsatz DESC;


-- NorthRiver Capstone
-- Umsatz und Positionen nach Channel

SELECT dc.channel_name AS channel, SUM(fo.revenue::numeric) AS umsatz,
       COUNT(*) AS bestellpositionen
FROM public.fact_orders AS fo
INNER JOIN public.dim_channel AS dc ON fo.channel_sk = dc.channel_sk
GROUP BY dc.channel_name ORDER BY umsatz DESC;


-- NorthRiver Capstone
-- Bestellungen und Umsatz pro Monat 2024

SELECT EXTRACT(YEAR FROM dd.date)::integer AS jahr,
       EXTRACT(MONTH FROM dd.date)::integer AS monat,
       COUNT(DISTINCT fo.order_id) AS bestellungen,
       COUNT(*) AS bestellpositionen, SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
INNER JOIN public.dim_date AS dd ON fo.date_sk = dd.date_sk
WHERE dd.year = 2024
GROUP BY EXTRACT(YEAR FROM dd.date), EXTRACT(MONTH FROM dd.date)
ORDER BY jahr, monat;


-- NorthRiver Capstone
-- Kontrollsummen nach Jahr

SELECT dd.year AS jahr, COUNT(DISTINCT fo.order_id) AS bestellungen,
       COUNT(*) AS bestellpositionen, SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
INNER JOIN public.dim_date AS dd ON fo.date_sk = dd.date_sk
GROUP BY dd.year ORDER BY dd.year;


-- NorthRiver Capstone
-- Die fünf umsatzstärksten Produkte

SELECT dp.product_sk, dp.name AS produkt, dp.category AS kategorie,
       SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
JOIN public.dim_product AS dp ON fo.product_sk = dp.product_sk
GROUP BY dp.product_sk, dp.name, dp.category
ORDER BY umsatz DESC, dp.product_sk
LIMIT 5;

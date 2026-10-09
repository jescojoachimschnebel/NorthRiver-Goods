-- Datenbank: northriver_warehouse
-- Schema: public
-- Bereinigte Reviewfassung: 9. Oktober 2026
-- PostgreSQL; Schema und Datentypen vor Ausführung prüfen.
-- Nur synthetische Daten verwenden; Abfrageergebnisse nicht veröffentlichen.
-- Die Abschnitte einzeln ausführen.

-- NorthRiver Capstone
-- Umsatzanteil jedes Channels

WITH channel_umsatz AS (
    SELECT dc.channel_name AS channel, SUM(fo.revenue::numeric) AS umsatz
    FROM public.fact_orders AS fo
    INNER JOIN public.dim_channel AS dc ON fo.channel_sk = dc.channel_sk
    GROUP BY dc.channel_name
), gesamt AS (SELECT SUM(umsatz) AS gesamtumsatz FROM channel_umsatz)
SELECT cu.channel, cu.umsatz,
       ROUND(100.0 * cu.umsatz / NULLIF(g.gesamtumsatz, 0), 2)
         AS umsatzanteil_prozent
FROM channel_umsatz AS cu CROSS JOIN gesamt AS g
ORDER BY cu.umsatz DESC;


-- NorthRiver Capstone
-- Kunden über dem durchschnittlichen Kundenumsatz

WITH kunden_umsatz AS (
    SELECT dc.customer_sk,
           COALESCE(SUM(fo.revenue::numeric), 0) AS umsatz
    FROM public.dim_customer AS dc
    LEFT JOIN public.fact_orders AS fo ON dc.customer_sk = fo.customer_sk
    GROUP BY dc.customer_sk
), durchschnitt AS (
    SELECT AVG(umsatz) AS durchschnittlicher_umsatz FROM kunden_umsatz
)
SELECT ku.customer_sk, ku.umsatz,
       ROUND(d.durchschnittlicher_umsatz::numeric, 2) AS kundendurchschnitt
FROM kunden_umsatz AS ku CROSS JOIN durchschnitt AS d
WHERE ku.umsatz > d.durchschnittlicher_umsatz
ORDER BY ku.umsatz DESC;


-- NorthRiver Capstone
-- Produkte über dem Durchschnitt ihrer Kategorie

WITH produktumsatz AS (
    SELECT dp.product_sk, dp.name AS produkt, dp.category AS kategorie,
           SUM(fo.revenue::numeric) AS umsatz
    FROM public.fact_orders AS fo
    JOIN public.dim_product AS dp ON fo.product_sk = dp.product_sk
    GROUP BY dp.product_sk, dp.name, dp.category
), kategoriedurchschnitt AS (
    SELECT kategorie, AVG(umsatz) AS durchschnitt
    FROM produktumsatz GROUP BY kategorie
)
SELECT pu.kategorie, pu.produkt, pu.umsatz,
       ROUND(kd.durchschnitt::numeric, 2) AS kategoriedurchschnitt
FROM produktumsatz AS pu
JOIN kategoriedurchschnitt AS kd ON pu.kategorie = kd.kategorie
WHERE pu.umsatz > kd.durchschnitt
ORDER BY pu.kategorie, pu.umsatz DESC, pu.product_sk;

-- NorthRiver Capstone
-- Kundenquartale über dem eigenen Durchschnitt

WITH kundenquartal AS (
    SELECT fo.customer_sk,
           EXTRACT(YEAR FROM dd.date)::integer AS jahr,
           EXTRACT(QUARTER FROM dd.date)::integer AS quartal,
           SUM(fo.revenue::numeric) AS umsatz
    FROM public.fact_orders AS fo
    JOIN public.dim_date AS dd ON fo.date_sk = dd.date_sk
    GROUP BY fo.customer_sk, EXTRACT(YEAR FROM dd.date),
             EXTRACT(QUARTER FROM dd.date)
), kundendurchschnitt AS (
    SELECT customer_sk, AVG(umsatz) AS durchschnitt
    FROM kundenquartal GROUP BY customer_sk
)
SELECT kq.customer_sk, kq.jahr, kq.quartal, kq.umsatz,
       ROUND(kd.durchschnitt::numeric, 2) AS quartalsdurchschnitt
FROM kundenquartal AS kq
JOIN kundendurchschnitt AS kd ON kq.customer_sk = kd.customer_sk
JOIN public.dim_customer AS dc ON kq.customer_sk = dc.customer_sk
WHERE kq.umsatz > kd.durchschnitt
ORDER BY kq.customer_sk, kq.jahr, kq.quartal;

-- NorthRiver Capstone
-- Region-Monate über dem eigenen Regionsdurchschnitt

WITH regionsmonat AS (
    SELECT dc.region, DATE_TRUNC('month', dd.date)::date AS monat,
           SUM(fo.revenue::numeric) AS umsatz
    FROM public.fact_orders AS fo
    JOIN public.dim_customer AS dc ON fo.customer_sk = dc.customer_sk
    JOIN public.dim_date AS dd ON fo.date_sk = dd.date_sk
    GROUP BY dc.region, DATE_TRUNC('month', dd.date)::date
), regionsdurchschnitt AS (
    SELECT region, AVG(umsatz) AS durchschnitt
    FROM regionsmonat GROUP BY region
)
SELECT rm.region, rm.monat, rm.umsatz,
       ROUND(rd.durchschnitt::numeric, 2) AS regionsdurchschnitt
FROM regionsmonat AS rm
JOIN regionsdurchschnitt AS rd ON rm.region = rd.region
WHERE rm.umsatz > rd.durchschnitt
ORDER BY rm.region, rm.monat;

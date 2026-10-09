-- Datenbank: northriver_warehouse
-- Schema: public
-- Bereinigte Reviewfassung: 9. Oktober 2026
-- PostgreSQL; Schema und Datentypen vor Ausführung prüfen.
-- Nur synthetische Daten verwenden; Abfrageergebnisse nicht veröffentlichen.
-- Die Abschnitte einzeln ausführen.

-- NorthRiver Capstone
-- Kunden nach Umsatz ranken

WITH kunden_umsatz AS (
    SELECT dc.customer_sk,
           COALESCE(SUM(fo.revenue::numeric), 0) AS umsatz
    FROM public.dim_customer AS dc
    LEFT JOIN public.fact_orders AS fo ON dc.customer_sk = fo.customer_sk
    GROUP BY dc.customer_sk
)
SELECT customer_sk, umsatz,
       RANK() OVER (ORDER BY umsatz DESC) AS umsatzrang
FROM kunden_umsatz ORDER BY umsatzrang, customer_sk;


-- NorthRiver Capstone
-- Umsatzveränderung gegenüber dem Vormonat

WITH monatsumsatz AS (
    SELECT m.monat, COALESCE(SUM(fo.revenue::numeric), 0)::numeric AS umsatz
    FROM generate_series(1, 12) AS m(monat)
    LEFT JOIN public.dim_date AS dd
      ON dd.date >= make_date(2024, m.monat, 1)
     AND dd.date < make_date(2024, m.monat, 1) + INTERVAL '1 month'
    LEFT JOIN public.fact_orders AS fo ON fo.date_sk = dd.date_sk
    GROUP BY m.monat
),
monatsvergleich AS (
    SELECT monat, umsatz, LAG(umsatz) OVER (ORDER BY monat) AS vormonatsumsatz
    FROM monatsumsatz
)
SELECT monat, umsatz, vormonatsumsatz,
       umsatz - vormonatsumsatz AS veraenderung
FROM monatsvergleich ORDER BY monat;


-- NorthRiver Capstone
-- Laufender Umsatz und Drei Monats Durchschnitt

WITH monatsumsatz AS (
    SELECT m.monat, COALESCE(SUM(fo.revenue::numeric), 0)::numeric AS umsatz
    FROM generate_series(1, 12) AS m(monat)
    LEFT JOIN public.dim_date AS dd
      ON dd.date >= make_date(2024, m.monat, 1)
     AND dd.date < make_date(2024, m.monat, 1) + INTERVAL '1 month'
    LEFT JOIN public.fact_orders AS fo ON fo.date_sk = dd.date_sk
    GROUP BY m.monat
)
SELECT monat, umsatz,
       SUM(umsatz) OVER (
           ORDER BY monat ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS laufender_umsatz,
       ROUND(AVG(umsatz) OVER (
           ORDER BY monat ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS drei_monats_durchschnitt
FROM monatsumsatz ORDER BY monat;


-- NorthRiver Capstone
-- Kontrolle: Kundenumsatz mit der Faktensumme abgleichen
-- Vergleich wird bei jeder Ausführung neu berechnet.

WITH kunden_umsatz AS (
    SELECT dc.customer_sk, COALESCE(SUM(fo.revenue::numeric), 0) AS umsatz
    FROM public.dim_customer AS dc
    LEFT JOIN public.fact_orders AS fo ON dc.customer_sk = fo.customer_sk
    GROUP BY dc.customer_sk
), summen AS (
    SELECT (SELECT SUM(revenue::numeric) FROM public.fact_orders) AS faktensumme,
           (SELECT SUM(umsatz) FROM kunden_umsatz) AS kundensumme
)
SELECT faktensumme, kundensumme,
       faktensumme - kundensumme AS differenz
FROM summen;


-- NorthRiver Capstone
-- Produktranking nach Umsatz

WITH produktumsatz AS (
    SELECT dp.product_sk, dp.name AS produkt, dp.category AS kategorie,
           SUM(fo.revenue::numeric) AS umsatz
    FROM public.fact_orders AS fo
    JOIN public.dim_product AS dp ON fo.product_sk = dp.product_sk
    GROUP BY dp.product_sk, dp.name, dp.category
)
SELECT product_sk, produkt, kategorie, umsatz,
       RANK() OVER (ORDER BY umsatz DESC) AS umsatzrang
FROM produktumsatz
ORDER BY umsatzrang, product_sk;


-- NorthRiver Capstone
-- Umsatzstärkstes Produkt je Kategorie und Anteil

WITH produktumsatz AS (
    SELECT dp.product_sk, dp.name AS produkt, dp.category AS kategorie,
           SUM(fo.revenue::numeric) AS umsatz
    FROM public.fact_orders AS fo
    JOIN public.dim_product AS dp ON fo.product_sk = dp.product_sk
    GROUP BY dp.product_sk, dp.name, dp.category
), produktrang AS (
    SELECT product_sk, produkt, kategorie, umsatz,
           ROUND(100.0 * umsatz / NULLIF(SUM(umsatz) OVER (
               PARTITION BY kategorie), 0), 2) AS anteil_kategorie_prozent,
           ROW_NUMBER() OVER (
               PARTITION BY kategorie ORDER BY umsatz DESC, product_sk
           ) AS rang
    FROM produktumsatz
)
SELECT kategorie, produkt, umsatz, anteil_kategorie_prozent
FROM produktrang WHERE rang = 1 ORDER BY kategorie;

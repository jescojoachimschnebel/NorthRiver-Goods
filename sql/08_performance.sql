-- Datenbank: northriver_warehouse
-- Schema: public
-- Bereinigte Reviewfassung: 9. Oktober 2026
-- PostgreSQL; Schema und Datentypen vor Ausführung prüfen.
-- Nur synthetische Daten verwenden; Abfrageergebnisse nicht veröffentlichen.
-- Die Abschnitte einzeln ausführen.

-- NorthRiver Capstone
-- Größe der Lasttest Tabelle

SELECT COUNT(*) AS zeilenanzahl FROM public.fact_orders_big;


-- NorthRiver Capstone
-- Vorhandene Indizes anzeigen

SELECT indexname AS index_name, indexdef AS index_definition
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'fact_orders_big'
ORDER BY indexname;


-- NorthRiver Capstone
-- Bestellsuche messen

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, channel_sk, revenue FROM public.fact_orders_big WHERE order_id = 5000;


-- NorthRiver Capstone
-- Bestellindex anlegen

CREATE INDEX IF NOT EXISTS idx_fact_orders_big_order_id
ON public.fact_orders_big (order_id);


-- NorthRiver Capstone
-- Channel Suche messen

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, channel_sk, revenue FROM public.fact_orders_big WHERE channel_sk = 1;


-- NorthRiver Capstone
-- Channel Index anlegen

CREATE INDEX IF NOT EXISTS idx_fact_orders_big_channel_sk
ON public.fact_orders_big (channel_sk);


-- NorthRiver Capstone
-- Statistiken aktualisieren

ANALYZE public.fact_orders_big;


-- NorthRiver Capstone
-- Schätzung für Bestellung prüfen

EXPLAIN
SELECT order_id, channel_sk, revenue FROM public.fact_orders_big WHERE order_id = 5000;


-- NorthRiver Capstone
-- Schätzung für Channel prüfen

EXPLAIN
SELECT order_id, channel_sk, revenue FROM public.fact_orders_big WHERE channel_sk = 1;

-- Wiederholungsmessungen nach Statistikaktualisierung
-- Kein Vergleich ohne/mit Index: beide Indizes waren beim Test bereits vorhanden.
-- Bestehende Indizes nicht automatisch löschen.
-- Vorher-Messungen sind nur dann eine Baseline, wenn die Indizes noch fehlen.
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, channel_sk, revenue FROM public.fact_orders_big WHERE order_id = 5000;
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, channel_sk, revenue FROM public.fact_orders_big WHERE channel_sk = 1;

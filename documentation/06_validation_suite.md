# Validierung mit PASS und FAIL

GitHub-Fassung: 9. Oktober 2026. Die ursprüngliche Prüfungsdokumentation bleibt separat erhalten.

Sprint 4 fasst drei Regeln zu einem protokollierbaren Prüfergebnis zusammen. Die absichtlich fehlerhaften Übungstabellen bleiben von echten Reports ausgeschlossen.

Die Ergebniswerte wurden mit den am 9. Oktober 2026 in Beekeeper geteilten Kontrollen abgeglichen. SQL-Beispiele entsprechen der aktuellen SQL-Fassung. Nicht erneut geprüfte historische Angaben sind gesondert gekennzeichnet.

## Validierung der fehlerhaften Übungstabellen

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

| Prüfung | Fehleranzahl | Status |
|---|---|---|
| duplicate_customer_sk | 1 | FAIL |
| null_customer_sk | 5 | FAIL |
| orphan_channel_sk | 3 | FAIL |

### Einordnung

Die Duplikatregel zählt einen betroffenen Schlüssel, nicht seine zwei Dimensionszeilen und nicht die 16 zusätzlich erzeugten Join Zeilen. Das sind drei verschiedene Größen.


## Validierung des sauberen Star Schemas

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

| Prüfung | Fehleranzahl | Status |
|---|---|---|
| duplicate_customer_sk | 0 | PASS |
| null_customer_sk | 0 | PASS |
| orphan_channel_sk | 0 | PASS |

### Einordnung

Alle drei Regeln bestehen. Die Suite bestätigt keine Vollständigkeit aller Fremdschlüssel, Datumsregeln, Beträge oder Ereignisfolgen. Der separate Produktverweischeck aus Datei 00 liefert ebenfalls 0 Fehler.


## Warum NOT EXISTS verwendet wird

NOT IN kann bei NULL Werten in der Unterabfrage unbekannte Wahrheitswerte erzeugen und erwartete Fehlerzeilen ausblenden. NOT EXISTS prüft direkt, ob ein Treffer fehlt. NULL Channels werden in dieser Suite vom Waisencheck ausgeschlossen. Eine zusätzliche Nullregel für channel_sk wäre für einen produktiven Ladeprozess sinnvoll.

## Einsatz im Ladeprozess

Die Prüfungen sollten nach dem Laden und vor der Freigabe für Reports laufen. Die aktuelle Prüfung wurde manuell ausgeführt. Automatische Protokollierung und ein Abbruch des Ladejobs bei FAIL wurden nicht eingerichtet.

## Erweiterte Integritätsdiagnosen

Die aktuelle SQL-Datei ergänzt Schlüssel-, Fremdschlüssel-, NULL-, Zeit- und Bestelldimensionsprüfungen. Ergebnis: 21 PASS und eine Auffälligkeit mit 314 Sessions vor Anmeldung bei 314 Nutzern. PASS bei den drei ursprünglichen Regeln ist kein vollständiger Qualitätsnachweis.

```sql
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
```

## Hinweise für die Veröffentlichung

Keine Zugangsdaten oder echten Ergebnisexporte veröffentlichen. Personenbezogene Kundennamen wurden in dieser Fassung entfernt. Einzelkennungen in Beispielen sind nicht automatisch anonym; die Herkunft und Freigabe der Übungsdaten sind separat zu klären. Umsatzwährung nicht ohne Quelldokumentation voraussetzen.

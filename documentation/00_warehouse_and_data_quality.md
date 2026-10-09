# Grundlagen und Datenqualität

GitHub-Fassung: 9. Oktober 2026. Die ursprüngliche Prüfungsdokumentation bleibt separat erhalten.

Sprint 1 untersucht den Aufbau, die Bedeutung einer Faktenzeile und die Auswirkungen fehlerhafter Dimensionsschlüssel. Die dq Tabellen sind absichtlich fehlerhafte Übungskopien.

Die Ergebniswerte wurden mit den am 9. Oktober 2026 in Beekeeper geteilten Kontrollen abgeglichen. SQL-Beispiele entsprechen der aktuellen SQL-Fassung. Nicht erneut geprüfte historische Angaben sind gesondert gekennzeichnet.

## Tabellen im Schema public

### Abfrage

```sql
SELECT table_name AS tabelle
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

### Bestätigtes Ergebnis

11 Tabellen: dim_channel, dim_customer, dim_customer_fixed, dim_date, dim_product, dim_user, dq_dim_customer, dq_fact_orders, fact_events, fact_orders und fact_orders_big.

### Einordnung

Die zehn Kursobjekte sind vorhanden. Zusätzlich existiert dim_customer_fixed. Die aktuellen Analysen verwenden die saubere dim_customer; die zusätzliche Tabelle wurde nicht als Datenquelle verwendet.


## Granularität der Faktentabelle

### Abfrage

```sql
SELECT COUNT(*) AS positionen,
       COUNT(DISTINCT order_item_sk) AS eindeutige_positions_ids,
       COUNT(DISTINCT order_id) AS bestellungen
FROM public.fact_orders;
```

### Bestätigtes Ergebnis

| Positionen | Eindeutige Positions IDs | Bestellungen |
|---|---|---|
| 180 | 180 | 178 |

### Einordnung

Eine Zeile steht für eine Bestellposition. Mehrere Positionen können zur selben Bestellung gehören. Deshalb unterscheiden sich Zeilenzahl und Bestellanzahl.


## Produktverweise prüfen

### Abfrage

```sql
SELECT COUNT(*) AS positionen_ohne_produkt
FROM public.fact_orders AS fo
WHERE NOT EXISTS (
    SELECT 1 FROM public.dim_product AS dp
    WHERE dp.product_sk = fo.product_sk
);
```

### Bestätigtes Ergebnis

0 Positionen ohne passenden Produktverweis.

### Einordnung

Jede der 180 Positionen findet ein Produkt. Damit bleibt bei dieser Zuordnung keine Position ohne Treffer.


## Auswirkung fehlender Kunden und Channels

### Abfrage

```sql
SELECT
    COUNT(*) FILTER (WHERE customer_sk IS NULL) AS null_customer_rows,
    SUM(revenue::numeric) FILTER (WHERE customer_sk IS NULL) AS revenue_ohne_kunde,
    COUNT(*) FILTER (WHERE channel_sk IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.dim_channel dc
        WHERE dc.channel_sk = dq_fact_orders.channel_sk)) AS orphan_channel_rows
FROM public.dq_fact_orders;
```

### Bestätigtes Ergebnis

| Fehlende Kunden | Umsatz ohne Kunde | Verwaiste Channels |
|---|---|---|
| 5 | 458,50 | 3 |

### Einordnung

Die Abfrage prüft fehlende Dimensionstreffer allgemein per NOT EXISTS; kein fest eingetragener Fehlerwert ist erforderlich.


## Doppelte Kundenschlüssel finden

### Abfrage

```sql
SELECT customer_sk, COUNT(*) AS dimensionszeilen
FROM public.dq_dim_customer
GROUP BY customer_sk
HAVING COUNT(*) > 1;
```

### Bestätigtes Ergebnis

| customer_sk | Dimensionszeilen |
|---|---|
| 17 | 2 |

### Einordnung

Ein Dimensionsschlüssel muss eindeutig sein. Ein doppelter Schlüssel kann Bestellpositionen beim Join vervielfachen.


## Zeilenvermehrung beim Kunden Join

### Abfrage

```sql
SELECT
    (SELECT COUNT(*) FROM public.dq_fact_orders
     WHERE customer_sk IS NOT NULL) AS positionen_mit_kundenschluessel,
    (SELECT COUNT(*) FROM public.dq_fact_orders AS fo
     INNER JOIN public.dq_dim_customer AS dc
       ON fo.customer_sk = dc.customer_sk) AS positionen_nach_join;
```

### Bestätigtes Ergebnis

| Vor Join | Nach Join | Zusätzliche Zeilen |
|---|---|---|
| 175 | 191 | 16 |

### Einordnung

Die 16 Positionen von Kunde 17 finden jeweils zwei Dimensionszeilen. Die aktuelle Messung liefert 191, nicht die 187 aus dem Kursbeispiel. Der eigene Datensatz bestimmt das Ergebnis.


## Join mit eindeutigen Kundenschlüsseln

### Abfrage

```sql
WITH eindeutige_kunden AS (
    SELECT DISTINCT customer_sk
    FROM public.dq_dim_customer
)
SELECT COUNT(*) AS positionen_nach_bereinigtem_join
FROM public.dq_fact_orders AS fo
INNER JOIN eindeutige_kunden AS dc ON fo.customer_sk = dc.customer_sk;
```

### Bestätigtes Ergebnis

175 Ergebniszeilen.

### Einordnung

Die Kundenliste beseitigt die Mehrfachtreffer in dieser Abfrage. Sie repariert die gespeicherten Übungsdaten nicht. Die fünf Positionen ohne Kundenschlüssel bleiben beim INNER JOIN ausgeschlossen. Werden weitere Kundenattribute benötigt, muss die Auswahl bei abweichenden Duplikaten fachlich eindeutig sein.


## Channel Treffer mit LEFT JOIN messen

### Abfrage

```sql
SELECT COUNT(*) AS alle_positionen,
       COUNT(dc.channel_sk) AS positionen_mit_channel,
       COUNT(*) - COUNT(dc.channel_sk) AS positionen_ohne_channel
FROM public.dq_fact_orders AS fo
LEFT JOIN public.dim_channel AS dc ON fo.channel_sk = dc.channel_sk;
```

### Bestätigtes Ergebnis

| Alle Positionen | Mit Treffer | Ohne Treffer |
|---|---|---|
| 180 | 177 | 3 |

### Einordnung

Der LEFT JOIN erhält die drei Positionen ohne passenden Channel. Der separat ausgeführte INNER JOIN lieferte nur 177 Positionen. Ein Filter auf eine rechte Spalte im WHERE kann solche NULL Treffer wieder ausschließen.


## Unbekannten Channel sichtbar halten

### Abfrage

```sql
SELECT COALESCE(dc.channel_name, 'Unbekannter Channel') AS channel,
       COUNT(*) AS positionen, SUM(fo.revenue::numeric) AS umsatz
FROM public.dq_fact_orders AS fo
LEFT JOIN public.dim_channel AS dc ON fo.channel_sk = dc.channel_sk
GROUP BY COALESCE(dc.channel_name, 'Unbekannter Channel')
ORDER BY umsatz DESC;
```

### Bestätigtes Ergebnis

| Channel | Positionen | Umsatz |
|---|---|---|
| Retail Store | 57 | 7.857,50 |
| Website | 47 | 6.708,50 |
| Retail Partner | 35 | 5.685,50 |
| Phone Order | 38 | 4.292,50 |
| Unbekannter Channel | 3 | 70,00 |

### Einordnung

Alle 180 Positionen bleiben sichtbar. Der fehlende Channel betrifft 70,00 Umsatz. Die dq Umsätze pro Channel unterscheiden sich deshalb von der sauberen Auswertung in Datei 01.


## Weitere bestätigte Grundlagen

Die saubere Kundendimension enthält 12 Kunden. Die Regionen heißen South, West, East und Midwest. Die Segmente heißen Consumer und Corporate. Lücken in customer_sk sind zulässig. Historische Orientierung: warehouse.dim_customer und warehouse.fact_orders wurden in der ursprünglichen Dokumentation als leer beschrieben. Dies wurde bei der aktuellen Prüfung nicht erneut gemessen. Die getesteten Abfragen verwenden public.

Eine dauerhafte Fehlerbehebung sollte die Ursache im Ladeprozess und die Eindeutigkeit der Dimensionsschlüssel sichern. In dieser Prüfung wurden keine Constraints an den Übungstabellen verändert.

## Hinweise für die Veröffentlichung

Keine Zugangsdaten oder echten Ergebnisexporte veröffentlichen. Personenbezogene Kundennamen wurden in dieser Fassung entfernt. Einzelkennungen in Beispielen sind nicht automatisch anonym; die Herkunft und Freigabe der Übungsdaten sind separat zu klären. Umsatzwährung nicht ohne Quelldokumentation voraussetzen.

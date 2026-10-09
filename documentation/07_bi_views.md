# BI Views und ihre Granularität

GitHub-Fassung: 9. Oktober 2026. Die ursprüngliche Prüfungsdokumentation bleibt separat erhalten.

Sprint 4 ergänzt vier wiederverwendbare Ausgaben. Die Erstellung und alle folgenden Kontrollen wurden im SQL Client bestätigt. Views speichern die Abfragelogik, keine vorberechneten Ergebnisse.

Die Ergebniswerte wurden mit den am 9. Oktober 2026 in Beekeeper geteilten Kontrollen abgeglichen. SQL-Beispiele entsprechen der aktuellen SQL-Fassung. Nicht erneut geprüfte historische Angaben sind gesondert gekennzeichnet.

## View vw_order_details erstellen

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

Die View wurde erstellt. Die Ergebnisnachweise stehen in den folgenden Kontrollen.

### Einordnung

Die Erstfassung wurde mit CREATE VIEW ausgeführt. Die aktuelle Fassung verwendet CREATE OR REPLACE VIEW. Änderungen von Spaltentypen oder vorhandenen Spalten benötigen gegebenenfalls eine gesonderte Migration. Diese Anweisung verändert die View Definition, nicht die zugrunde liegenden Tabellen.


## View vw_region_month_summary erstellen

### Abfrage

```sql
CREATE OR REPLACE VIEW public.vw_region_month_summary AS
SELECT region, EXTRACT(YEAR FROM bestelldatum)::integer AS year,
       EXTRACT(MONTH FROM bestelldatum)::integer AS month,
       SUM(revenue::numeric) AS total_revenue,
       COUNT(DISTINCT bestellung_id) AS orders
FROM public.vw_order_details
GROUP BY region, EXTRACT(YEAR FROM bestelldatum), EXTRACT(MONTH FROM bestelldatum);
```

### Bestätigtes Ergebnis

Die View wurde erstellt. Die Ergebnisnachweise stehen in den folgenden Kontrollen.

### Einordnung

Die Erstfassung wurde mit CREATE VIEW ausgeführt. Die aktuelle Fassung verwendet CREATE OR REPLACE VIEW. Änderungen von Spaltentypen oder vorhandenen Spalten benötigen gegebenenfalls eine gesonderte Migration. Diese Anweisung verändert die View Definition, nicht die zugrunde liegenden Tabellen.


## View vw_region_category_pivot erstellen

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

Die View wurde erstellt. Die Ergebnisnachweise stehen in den folgenden Kontrollen.

### Einordnung

Die Erstfassung wurde mit CREATE VIEW ausgeführt. Die aktuelle Fassung verwendet CREATE OR REPLACE VIEW. Änderungen von Spaltentypen oder vorhandenen Spalten benötigen gegebenenfalls eine gesonderte Migration. Diese Anweisung verändert die View Definition, nicht die zugrunde liegenden Tabellen.


## View vw_channel_metrics_long erstellen

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

Die View wurde erstellt. Die Ergebnisnachweise stehen in den folgenden Kontrollen.

### Einordnung

Die Erstfassung wurde mit CREATE VIEW ausgeführt. Die aktuelle Fassung verwendet CREATE OR REPLACE VIEW. Änderungen von Spaltentypen oder vorhandenen Spalten benötigen gegebenenfalls eine gesonderte Migration. Diese Anweisung verändert die View Definition, nicht die zugrunde liegenden Tabellen.


## Detail View kontrollieren

### Abfrage

```sql
SELECT COUNT(*) AS bestellpositionen,
       COUNT(DISTINCT bestellposition_id) AS eindeutige_positionen,
       COUNT(DISTINCT bestellung_id) AS bestellungen,
       SUM(quantity) AS verkaufte_stueckzahl, SUM(revenue::numeric) AS gesamtumsatz
FROM public.vw_order_details;
```

### Bestätigtes Ergebnis

| Positionen | Eindeutige IDs | Bestellungen | Stück | Umsatz |
|---|---|---|---|---|
| 180 | 180 | 178 | 356 | 24.614,00 |

### Einordnung

Eine Zeile entspricht einer Position. COUNT(*) ist daher keine Bestellanzahl.


## Region Monat View kontrollieren

### Abfrage

```sql
SELECT year AS jahr, SUM(total_revenue) AS gesamtumsatz,
       SUM(orders) AS summe_region_monat_bestellungen
FROM public.vw_region_month_summary GROUP BY year ORDER BY year;
```

### Bestätigtes Ergebnis

| Jahr | Umsatz | Bestellungen |
|---|---|---|
| 2024 | 12.951,50 | 91 |
| 2025 | 11.662,50 | 87 |

### Einordnung

Die Werte stimmen mit den direkt ermittelten Jahressummen überein. Unterschiedliche Bestellungen pro Gruppe sind nur addierbar, wenn keine Bestellung mehreren Gruppen angehört.


## Region Kategorie Pivot kontrollieren

### Abfrage

```sql
SELECT region, furniture, lighting, electronics, office_supplies, other_categories,
       furniture + lighting + electronics + office_supplies + other_categories AS regionsumsatz
FROM public.vw_region_category_pivot ORDER BY regionsumsatz DESC;
```

### Bestätigtes Ergebnis

| Region | Furniture | Lighting | Electronics | Office Supplies | Summe |
|---|---|---|---|---|---|
| West | 3.346,00 | 2.670,00 | 2.342,00 | 166,00 | 8.524,00 |
| East | 3.053,00 | 2.403,00 | 1.036,50 | 234,00 | 6.726,50 |
| South | 3.197,00 | 801,00 | 926,00 | 162,00 | 5.086,00 |
| Midwest | 2.859,00 | 534,00 | 777,50 | 107,00 | 4.277,50 |

### Einordnung

Die Regionssummen und Kategorie Spaltensummen stimmen mit Datei 01 überein. Eine Zeile steht für eine Region.


## Lange Channel Kennzahlen kontrollieren

### Abfrage

```sql
SELECT metric AS kennzahl, COUNT(*) AS zeilen, SUM(value) AS gesamtsumme
FROM public.vw_channel_metrics_long GROUP BY metric ORDER BY metric;
```

### Bestätigtes Ergebnis

| Kennzahl | Zeilen | Summe |
|---|---|---|
| order_count | 4 | 178 |
| total_quantity | 4 | 356 |
| total_revenue | 4 | 24.614,00 |

### Einordnung

Die View enthält insgesamt 12 Zeilen. Die drei Kennzahlen müssen getrennt ausgewertet werden. Eine Summe über alle value Werte würde unterschiedliche Einheiten vermischen.


## Bereits vorhandene Views

Auch die Definitionen der folgenden Views wurden gelesen und ihre Kontrollsummen geprüft:

| View | Granularität | Bestätigte Kontrolle |
|---|---|---|
| vw_category_by_channel | Kategorie mit Channel Spalten | Kategorieumsätze ergeben 24.614,00 |
| vw_channel_performance | Monat und Channel | 24.614,00 Umsatz, 356 Stück, 178 Bestellungen |
| vw_monthly_revenue | Monat, Region und Kategorie | 2024: 12.951,50 und 172 Stück; 2025: 11.662,50 und 184 Stück |
| vw_revenue_by_region_category | Region und Kategorie | Regionssummen stimmen mit Datei 01 überein |

Die SQL Datei definiert die vier neu erstellten Views. Sie überschreibt die vier zuvor vorhandenen Views nicht.

## Änderungen der GitHub-Fassung

Die Detailview verwendet LEFT JOINs, damit fehlende Dimensionstreffer keine Fakten entfernen. Eindeutige Dimensionsschlüssel bleiben notwendig, um Zeilenvermehrung zu verhindern. Der Pivot ergänzt other_categories einschließlich NULL-Kategorie; diese Spalte ist im geprüften Bestand für alle Regionen 0. Die Regionssummen bleiben unverändert. Angaben zu weiteren vorhandenen Views stammen aus der historischen Dokumentation; diese wurden am 9. Oktober nicht erneut einzeln geprüft.

## Hinweise für die Veröffentlichung

Keine Zugangsdaten oder echten Ergebnisexporte veröffentlichen. Personenbezogene Kundennamen wurden in dieser Fassung entfernt. Einzelkennungen in Beispielen sind nicht automatisch anonym; die Herkunft und Freigabe der Übungsdaten sind separat zu klären. Umsatzwährung nicht ohne Quelldokumentation voraussetzen.

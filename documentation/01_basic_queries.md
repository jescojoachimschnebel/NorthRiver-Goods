# Geschäftsfragen mit einfachen SQL Abfragen

GitHub-Fassung: 9. Oktober 2026. Die ursprüngliche Prüfungsdokumentation bleibt separat erhalten.

Sprint 2 wertet den sauberen Bestelldatensatz aus. Die Kontrollsumme beträgt 24.614,00 Umsatz, 180 Positionen und 178 Bestellungen.

Die Ergebniswerte wurden mit den am 9. Oktober 2026 in Beekeeper geteilten Kontrollen abgeglichen. SQL-Beispiele entsprechen der aktuellen SQL-Fassung. Nicht erneut geprüfte historische Angaben sind gesondert gekennzeichnet.

## Basiswerte des Datensatzes

### Abfrage

```sql
SELECT COUNT(*) AS bestellpositionen,
       COUNT(DISTINCT order_id) AS bestellungen,
       SUM(revenue::numeric) AS gesamtumsatz
FROM public.fact_orders;
```

### Bestätigtes Ergebnis

| Bestellpositionen | Bestellungen | Gesamtumsatz |
|---|---|---|
| 180 | 178 | 24.614,00 |

### Einordnung

Diese Werte dienen als Vergleich für die folgenden Aggregationen. Die BI Detailansicht bestätigt zusätzlich 356 verkaufte Stück.


## Umsatz nach Region

### Abfrage

```sql
SELECT dc.region, SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
INNER JOIN public.dim_customer AS dc ON fo.customer_sk = dc.customer_sk
GROUP BY dc.region ORDER BY umsatz DESC;
```

### Bestätigtes Ergebnis

| Region | Umsatz |
|---|---|
| West | 8.524,00 |
| East | 6.726,50 |
| South | 5.086,00 |
| Midwest | 4.277,50 |

### Einordnung

West erzielt den höchsten Umsatz. Jede Ausgabezeile steht für eine Region. Die Summe der vier Regionen beträgt 24.614,00.


## Umsatz nach Produktkategorie

### Abfrage

```sql
SELECT dp.category, SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
INNER JOIN public.dim_product AS dp ON fo.product_sk = dp.product_sk
GROUP BY dp.category ORDER BY umsatz DESC;
```

### Bestätigtes Ergebnis

| Kategorie | Umsatz |
|---|---|
| Furniture | 12.455,00 |
| Lighting | 6.408,00 |
| Electronics | 5.082,00 |
| Office Supplies | 669,00 |

### Einordnung

Furniture führt. Die vier Kategorien ergeben zusammen 24.614,00. Die früheren Zahlen mit zwei Kategorien gehören zu einem anderen Datenstand.


## Umsatz und Positionen nach Channel

### Abfrage

```sql
SELECT dc.channel_name AS channel, SUM(fo.revenue::numeric) AS umsatz,
       COUNT(*) AS bestellpositionen
FROM public.fact_orders AS fo
INNER JOIN public.dim_channel AS dc ON fo.channel_sk = dc.channel_sk
GROUP BY dc.channel_name ORDER BY umsatz DESC;
```

### Bestätigtes Ergebnis

| Channel | Umsatz | Positionen |
|---|---|---|
| Retail Store | 7.857,50 | 57 |
| Website | 6.708,50 | 47 |
| Retail Partner | 5.713,50 | 36 |
| Phone Order | 4.334,50 | 40 |

### Einordnung

Retail Store führt bei Umsatz und Positionszahl. COUNT(*) zählt hier ausdrücklich Positionen. Die Summen ergeben 180 Positionen und 24.614,00.


## Bestellungen und Umsatz pro Monat 2024

### Abfrage

```sql
SELECT EXTRACT(YEAR FROM dd.date)::integer AS jahr,
       EXTRACT(MONTH FROM dd.date)::integer AS monat,
       COUNT(DISTINCT fo.order_id) AS bestellungen,
       COUNT(*) AS bestellpositionen, SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
INNER JOIN public.dim_date AS dd ON fo.date_sk = dd.date_sk
WHERE dd.year = 2024
GROUP BY EXTRACT(YEAR FROM dd.date), EXTRACT(MONTH FROM dd.date)
ORDER BY jahr, monat;
```

### Bestätigtes Ergebnis

| Monat | Bestellungen | Positionen | Umsatz |
|---|---|---|---|
| 1 | 5 | 5 | 348,50 |
| 2 | 5 | 5 | 961,00 |
| 3 | 10 | 10 | 1.042,50 |
| 4 | 2 | 2 | 388,00 |
| 5 | 8 | 8 | 1.122,00 |
| 6 | 3 | 3 | 285,50 |
| 7 | 12 | 12 | 2.762,00 |
| 8 | 12 | 14 | 1.550,00 |
| 9 | 5 | 5 | 1.333,00 |
| 10 | 11 | 11 | 1.298,00 |
| 11 | 11 | 11 | 1.329,00 |
| 12 | 7 | 7 | 532,00 |

### Einordnung

2024 enthält 91 Bestellungen und 93 Positionen mit 12.951,50 Umsatz. Im August enthalten 12 Bestellungen 14 Positionen. Die Datumsspalte heißt date, nicht full_date.


## Kontrollsummen nach Jahr

### Abfrage

```sql
SELECT dd.year AS jahr, COUNT(DISTINCT fo.order_id) AS bestellungen,
       COUNT(*) AS bestellpositionen, SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
INNER JOIN public.dim_date AS dd ON fo.date_sk = dd.date_sk
GROUP BY dd.year ORDER BY dd.year;
```

### Bestätigtes Ergebnis

| Jahr | Bestellungen | Positionen | Umsatz |
|---|---|---|---|
| 2024 | 91 | 93 | 12.951,50 |
| 2025 | 87 | 87 | 11.662,50 |

### Einordnung

Die Jahressummen stimmen mit den Basiswerten überein. Eine Summierung gruppierter unterschiedlicher Bestellungen ist nur sicher, wenn eine Bestellung nicht in mehreren Gruppen vorkommt.


## Die fünf umsatzstärksten Produkte

### Abfrage

```sql
SELECT dp.product_sk, dp.name AS produkt, dp.category AS kategorie,
       SUM(fo.revenue::numeric) AS umsatz
FROM public.fact_orders AS fo
JOIN public.dim_product AS dp ON fo.product_sk = dp.product_sk
GROUP BY dp.product_sk, dp.name, dp.category
ORDER BY umsatz DESC, dp.product_sk
LIMIT 5;
```

### Bestätigtes Ergebnis

Am 6. Oktober 2026 in northriver_warehouse, Schema public, ausgeführt und anhand der Ergebnisanzeige bestätigt.

| Schlüssel | Produkt | Kategorie | Umsatz |
|---|---|---|---|
| 5 | Aria Desk Lamp | Lighting | 6.408,00 |
| 3 | Birchwood Bookshelf | Furniture | 5.481,00 |
| 1 | Oakwood Office Chair | Furniture | 4.619,00 |
| 7 | USB-C Dock | Electronics | 2.370,00 |
| 6 | Wireless Keyboard | Electronics | 1.947,00 |

### Einordnung

Die Aria Desk Lamp erzielt den höchsten Produktumsatz. Die fünf Produkte erreichen zusammen 20.825,00 und damit rund 84,61 Prozent des Gesamtumsatzes von 24.614,00. Gruppiert wird nach Produktschlüssel, Name und Kategorie. Bei gleichen Umsätzen entscheidet der Produktschlüssel über die Reihenfolge für LIMIT 5.


## Hinweise für die Veröffentlichung

Keine Zugangsdaten oder echten Ergebnisexporte veröffentlichen. Personenbezogene Kundennamen wurden in dieser Fassung entfernt. Einzelkennungen in Beispielen sind nicht automatisch anonym; die Herkunft und Freigabe der Übungsdaten sind separat zu klären. Umsatzwährung nicht ohne Quelldokumentation voraussetzen.

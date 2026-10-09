# Mehrstufige Analysen mit CTEs

GitHub-Fassung: 9. Oktober 2026. Die ursprüngliche Prüfungsdokumentation bleibt separat erhalten.

CTEs benennen Zwischenergebnisse. Die hier bestätigten Beispiele bilden zunächst Umsätze und vergleichen diese anschließend mit einer Gesamtsumme oder einem Durchschnitt.

Die Ergebniswerte wurden mit den am 9. Oktober 2026 in Beekeeper geteilten Kontrollen abgeglichen. SQL-Beispiele entsprechen der aktuellen SQL-Fassung. Nicht erneut geprüfte historische Angaben sind gesondert gekennzeichnet.

## Umsatzanteil jedes Channels

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

| Channel | Umsatz | Anteil |
|---|---|---|
| Retail Store | 7.857,50 | 31,92 % |
| Website | 6.708,50 | 27,25 % |
| Retail Partner | 5.713,50 | 23,21 % |
| Phone Order | 4.334,50 | 17,61 % |

### Einordnung

Die zweite CTE liefert genau einen Gesamtwert. Daher passt CROSS JOIN. Die gerundeten Anteile ergeben 99,99 %. NULLIF verhindert eine Division durch null.


## Kunden über dem durchschnittlichen Kundenumsatz

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

| Schlüssel | Umsatz | Durchschnitt |
|---|---|---|
| 3 | 3.619,00 | 2.051,17 |
| 4 | 2.929,50 | 2.051,17 |
| 11 | 2.611,00 | 2.051,17 |
| 19 | 2.340,50 | 2.051,17 |
| 17 | 2.294,00 | 2.051,17 |
| 14 | 2.110,50 | 2.051,17 |

### Einordnung

Sechs Kunden liegen über dem Durchschnitt. Der Nenner umfasst alle zwölf Kunden. LEFT JOIN berücksichtigt auch Kunden ohne Umsatz mit 0. Der Vergleich verwendet den ungerundeten Durchschnitt, die Anzeige zwei Nachkommastellen.




## Produkte über dem Kategoriedurchschnitt

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

Am 6. Oktober 2026 in northriver_warehouse, Schema public, ausgeführt und anhand der Ergebnisanzeigen bestätigt.

| Kategorie | Produkt | Umsatz | Kategoriedurchschnitt |
| --- | --- | --- | --- |
| Electronics | USB-C Dock | 2.370,00 | 1.694,00 |
| Electronics | Wireless Keyboard | 1.947,00 | 1.694,00 |
| Furniture | Birchwood Bookshelf | 5.481,00 | 3.113,75 |
| Furniture | Oakwood Office Chair | 4.619,00 | 3.113,75 |
| Office Supplies | Premium Notebook Set | 448,00 | 334,50 |

### Einordnung

Fünf Produkte liegen über dem durchschnittlichen Produktumsatz ihrer eigenen Kategorie. Lighting liefert keinen Treffer, weil das einzige Produkt genau dem Durchschnitt entspricht. Verglichen wird mit dem ungerundeten Durchschnitt; nur die Anzeige wird gerundet. Der Join über kategorie ordnet jedem Produkt den passenden Durchschnitt zu. Berücksichtigt werden Produkte mit Bestellpositionen.



## Kundenquartale über dem eigenen Durchschnitt

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

Am 6. Oktober 2026 in northriver_warehouse, Schema public, ausgeführt und anhand der Ergebnisanzeigen bestätigt.

| Schlüssel | Jahr | Quartal | Umsatz | Quartalsdurchschnitt |
| --- | --- | --- | --- | --- |
| 2 | 2025 | 4 | 1.089,50 | 196,36 |
| 3 | 2024 | 3 | 1.212,00 | 603,17 |
| 3 | 2025 | 2 | 881,00 | 603,17 |
| 3 | 2025 | 3 | 801,00 | 603,17 |
| 4 | 2024 | 2 | 805,00 | 366,19 |
| 4 | 2024 | 4 | 867,50 | 366,19 |
| 6 | 2024 | 3 | 490,00 | 228,71 |
| 6 | 2025 | 3 | 567,00 | 228,71 |
| 7 | 2024 | 3 | 181,00 | 157,08 |
| 7 | 2025 | 3 | 378,00 | 157,08 |
| 7 | 2025 | 4 | 178,00 | 157,08 |
| 9 | 2024 | 2 | 222,00 | 142,07 |
| 9 | 2024 | 3 | 456,00 | 142,07 |
| 9 | 2025 | 2 | 148,00 | 142,07 |
| 11 | 2024 | 3 | 774,00 | 373,00 |
| 11 | 2024 | 4 | 685,00 | 373,00 |
| 11 | 2025 | 3 | 503,00 | 373,00 |
| 13 | 2024 | 1 | 811,50 | 361,80 |
| 13 | 2025 | 3 | 367,00 | 361,80 |
| 14 | 2024 | 3 | 1.190,50 | 351,75 |
| 14 | 2024 | 4 | 516,50 | 351,75 |
| 16 | 2025 | 3 | 987,00 | 284,00 |
| 16 | 2025 | 4 | 488,00 | 284,00 |
| 17 | 2024 | 1 | 425,00 | 327,71 |
| 17 | 2024 | 4 | 590,50 | 327,71 |
| 17 | 2025 | 3 | 502,00 | 327,71 |
| 19 | 2024 | 1 | 343,00 | 334,36 |
| 19 | 2024 | 3 | 378,00 | 334,36 |
| 19 | 2025 | 2 | 426,00 | 334,36 |
| 19 | 2025 | 3 | 473,00 | 334,36 |

### Einordnung

Die Ergebnisanzeigen enthalten 30 Kundenquartale über dem jeweiligen Kundendurchschnitt. Beispielsweise erreicht der betreffende Kunde im vierten Quartal 2025 einen Umsatz von 1.089,50 gegenüber einem Durchschnitt von 196,36. Jahr und Quartal werden gemeinsam gruppiert. Der Durchschnitt berücksichtigt nur Quartale mit Bestellungen; fehlende Quartale werden nicht als 0 ergänzt. Der Filter verwendet den ungerundeten Durchschnitt.



## Region-Monate über dem Regionsdurchschnitt

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

Am 6. Oktober 2026 in northriver_warehouse, Schema public, ausgeführt und anhand der Ergebnisanzeigen bestätigt.

| Region | Monat | Umsatz | Regionsdurchschnitt |
| --- | --- | --- | --- |
| East | 2024-02-01 | 536,00 | 305,75 |
| East | 2024-05-01 | 953,00 | 305,75 |
| East | 2024-08-01 | 401,00 | 305,75 |
| East | 2024-11-01 | 385,00 | 305,75 |
| East | 2025-07-01 | 855,00 | 305,75 |
| East | 2025-08-01 | 567,00 | 305,75 |
| East | 2025-12-01 | 501,50 | 305,75 |
| Midwest | 2024-03-01 | 356,00 | 225,13 |
| Midwest | 2024-04-01 | 298,00 | 225,13 |
| Midwest | 2024-08-01 | 238,00 | 225,13 |
| Midwest | 2024-09-01 | 556,00 | 225,13 |
| Midwest | 2025-03-01 | 237,00 | 225,13 |
| Midwest | 2025-05-01 | 574,00 | 225,13 |
| Midwest | 2025-07-01 | 537,00 | 225,13 |
| Midwest | 2025-09-01 | 384,50 | 225,13 |
| South | 2024-07-01 | 1.123,00 | 299,18 |
| South | 2024-08-01 | 468,50 | 299,18 |
| South | 2024-11-01 | 484,50 | 299,18 |
| South | 2025-05-01 | 424,50 | 299,18 |
| South | 2025-08-01 | 567,00 | 299,18 |
| South | 2025-10-01 | 467,00 | 299,18 |
| South | 2025-12-01 | 722,50 | 299,18 |
| West | 2024-07-01 | 1.301,00 | 448,63 |
| West | 2024-09-01 | 567,00 | 448,63 |
| West | 2024-10-01 | 904,50 | 448,63 |
| West | 2025-07-01 | 490,00 | 448,63 |
| West | 2025-08-01 | 879,00 | 448,63 |

### Einordnung

Die Anzeige enthält 27 Region-Monate über dem jeweiligen Regionsdurchschnitt: East 7, Midwest 8, South 7 und West 5. DATE_TRUNC bildet eindeutige Kalendermonate einschließlich des Jahres. Der Durchschnitt berücksichtigt nur Monate mit Bestellungen in der Region. Fehlende Monate werden nicht als 0 ergänzt. Der Join über region liefert den passenden Vergleichswert; der Filter vergleicht ungerundete Werte.


## Hinweise für die Veröffentlichung

Keine Zugangsdaten oder echten Ergebnisexporte veröffentlichen. Personenbezogene Kundennamen wurden in dieser Fassung entfernt. Einzelkennungen in Beispielen sind nicht automatisch anonym; die Herkunft und Freigabe der Übungsdaten sind separat zu klären. Umsatzwährung nicht ohne Quelldokumentation voraussetzen.

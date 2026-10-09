# Vergleiche mit Window Functions

GitHub-Fassung: 9. Oktober 2026. Die ursprüngliche Prüfungsdokumentation bleibt separat erhalten.

Window Functions ergänzen Vergleichswerte, ohne die Eingabezeilen zusammenzufassen. Die Umsätze werden zuerst auf Kunden oder Monate aggregiert.

Die Ergebniswerte wurden mit den am 9. Oktober 2026 in Beekeeper geteilten Kontrollen abgeglichen. SQL-Beispiele entsprechen der aktuellen SQL-Fassung. Nicht erneut geprüfte historische Angaben sind gesondert gekennzeichnet.

## Kunden nach Umsatz ranken

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

| Schlüssel | Umsatz | Rang |
|---|---|---|
| 3 | 3.619,00 | 1 |
| 4 | 2.929,50 | 2 |
| 11 | 2.611,00 | 3 |
| 19 | 2.340,50 | 4 |
| 17 | 2.294,00 | 5 |
| 14 | 2.110,50 | 6 |
| 16 | 1.988,00 | 7 |
| 13 | 1.809,00 | 8 |
| 6 | 1.601,00 | 9 |
| 2 | 1.374,50 | 10 |
| 9 | 994,50 | 11 |
| 7 | 942,50 | 12 |

### Einordnung

Alle zwölf Kunden bleiben erhalten. der betreffende Kunde führt. Bei gleichem Umsatz vergibt RANK denselben Rang und lässt danach eine Rangnummer aus. Die erneute Rankingabfrage am 6. Oktober 2026 bestätigt für der betreffende Kunde 1.988,00. Der zuvor dokumentierte Wert von 1.980,00 wurde korrigiert. Die zwölf Kundenumsätze summieren sich auf 24.614,00 und stimmen mit der separat geprüften Faktensumme überein.


## Umsatzveränderung gegenüber dem Vormonat

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

| Monat | Umsatz | Vormonat | Veränderung |
|---|---|---|---|
| 1 | 348,50 | NULL | NULL |
| 2 | 961,00 | 348,50 | 612,50 |
| 3 | 1.042,50 | 961,00 | 81,50 |
| 4 | 388,00 | 1.042,50 | -654,50 |
| 5 | 1.122,00 | 388,00 | 734,00 |
| 6 | 285,50 | 1.122,00 | -836,50 |
| 7 | 2.762,00 | 285,50 | 2.476,50 |
| 8 | 1.550,00 | 2.762,00 | -1.212,00 |
| 9 | 1.333,00 | 1.550,00 | -217,00 |
| 10 | 1.298,00 | 1.333,00 | -35,00 |
| 11 | 1.329,00 | 1.298,00 | 31,00 |
| 12 | 532,00 | 1.329,00 | -797,00 |

### Einordnung

Für Januar gibt es in dieser Auswahl keinen Vormonat. Der größte Anstieg liegt im Juli und der größte Rückgang im August. Alle zwölf Monate sind im Datensatz vertreten. Die aktuelle Abfrage ergänzt alle zwölf Kalendermonate; Monate ohne Positionen erhalten Umsatz 0. LAG vergleicht dadurch benachbarte Kalendermonate.


## Laufender Umsatz und Drei Monats Durchschnitt

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

| Monat | Laufender Umsatz | Drei Monats Durchschnitt |
|---|---|---|
| 1 | 348,50 | 348,50 |
| 2 | 1.309,50 | 654,75 |
| 3 | 2.352,00 | 784,00 |
| 4 | 2.740,00 | 797,17 |
| 5 | 3.862,00 | 850,83 |
| 6 | 4.147,50 | 598,50 |
| 7 | 6.909,50 | 1.389,83 |
| 8 | 8.459,50 | 1.532,50 |
| 9 | 9.792,50 | 1.881,67 |
| 10 | 11.090,50 | 1.393,67 |
| 11 | 12.419,50 | 1.320,00 |
| 12 | 12.951,50 | 1.053,00 |

### Einordnung

Die laufende Summe endet bei dem bestätigten Jahresumsatz. Der Durchschnitt nutzt den aktuellen und die zwei vorherigen Kalendermonate, einschließlich ergänzter Monate mit Umsatz 0. Für Januar und Februar stehen weniger als drei Monate zur Verfügung.


## Bestätigte Kontrolle der Kundensumme

Die folgende Abfrage wurde am 6. Oktober 2026 ausgeführt und durch eine Ergebnisanzeige bestätigt.

| Faktensumme | Kundensumme | Differenz |
|---|---|---|
| 24.614,00 | 24.614,00 | 0,00 |

Die aktuelle Kundensumme stimmt mit der Faktensumme überein. Auch die anschließende Rankingabfrage bestätigt die zwölf Einzelwerte mit insgesamt 24.614,00. Die Abweichung im zuvor dokumentierten Ranking ist damit geklärt.

```sql
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
```


## Produktranking nach Umsatz

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

Am 6. Oktober 2026 in northriver_warehouse, Schema public, ausgeführt und anhand der Ergebnisanzeige bestätigt.

| Schlüssel | Produkt | Kategorie | Umsatz | Rang |
|---|---|---|---|---|
| 5 | Aria Desk Lamp | Lighting | 6.408,00 | 1 |
| 3 | Birchwood Bookshelf | Furniture | 5.481,00 | 2 |
| 1 | Oakwood Office Chair | Furniture | 4.619,00 | 3 |
| 7 | USB-C Dock | Electronics | 2.370,00 | 4 |
| 6 | Wireless Keyboard | Electronics | 1.947,00 | 5 |
| 2 | Standing Desk Converter | Furniture | 1.395,00 | 6 |
| 4 | Ergo Lumbar Cushion | Furniture | 960,00 | 7 |
| 8 | Wireless Mouse | Electronics | 765,00 | 8 |
| 10 | Premium Notebook Set | Office Supplies | 448,00 | 9 |
| 9 | Sticky Note Pack | Office Supplies | 221,00 | 10 |

### Einordnung

Die zehn Produktumsätze ergeben zusammen 24.614,00 und stimmen mit der Faktensumme überein. RANK vergibt bei Umsatzgleichheit denselben Rang und lässt nachfolgende Rangnummern aus. Im bestätigten Ergebnis gibt es keine Umsatzgleichheit. Die ersten fünf Produkte stimmen mit der LIMIT-5-Abfrage überein.



## Spitzenprodukt je Kategorie

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

Am 6. Oktober 2026 in northriver_warehouse, Schema public, ausgeführt und anhand der Ergebnisanzeigen bestätigt.

| Kategorie | Produkt | Umsatz | Anteil in Prozent |
| --- | --- | --- | --- |
| Electronics | USB-C Dock | 2.370,00 | 46,64 |
| Furniture | Birchwood Bookshelf | 5.481,00 | 44,01 |
| Lighting | Aria Desk Lamp | 6.408,00 | 100,00 |
| Office Supplies | Premium Notebook Set | 448,00 | 66,97 |

### Einordnung

ROW_NUMBER bestimmt pro Kategorie genau ein Spitzenprodukt. Bei gleichen Umsätzen entscheidet der Produktschlüssel. Der Anteil bezieht sich auf den gesamten Umsatz der jeweiligen Kategorie. Die Rangberechnung erfolgt in einer CTE; die äußere Abfrage filtert rang = 1. Lighting hat im bestätigten Produktranking nur ein Produkt und daher einen Anteil von 100 Prozent.


## Hinweise für die Veröffentlichung

Keine Zugangsdaten oder echten Ergebnisexporte veröffentlichen. Personenbezogene Kundennamen wurden in dieser Fassung entfernt. Einzelkennungen in Beispielen sind nicht automatisch anonym; die Herkunft und Freigabe der Übungsdaten sind separat zu klären. Umsatzwährung nicht ohne Quelldokumentation voraussetzen.

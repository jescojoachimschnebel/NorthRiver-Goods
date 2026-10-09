# Ergebnisnachweise

## Herkunft und Grenzen

Die sechs PNG-Dateien sind unveränderte Ergebnis-Screenshots vom 6. Oktober 2026. Die darin sichtbaren aggregierten Ergebnisse stimmen mit den am 9. Oktober erneut kontrollierten Werten überein. Der Screenshot zum Kundenumsatzabgleich zeigt ausschließlich Summen, keine Kundennamen oder individuellen Kundenwerte.

Die vier TXT-Dateien sind historische Abschriften ausgewählter Ausführungsplanzeilen. Sie sind keine vollständigen Roh-Exporte und wurden in dieser Prüfung nicht anhand der damaligen Originalpläne verifiziert. Die Messungen verwenden SELECT * und unterscheiden sich damit von der expliziten Spaltenauswahl in der aktuellen SQL-Fassung.

## Screenshots

| Datei | Nachweis |
|---|---|
| [top_product_by_category_20261006.png](top_product_by_category_20261006.png) | Spitzenprodukt und Umsatzanteil je Kategorie |
| [top_5_products_20261006.png](top_5_products_20261006.png) | Fünf umsatzstärkste Produkte |
| [products_above_category_average_20261006.png](products_above_category_average_20261006.png) | Produkte über dem Kategoriedurchschnitt |
| [customer_revenue_reconciliation_20261006.png](customer_revenue_reconciliation_20261006.png) | Faktensumme und Kundensumme jeweils 24.614,00; Differenz 0,00 |
| [product_ranking_20261006.png](product_ranking_20261006.png) | Ranking aller zehn Produkte |
| [region_months_above_average_20261006.png](region_months_above_average_20261006.png) | 27 Region-Monate über dem Regionsdurchschnitt |

## Historische Performance-Abschriften

| Dateien | Historisch dokumentierte Messung |
|---|---|
| [order_id_before.txt](order_id_before.txt), [order_id_after.txt](order_id_after.txt) | Bestellsuche: Parallel Seq Scan 64,377 ms; Index Scan 0,083 ms |
| [channel_before.txt](channel_before.txt), [channel_after.txt](channel_after.txt) | Channelsuche: Seq Scan 114,694 ms; Bitmap Heap Scan 336,213 ms |

Diese historischen Einzelmessungen liefern keinen allgemeinen Beschleunigungsfaktor. Beim Test am 9. Oktober waren beide Indizes bereits vorhanden: Bestellsuche 1,763 und 0,437 ms; Channelsuche 170,519 und 347,807 ms. Die Indexnutzung wurde bestätigt, eine Beschleunigung durch Indexanlage oder Statistikaktualisierung nicht nachgewiesen. Cache, Systemlast und Abfrageprojektion beeinflussen die Vergleichbarkeit.

## Bewusst nicht enthalten

customer_revenue_ranking_20261006.png sowie customer_quarters_20261006_part_1.png und customer_quarters_20261006_part_2.png enthalten Kundennamen mit Einzelumsätzen. Sie bleiben in der lokalen Prüfungsfassung und gehören nicht zu diesem Uploadpaket. Ob diese Namen synthetisch sind, wurde nicht nachgewiesen. Die Originalbilder wurden nicht verändert.

Die Herkunft und Veröffentlichungsrechte der zugrunde liegenden Übungsdaten sind separat zu klären. Die Auswahl enthält keine erkennbaren Zugangsdaten oder personenbezogenen Kundennamen.

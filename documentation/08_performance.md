# Performance und Ausführungspläne

GitHub-Fassung: 9. Oktober 2026. Aktuelle Kontrollen getrennt von den historischen Prüfungsnotizen.

## Aktueller Indexstand

fact_orders_big enthält 2.000.000 Zeilen. Primärschlüsselindex auf order_item_sk sowie Indizes auf order_id und channel_sk waren vor den aktuellen Messungen bereits vorhanden. Die beiden CREATE INDEX-Abschnitte wurden deshalb nicht erneut ausgeführt. Kein Index wurde gelöscht.

## Aktuelle Messungen mit vorhandenen Indizes

| Filter | Plan | Tatsächliche Treffer | Erste Messung | Wiederholung nach ANALYZE |
|---|---|---:|---:|---:|
| order_id = 5000 | Index Scan | 3 | 1,763 ms | 0,437 ms |
| channel_sk = 1 | Bitmap Index Scan + Bitmap Heap Scan | 499.794 | 170,519 ms | 347,807 ms |

Die aktuelle Abfrage selektiert order_id, channel_sk und revenue. Der Channel-Filter trifft rund 25 % der Tabelle; 18.692 Heap-Blöcke werden besucht. Laufzeiten sind Einzelmessungen und schwanken mit Cache und Systemlast. Kein Geschwindigkeitsgewinn durch Indexanlage oder Statistikaktualisierung nachgewiesen.

## Schätzungen

Bestellung: 2 geschätzte statt 3 tatsächliche Treffer. Channel: vor Statistikaktualisierung 501.533 geschätzt; nach Aktualisierung 489.467 statt 499.794 (rund 2,1 % Abweichung). ANALYZE garantiert keine Verbesserung jeder einzelnen Schätzung. EXPLAIN ohne ANALYZE zeigt Schätzungen, keine gemessene Laufzeit.

## Historische Prüfungsnotizen vom 6. Oktober

Die gelieferte ältere Dokumentation berichtet folgende Einzelmessungen mit SELECT *:

| Filter | Ohne betreffenden Index laut alter Dokumentation | Mit Index laut alter Dokumentation |
|---|---|---|
| order_id = 5000 | Parallel Seq Scan, 64,377 ms | Index Scan, 0,083 ms |
| channel_sk = 1 | Seq Scan, 114,694 ms | Bitmap Heap Scan, 336,213 ms |

Diese historischen Angaben wurden am 9. Oktober nicht reproduziert; die zugrunde liegenden alten Nachweise wurden für diese Dokumentationsprüfung nicht geprüft. Die Projektion unterscheidet sich von der aktuellen Abfrage. Daraus wird kein allgemeiner Beschleunigungsfaktor abgeleitet.

## Ausführungshinweise

EXPLAIN ANALYZE führt SELECT tatsächlich aus und erzeugt Last. CREATE INDEX kann Schreibzugriffe blockieren. IF NOT EXISTS prüft nicht die Definition eines bereits vorhandenen Indexnamens. Statistiken wurden aktualisiert; die aktuelle Planwahl nutzt beide passenden Indizes. Ein belastbarer Vergleich ohne/mit Index benötigt eine getrennte Testkopie und vergleichbare Messbedingungen.

[Aktuelle SQL-Datei öffnen](../sql/08_performance.sql)

## Hinweise für die Veröffentlichung

Keine Zugangsdaten oder echten Ergebnisexporte veröffentlichen. Personenbezogene Kundennamen wurden in dieser Fassung entfernt. Einzelkennungen in Beispielen sind nicht automatisch anonym; die Herkunft und Freigabe der Übungsdaten sind separat zu klären. Umsatzwährung nicht ohne Quelldokumentation voraussetzen.

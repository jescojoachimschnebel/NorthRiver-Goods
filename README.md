# NorthRiver Goods – SQL-Analysen im Data Warehouse

**Masterschool Data Analytics | Abschlussprüfung: 100/100 Punkte**

## Projektübersicht

NorthRiver Goods ist ein Data-Warehouse-Projekt zur Analyse von Bestellungen, Umsätzen und Nutzeraktivität.

Das Projekt umfasst dimensionale Modellierung, Datenqualitätsprüfungen, analytische SQL-Abfragen, Performance-Untersuchungen und Berichte mit Power BI.

Die veröffentlichten SQL-Dateien wurden nach der abgeschlossenen Prüfung zusätzlich überprüft und getestet. Diese Überarbeitung ergänzt das Projekt; das Prüfungsergebnis bleibt unverändert.

## Technologien und Kompetenzen

- SQL: PostgreSQL und Databricks SQL
- Data Warehousing und Star Schema
- Common Table Expressions (CTEs)
- Window Functions
- Datenqualitätsprüfungen
- Funnel- und Kohortenanalysen
- Untersuchung von Abfrageplänen und Indizes
- Power BI

Die SQL-Dateien in diesem Repository verwenden PostgreSQL-Syntax.

## SQL-Dateien

| Datei | Inhalt |
|---|---|
| [00_warehouse_and_data_quality.sql](sql/00_warehouse_and_data_quality.sql) | Tabellenübersicht, Granularität und Auswirkungen fehlerhafter Joins |
| [01_basic_queries.sql](sql/01_basic_queries.sql) | Umsätze, Bestellungen, Produkte, Regionen und Vertriebskanäle |
| [02_ctes.sql](sql/02_ctes.sql) | Umsatzanteile und Vergleiche mit Durchschnittswerten |
| [03_window_functions.sql](sql/03_window_functions.sql) | Rankings, Monatsvergleiche, laufende Summen und gleitende Durchschnitte |
| [04_cohort_analysis.sql](sql/04_cohort_analysis.sql) | Anmeldekohorten und Retention anhand von Sessions |
| [05_funnel_analysis.sql](sql/05_funnel_analysis.sql) | Geordneter Funnel, Kaufquoten und Prüfung der Anmeldezeitpunkte |
| [06_validation_suite.sql](sql/06_validation_suite.sql) | Datenqualitäts- und Integritätsprüfungen |
| [07_bi_views.sql](sql/07_bi_views.sql) | BI-Views und Abgleich der Kontrollsummen |
| [08_performance.sql](sql/08_performance.sql) | Indexübersicht und Messung von Ausführungsplänen |

## Datenmodell und Granularität

Das Bestellmodell folgt einem Star Schema mit einer Faktentabelle und vier Dimensionen.

**Faktentabelle:** `fact_orders`

**Dimensionen:**

- `dim_customer` – Kunden
- `dim_product` – Produkte
- `dim_date` – Datum
- `dim_channel` – Vertriebskanäle

**Granularität:** Eine Zeile entspricht einer Bestellposition.

Für die Analyse der Nutzeraktivität werden zusätzlich `dim_user` und `fact_events` verwendet.

Die SQL-Dateien greifen auf das Schema `public` zu. Tabellen mit dem Präfix `dq_` enthalten absichtliche Übungsfehler. Die Tabelle `fact_orders_big` dient den Performance-Untersuchungen.

## Bestätigte Kennzahlen

| Kennzahl | Ergebnis |
|---|---:|
| Bestellpositionen | 180 |
| Eindeutige Bestellungen | 178 |
| Verkaufte Stückzahl | 356 |
| Gesamtumsatz | 24.614,00 |
| Umsatz 2024 | 12.951,50 |
| Umsatz 2025 | 11.662,50 |
| Registrierte Nutzer | 500 |
| Nutzer mit Kauf ab hinterlegtem Anmeldedatum | 94 |
| Kaufquote ab hinterlegtem Anmeldedatum | 18,80 % |
| Aktive Nutzer im Kalendermonat nach Anmeldung | 352 |
| Monat-1-Retention | 70,40 % |

Die Währung ist anhand der Dokumentation der Quelldaten zu bestätigen.

Bestell- und Nutzerkennzahlen stammen aus unterschiedlichen Faktentabellen und werden nicht unmittelbar gleichgesetzt.

## Umsatzanalysen

Die SQL-Abfragen untersuchen:

- Umsätze nach Region, Produktkategorie und Vertriebskanal
- Produkt- und Kundenrankings
- Umsatzveränderungen gegenüber dem Vormonat
- Laufende Umsatzsummen
- Gleitende Drei-Monats-Durchschnitte

Die geprüften Dimensions-Joins und BI-Views erhalten die Gesamtwerte der Bestellfakten.

Die monatlichen Fensterberechnungen berücksichtigen alle zwölf Monate des Jahres 2024. Kundenquartals- und Regionsmonatsdurchschnitte berücksichtigen dagegen nur Zeiträume mit vorhandenen Bestellpositionen.

## Kohortenanalyse und Retention

Nutzer werden nach dem Kalendermonat ihres hinterlegten Anmeldedatums in `dim_user.signup_date` gruppiert.

Für die Retention zählen ausschließlich Sessions ab diesem Anmeldedatum. **Monat 1** bezeichnet den folgenden Kalendermonat, keinen festen Zeitraum von 30 Tagen.

Im Datensatz wurden **314 Sessions vor dem hinterlegten Anmeldedatum** gefunden. Diese Sessions werden aus der Retention ausgeschlossen. Die Rohdaten bleiben unverändert.

Der letzte Event-Monat wird vorsorglich als möglicherweise unvollständig ausgeschlossen. Diese Annahme belegt nicht, dass die vorherigen Monate vollständig erfasst wurden.

## Kaufquote und geordneter Funnel

Die Auswertung unterscheidet zwei Kennzahlen:

- **Kaufquote: 18,80 %** – 94 von 500 registrierten Nutzern haben ab ihrem hinterlegten Anmeldedatum gekauft. Zwischenstufen sind dafür nicht erforderlich.
- **Vollständiger geordneter Funnel: 0,20 %** – Ein Nutzer hat alle fünf aufgezeichneten Schritte in zeitlicher Reihenfolge durchlaufen.

Die Funnel-Stufen lauten:

`signup → browsed → added_to_cart → checkout → purchased`

Die Nutzerzahlen im geordneten Funnel betragen:

**500 → 237 → 67 → 11 → 1**

Beide Auswertungen verwenden den verfügbaren Datenbestand ohne feste Conversion-Frist. Im Funnel sind gleiche Zeitstempel erlaubt; die Schritte müssen nicht innerhalb derselben Session stattfinden.

Das erste Signup-Event liegt bei **24 Nutzern am hinterlegten Anmeldetag** und bei **476 Nutzern an einem späteren Tag**. Signup-Event und hinterlegtes Anmeldedatum sind deshalb unterschiedliche Startpunkte. Die Ursache dieser Abweichung ist nicht geklärt.

## Datenqualität

Die SQL-Prüfungen untersuchen:

- Fehlende und doppelte Schlüssel
- Ungültige Verweise auf Dimensionstabellen
- Fehlende Kennzahlen und Eventfelder
- Events vor dem hinterlegten Anmeldedatum
- Uneinheitliche Dimensionszuordnungen innerhalb einer Bestellung

Die erweiterte Prüfung ergab **21 PASS-Ergebnisse** und eine Auffälligkeit: die 314 Sessions vor Anmeldung.

Die absichtlich fehlerhaften Übungstabellen zeigen die Auswirkungen von Datenqualitätsproblemen:

- Fünf Bestellpositionen haben keinen Kundenschlüssel.
- Drei Bestellpositionen verweisen auf einen unbekannten Channel.
- Ein Kundenschlüssel kommt zweimal vor.
- Der Kunden-Join vermehrt 175 Positionen auf 191 Zeilen.
- Ein Join mit eindeutigen Kundenschlüsseln liefert wieder 175 Zeilen.

Die ausgegebenen Werte `PASS` und `FAIL` dienen der Diagnose. Sie stoppen keine Verarbeitung automatisch.

## Performance-Untersuchung

Die Abfragepläne wurden anhand einer Tabelle mit **2.000.000 Zeilen** untersucht.

- Die Suche nach einer Bestellung verwendet einen `Index Scan` und liefert drei Treffer.
- Die Suche nach einem Channel verwendet einen `Bitmap Index Scan` mit anschließendem `Bitmap Heap Scan` und liefert 499.794 Treffer.

Beide Indizes waren bei der Überprüfung bereits vorhanden. Die gemessenen Laufzeiten schwankten zwischen den Ausführungen.

Die Messungen bestätigen die Indexnutzung. Sie belegen keine Beschleunigung durch eine neue Indexanlage oder die Aktualisierung von Statistiken.

## Business Intelligence

Im Prüfungsprojekt wurde ein Power-BI-Dashboard zur Darstellung der Analyseergebnisse eingesetzt.

Die SQL-Dateien erstellen vier unterstützende Views:

- `vw_order_details`
- `vw_region_month_summary`
- `vw_region_category_pivot`
- `vw_channel_metrics_long`

Die Kontrollsummen der geprüften Views stimmen mit den Bestellfakten überein.

## Ausführung der SQL-Dateien

Voraussetzung sind die vorhandenen NorthRiver-Tabellen mit passenden Spalten und Datentypen. Skripte zur Tabellenerstellung und Beispieldaten sind derzeit nicht enthalten. Das Repository stellt deshalb keine eigenständig ausführbare Datenbankinstallation bereit.

Die Abschnitte anhand ihrer Überschriften einzeln und vollständig ausführen. Ein `WITH`-Block muss zusammen mit seinem abschließenden `SELECT` ausgeführt werden.

Views, Indizes und Statistikaktualisierungen zunächst in einer Testdatenbank ausführen. `EXPLAIN ANALYZE` führt die untersuchte Abfrage tatsächlich aus und kann Last verursachen.

Zugangsdaten, echte Kundendaten, Datenbank-Dumps und Ergebnisse mit identifizierbaren Einzelinformationen gehören nicht in das öffentliche Repository.

## Abschlussprüfung

**Ergebnis: 100/100 Punkte**

Das Projekt wurde im Rahmen der Masterschool-Weiterbildung im Bereich Data Analytics abgeschlossen.

Die Bewertung würdigte das Verständnis von Warehouse-Architektur, Datengranularität, SQL-Joins und Datenqualität.

## Autor

Jesco-Joachim Schnebel

Data Analytics | SQL | Data Warehousing | Business Intelligence

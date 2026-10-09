# Kaufquote und geordneter Funnel

GitHub-Fassung: 9. Oktober 2026. Ergänzung nach abgeschlossener Prüfung; Prüfungsabgabe unverändert.

## Bestätigte Definitionen und Ergebnisse

Die Kaufquote ab dim_user.signup_date beträgt 94/500 = 18,80 %. Sie setzt keine Zwischenstufen voraus. Der vollständige geordnete Funnel ab Signup-Event zählt 500 → 237 → 67 → 11 → 1 Nutzer, also 0,20 % Abschlussquote. Gleiche Zeitstempel sind erlaubt; keine Session-Zuordnung und keine feste Conversion-Frist.

| Stufe | Nutzer | Nutzer der Vorstufe | Conversion |
|---|---:|---:|---:|
| signup | 500 | NULL | NULL |
| browsed | 237 | 500 | 47,40 % |
| added_to_cart | 67 | 237 | 28,27 % |
| checkout | 11 | 67 | 16,42 % |
| purchased | 1 | 11 | 9,09 % |

Im vollständigen Funnel nach Kanal hat Paid Search 1 Käufer bei 110 Anmeldungen (0,91 %); die anderen Kanäle 0. Diese Kennzahl ist nicht die allgemeine Kaufquote.

## Kaufquote ab hinterlegtem Anmeldedatum nach Kanal

| Kanal | Registrierte Nutzer | Kaufnutzer | Kaufquote |
|---|---:|---:|---:|
| Referral | 102 | 22 | 21,57 % |
| Paid Search | 110 | 23 | 20,91 % |
| Social | 89 | 17 | 19,10 % |
| Email | 93 | 15 | 16,13 % |
| Organic | 106 | 17 | 16,04 % |

Gesamt: 500 registrierte Nutzer, 94 Kaufnutzer. Referral führt bei der Quote, Paid Search bei der absoluten Käuferzahl. Daraus wird keine Ursache oder statistische Signifikanz abgeleitet.

## Unterschiedliche Anmeldezeitpunkte

Alle 500 Nutzer besitzen ein Signup-Event. Bei 24 liegt das erste Event am hinterlegten Anmeldetag, bei 476 später, bei keinem früher. Kauf ab erstem Signup-Event: 48/500 = 9,60 %. Die Ursache der Abweichung ist offen; die beiden Startdefinitionen sind nicht austauschbar.

## Historische Stufenzählung

Die ursprüngliche Auswertung zählte unabhängig von Reihenfolge 500/426/317/196/94 Nutzer je Eventtyp. Quotienten dieser unabhängigen Mengen belegen keinen individuellen Übergang zwischen Stufen. Diese Darstellung wurde durch den geordneten Funnel ergänzt.

## Abgrenzung zur Retention

Retention misst Session-Aktivität im Folgemonat. Email hat 73,12 % Monat-1-Retention; Referral 21,57 % Kaufquote ab Anmeldedatum. Die Kennzahlen verwenden unterschiedliche Ereignisse.

## Aktuelle SQL-Abfragen

Alle sechs Anweisungen der verknüpften SQL-Datei wurden in Beekeeper ausgeführt und anhand der geteilten Ergebnisse kontrolliert. Die SQL-Quelle ist maßgeblich für die genauen Filter.

[SQL-Datei öffnen](../sql/05_funnel_analysis.sql)

```sql
-- Datenbank: northriver_warehouse
-- Schema: public
-- Bereinigte Reviewfassung: 9. Oktober 2026
-- PostgreSQL; Schema und Datentypen vor Ausführung prüfen.
-- Nur synthetische Daten verwenden; Abfrageergebnisse nicht veröffentlichen.
-- Die Abschnitte einzeln ausführen.

-- Vollständiger Funnel ab Signup-Event; nicht die allgemeine Kaufquote.
-- Zeitlich geordneter Nutzerfunnel über den gesamten Datenbestand.
-- Gleiche Zeitstempel sind erlaubt, da event_date auch nur Tagesauflösung haben kann.
-- Keine Session-Zuordnung oder festgelegte Conversion-Frist.
WITH anmeldungen AS (
    SELECT fe.user_sk, MIN(fe.event_date) AS signup_at
    FROM public.fact_events fe JOIN public.dim_user du ON fe.user_sk = du.user_sk
    WHERE fe.event_type = 'signup' AND fe.event_date >= du.signup_date
    GROUP BY fe.user_sk
), pfad AS (
    SELECT a.user_sk, du.acquisition_channel AS kanal, a.signup_at,
           b.at AS browsed_at, c.at AS cart_at, ch.at AS checkout_at, p.at AS purchased_at
    FROM anmeldungen a JOIN public.dim_user du USING (user_sk)
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'browsed' AND event_date >= a.signup_at) b ON true
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'added_to_cart' AND event_date >= b.at) c ON true
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'checkout' AND event_date >= c.at) ch ON true
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'purchased' AND event_date >= ch.at) p ON true
), funnel AS (
    SELECT 1 AS stufenfolge, 'signup' AS stufe, COUNT(*) AS nutzer FROM pfad
    UNION ALL SELECT 2, 'browsed', COUNT(browsed_at) FROM pfad
    UNION ALL SELECT 3, 'added_to_cart', COUNT(cart_at) FROM pfad
    UNION ALL SELECT 4, 'checkout', COUNT(checkout_at) FROM pfad
    UNION ALL SELECT 5, 'purchased', COUNT(purchased_at) FROM pfad
)
SELECT * FROM funnel ORDER BY stufenfolge;

WITH anmeldungen AS (
    SELECT fe.user_sk, MIN(fe.event_date) AS signup_at
    FROM public.fact_events fe JOIN public.dim_user du ON fe.user_sk = du.user_sk
    WHERE fe.event_type = 'signup' AND fe.event_date >= du.signup_date
    GROUP BY fe.user_sk
), pfad AS (
    SELECT a.user_sk, du.acquisition_channel AS kanal, a.signup_at,
           b.at AS browsed_at, c.at AS cart_at, ch.at AS checkout_at, p.at AS purchased_at
    FROM anmeldungen a JOIN public.dim_user du USING (user_sk)
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'browsed' AND event_date >= a.signup_at) b ON true
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'added_to_cart' AND event_date >= b.at) c ON true
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'checkout' AND event_date >= c.at) ch ON true
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'purchased' AND event_date >= ch.at) p ON true
), funnel AS (
    SELECT 1 AS stufenfolge, 'signup' AS stufe, COUNT(*) AS nutzer FROM pfad
    UNION ALL SELECT 2, 'browsed', COUNT(browsed_at) FROM pfad
    UNION ALL SELECT 3, 'added_to_cart', COUNT(cart_at) FROM pfad
    UNION ALL SELECT 4, 'checkout', COUNT(checkout_at) FROM pfad
    UNION ALL SELECT 5, 'purchased', COUNT(purchased_at) FROM pfad
), vergleich AS (
    SELECT *, LAG(nutzer) OVER (ORDER BY stufenfolge) AS nutzer_vorstufe FROM funnel
)
SELECT stufe, nutzer, nutzer_vorstufe,
       ROUND(100.0 * nutzer / NULLIF(nutzer_vorstufe, 0), 2) AS conversion_prozent
FROM vergleich ORDER BY stufenfolge;

WITH anmeldungen AS (
    SELECT fe.user_sk, MIN(fe.event_date) AS signup_at
    FROM public.fact_events fe JOIN public.dim_user du ON fe.user_sk = du.user_sk
    WHERE fe.event_type = 'signup' AND fe.event_date >= du.signup_date
    GROUP BY fe.user_sk
), pfad AS (
    SELECT a.user_sk, du.acquisition_channel AS kanal, a.signup_at,
           b.at AS browsed_at, c.at AS cart_at, ch.at AS checkout_at, p.at AS purchased_at
    FROM anmeldungen a JOIN public.dim_user du USING (user_sk)
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'browsed' AND event_date >= a.signup_at) b ON true
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'added_to_cart' AND event_date >= b.at) c ON true
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'checkout' AND event_date >= c.at) ch ON true
    LEFT JOIN LATERAL (SELECT MIN(event_date) AS at FROM public.fact_events
        WHERE user_sk = a.user_sk AND event_type = 'purchased' AND event_date >= ch.at) p ON true
)
SELECT kanal, COUNT(*) AS anmeldungen, COUNT(purchased_at) AS kaeufer,
       ROUND(100.0 * COUNT(purchased_at) / NULLIF(COUNT(*), 0), 2) AS conversion_prozent
FROM pfad GROUP BY kanal ORDER BY conversion_prozent DESC, kanal;

-- Kaufquote ab hinterlegtem Anmeldedatum (unabhängig von Zwischenstufen)
-- Nenner: registrierte Nutzer mit bekanntem signup_date.
-- Gesamter verfügbarer Zeitraum, keine feste Conversion-Frist.
-- Vergleich mit Funnel ab signup-Event nur bei übereinstimmenden Startdaten.
WITH registrierte AS (
    SELECT du.user_sk, du.signup_date, du.acquisition_channel AS kanal,
           EXISTS (
               SELECT 1 FROM public.fact_events fe
               WHERE fe.user_sk = du.user_sk AND fe.event_type = 'purchased'
                 AND fe.event_date >= du.signup_date
           ) AS hat_gekauft
    FROM public.dim_user du WHERE du.signup_date IS NOT NULL
)
SELECT COUNT(*) AS registrierte_nutzer,
       COUNT(*) FILTER (WHERE hat_gekauft) AS kaufnutzer,
       ROUND(100.0 * COUNT(*) FILTER (WHERE hat_gekauft)
             / NULLIF(COUNT(*), 0), 2) AS kaufquote_prozent
FROM registrierte;

-- Kaufquote ab hinterlegtem Anmeldedatum nach Akquisitionskanal
WITH registrierte AS (
    SELECT du.user_sk, du.acquisition_channel AS kanal,
           EXISTS (
               SELECT 1 FROM public.fact_events fe
               WHERE fe.user_sk = du.user_sk AND fe.event_type = 'purchased'
                 AND fe.event_date >= du.signup_date
           ) AS hat_gekauft
    FROM public.dim_user du WHERE du.signup_date IS NOT NULL
)
SELECT kanal, COUNT(*) AS registrierte_nutzer,
       COUNT(*) FILTER (WHERE hat_gekauft) AS kaufnutzer,
       ROUND(100.0 * COUNT(*) FILTER (WHERE hat_gekauft)
             / NULLIF(COUNT(*), 0), 2) AS kaufquote_prozent
FROM registrierte GROUP BY kanal ORDER BY kaufquote_prozent DESC, kanal;

-- Diagnose: Signup-Event gegenüber hinterlegtem Anmeldedatum
-- Aggregierte Ausgabe; keine Namen oder Einzelkennungen.
WITH signup_events AS (
    SELECT user_sk, MIN(event_date) AS signup_event_at
    FROM public.fact_events WHERE event_type = 'signup' GROUP BY user_sk
)
SELECT COUNT(*) AS registrierte_nutzer,
       COUNT(*) FILTER (WHERE s.user_sk IS NULL) AS ohne_signup_event,
       COUNT(*) FILTER (WHERE s.signup_event_at::date = du.signup_date::date) AS gleicher_kalendertag,
       COUNT(*) FILTER (WHERE s.signup_event_at::date < du.signup_date::date) AS event_vor_anmeldetag,
       COUNT(*) FILTER (WHERE s.signup_event_at::date > du.signup_date::date) AS event_nach_anmeldetag
FROM public.dim_user du LEFT JOIN signup_events s USING (user_sk)
WHERE du.signup_date IS NOT NULL;
```

## Hinweise für die Veröffentlichung

Keine Zugangsdaten oder echten Ergebnisexporte veröffentlichen. Personenbezogene Kundennamen wurden in dieser Fassung entfernt. Einzelkennungen in Beispielen sind nicht automatisch anonym; die Herkunft und Freigabe der Übungsdaten sind separat zu klären. Umsatzwährung nicht ohne Quelldokumentation voraussetzen.

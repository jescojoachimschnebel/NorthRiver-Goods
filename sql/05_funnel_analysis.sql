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

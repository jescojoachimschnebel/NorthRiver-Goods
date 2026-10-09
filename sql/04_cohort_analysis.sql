-- Datenbank: northriver_warehouse
-- Schema: public
-- Bereinigte Reviewfassung: 9. Oktober 2026
-- PostgreSQL; Schema und Datentypen vor Ausführung prüfen.
-- Nur synthetische Daten verwenden; Abfrageergebnisse nicht veröffentlichen.
-- Die Abschnitte einzeln ausführen.

-- NorthRiver Capstone
-- Nutzer je Anmeldemonat

SELECT DATE_TRUNC('month', signup_date)::date AS kohortenmonat,
       COUNT(DISTINCT user_sk) AS kohortengroesse
FROM public.dim_user
GROUP BY DATE_TRUNC('month', signup_date)::date ORDER BY kohortenmonat;


-- NorthRiver Capstone
-- Sessions vor dem genauen Anmeldetag prüfen

SELECT DATE_TRUNC('month', du.signup_date)::date AS kohortenmonat,
       COUNT(DISTINCT du.user_sk) AS nutzer_mit_session_im_anmeldemonat,
       COUNT(DISTINCT du.user_sk) FILTER (
           WHERE fe.event_date >= du.signup_date) AS nutzer_ab_anmeldetag,
       COUNT(DISTINCT du.user_sk) FILTER (
           WHERE fe.event_date < du.signup_date) AS nutzer_mit_session_vor_anmeldetag
FROM public.dim_user AS du
INNER JOIN public.fact_events AS fe ON du.user_sk = fe.user_sk
WHERE fe.event_type = 'session'
  AND DATE_TRUNC('month', fe.event_date) = DATE_TRUNC('month', du.signup_date)
GROUP BY DATE_TRUNC('month', du.signup_date)::date ORDER BY kohortenmonat;


-- NorthRiver Capstone
-- Retention je Kohorte und Monatsnummer

-- Beobachtungsende: erster Tag des letzten Event-Monats.
-- Dieser letzte Monat gilt konservativ als unvollständig und wird ausgeschlossen.
-- Ein dokumentiertes Ende eines vollständigen Datenexports ist vorzuziehen.
WITH grenze AS (
    SELECT DATE_TRUNC('month', MAX(event_date))::date AS exklusives_ende
    FROM public.fact_events
), kohorten AS (
    SELECT DATE_TRUNC('month', signup_date)::date AS kohortenmonat,
           COUNT(DISTINCT user_sk) AS kohortengroesse
    FROM public.dim_user WHERE signup_date IS NOT NULL
    GROUP BY 1
), raster AS (
    SELECT k.*, m.monat::date AS aktivitaetsmonat,
           (EXTRACT(YEAR FROM m.monat)::integer - EXTRACT(YEAR FROM k.kohortenmonat)::integer) * 12
           + EXTRACT(MONTH FROM m.monat)::integer - EXTRACT(MONTH FROM k.kohortenmonat)::integer AS monatsnummer
    FROM kohorten k CROSS JOIN grenze g
    CROSS JOIN LATERAL generate_series(k.kohortenmonat::timestamp,
        (g.exklusives_ende - INTERVAL '1 month')::timestamp, INTERVAL '1 month') m(monat)
), aktivitaet AS (
    SELECT DATE_TRUNC('month', du.signup_date)::date AS kohortenmonat,
           DATE_TRUNC('month', fe.event_date)::date AS aktivitaetsmonat,
           COUNT(DISTINCT du.user_sk) AS aktive_nutzer
    FROM public.dim_user du JOIN public.fact_events fe ON du.user_sk = fe.user_sk
    WHERE fe.event_type = 'session' AND fe.event_date >= du.signup_date
    GROUP BY 1, 2
)
SELECT r.kohortenmonat, r.monatsnummer, COALESCE(a.aktive_nutzer, 0) AS aktive_nutzer,
       r.kohortengroesse,
       ROUND(100.0 * COALESCE(a.aktive_nutzer, 0) / NULLIF(r.kohortengroesse, 0), 2) AS retention_prozent
FROM raster r LEFT JOIN aktivitaet a USING (kohortenmonat, aktivitaetsmonat)
ORDER BY r.kohortenmonat, r.monatsnummer;


-- NorthRiver Capstone
-- Monat 1 Retention nach Akquisitionskanal

WITH grenze AS (
    SELECT DATE_TRUNC('month', MAX(event_date))::date AS exklusives_ende FROM public.fact_events
), kanal_retention AS (
    SELECT du.acquisition_channel AS kanal,
           COUNT(DISTINCT du.user_sk) AS angemeldete_nutzer,
           COUNT(DISTINCT du.user_sk) FILTER (
               WHERE fe.user_sk IS NOT NULL) AS aktive_nutzer_monat_1
    FROM public.dim_user AS du
    LEFT JOIN public.fact_events AS fe
      ON du.user_sk = fe.user_sk AND fe.event_type = 'session'
     AND DATE_TRUNC('month', fe.event_date)
       = DATE_TRUNC('month', du.signup_date) + INTERVAL '1 month'
    WHERE du.signup_date IS NOT NULL
      AND DATE_TRUNC('month', du.signup_date) + INTERVAL '2 months'
          <= (SELECT exklusives_ende FROM grenze)
    GROUP BY du.acquisition_channel
)
SELECT kanal, angemeldete_nutzer, aktive_nutzer_monat_1,
       ROUND(100.0 * aktive_nutzer_monat_1
         / NULLIF(angemeldete_nutzer, 0), 2) AS retention_prozent
FROM kanal_retention ORDER BY retention_prozent DESC, kanal;

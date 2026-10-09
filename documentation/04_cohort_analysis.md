# Kohorten und Nutzerbindung

GitHub-Fassung: 9. Oktober 2026. Die ursprüngliche Prüfungsdokumentation bleibt separat erhalten.

Sprint 3 untersucht 500 Nutzer in zwölf Anmeldekohorten von 2024. Ein Nutzer gehört zum Kalendermonat seiner Anmeldung. Monat 0 ist der Anmeldemonat, Monat 1 der folgende Kalendermonat.

Die Ergebniswerte wurden mit den am 9. Oktober 2026 in Beekeeper geteilten Kontrollen abgeglichen. SQL-Beispiele entsprechen der aktuellen SQL-Fassung. Nicht erneut geprüfte historische Angaben sind gesondert gekennzeichnet.

## Nutzer je Anmeldemonat

### Abfrage

```sql
SELECT DATE_TRUNC('month', signup_date)::date AS kohortenmonat,
       COUNT(DISTINCT user_sk) AS kohortengroesse
FROM public.dim_user
GROUP BY DATE_TRUNC('month', signup_date)::date ORDER BY kohortenmonat;
```

### Bestätigtes Ergebnis

| Anmeldemonat 2024 | Nutzer |
|---|---|
| 1 | 42 |
| 2 | 36 |
| 3 | 49 |
| 4 | 37 |
| 5 | 46 |
| 6 | 33 |
| 7 | 35 |
| 8 | 51 |
| 9 | 40 |
| 10 | 46 |
| 11 | 39 |
| 12 | 46 |

### Einordnung

Die Größen summieren sich auf 500 Nutzer. August ist mit 51 Nutzern die größte Kohorte. Die Kohortengröße bleibt als Nenner für die Retention unverändert.


## Sessions vor dem genauen Anmeldetag prüfen

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

| Monat 2024 | Session im Monat | Ab Anmeldetag | Vor Anmeldetag |
|---|---|---|---|
| 1 | 42 | 18 | 24 |
| 2 | 36 | 11 | 25 |
| 3 | 49 | 24 | 25 |
| 4 | 37 | 16 | 21 |
| 5 | 46 | 16 | 30 |
| 6 | 33 | 10 | 23 |
| 7 | 35 | 10 | 25 |
| 8 | 51 | 17 | 34 |
| 9 | 40 | 16 | 24 |
| 10 | 46 | 13 | 33 |
| 11 | 39 | 17 | 22 |
| 12 | 46 | 18 | 28 |

### Einordnung

314 Sessions liegen 1 bis 27 Tage vor dem Anmeldetag, jeweils im Anmeldemonat. Sie werden in der aktuellen Retention ausgeschlossen. Insgesamt haben 186 von 500 Nutzern im Monat 0 eine Session ab Anmeldedatum (37,2 %). Die Ursache der Datumsabweichung ist nicht geklärt.


## Retention je Kohorte und Monatsnummer

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

Die aktuelle Ergebnisanzeige enthält 198 Zeilen. Der kontrollierte Januar Ausschnitt lautet:

| Monatsnummer | Aktive Nutzer | Kohortengröße | Retention |
|---|---|---|---|
| 0 | 18 | 42 | 42,86 % |
| 1 | 32 | 42 | 76,19 % |
| 2 | 25 | 42 | 59,52 % |
| 3 | 16 | 42 | 38,10 % |
| 4 | 14 | 42 | 33,33 % |
| 5 | 6 | 42 | 14,29 % |
| 6 | 5 | 42 | 11,90 % |
| 7 | 4 | 42 | 9,52 % |
| 8 | 1 | 42 | 2,38 % |
| 9 | 2 | 42 | 4,76 % |

### Einordnung

Mehrere Sessions eines Nutzers zählen pro Monat nur einmal. Retention kann steigen, wenn Nutzer zurückkehren. Beobachtete Kohortenmonate ohne Session werden mit 0 ausgegeben. Der dokumentierte Ausschnitt bestätigt die Januar-Werte, nicht eine Einzelkontrolle aller 198 Zeilen. Der letzte Event-Monat gilt konservativ als unvollständig und wird ausgeschlossen; eine vollständige Erfassung früherer Monate ist damit nicht bewiesen.


## Monat 1 Retention nach Akquisitionskanal

### Abfrage

```sql
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
```

### Bestätigtes Ergebnis

| Kanal | Anmeldungen | Aktiv in Monat 1 | Retention |
|---|---|---|---|
| Email | 93 | 68 | 73,12 % |
| Paid Search | 110 | 78 | 70,91 % |
| Social | 89 | 63 | 70,79 % |
| Organic | 106 | 74 | 69,81 % |
| Referral | 102 | 69 | 67,65 % |

### Einordnung

Email führt. Insgesamt bleiben 352 von 500 Nutzern im Folgemonat aktiv, also 70,40 %. Der LEFT JOIN erhält Nutzer ohne Session im Nenner. Die aktuelle Abfrage schließt Kohorten aus, deren Monat 1 nach der angenommenen Beobachtungsgrenze liegt. Diese Grenze wird aus dem letzten Event-Monat abgeleitet und benötigt für produktive Daten eine belegte Exportgrenze.




## Hinweise für die Veröffentlichung

Keine Zugangsdaten oder echten Ergebnisexporte veröffentlichen. Personenbezogene Kundennamen wurden in dieser Fassung entfernt. Einzelkennungen in Beispielen sind nicht automatisch anonym; die Herkunft und Freigabe der Übungsdaten sind separat zu klären. Umsatzwährung nicht ohne Quelldokumentation voraussetzen.

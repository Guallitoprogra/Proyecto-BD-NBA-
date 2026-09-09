-- Etapa 3
-- Preguntas propias
-- ============================================================
-- ETAPA 3 - ANALISIS PARA LA DECISION DE INVERSION
-- ============================================================

-- A. CONSISTENCIA DEPORTIVA
-- Objetivo:
-- Medir el rendimiento de cada equipo entre 2015 y 2020.
-- Se calcula el porcentaje de victorias de cada temporada,
-- su promedio y la variabilidad entre temporadas.

WITH team_games AS (
    SELECT
        season_start_year,
        home_team_id AS team_id,
        (home_win_loss = 'W')::int AS win
    FROM game
    WHERE season_start_year BETWEEN 2015 AND 2020

    UNION ALL

    SELECT
        season_start_year,
        away_team_id AS team_id,
        (away_win_loss = 'W')::int AS win
    FROM game
    WHERE season_start_year BETWEEN 2015 AND 2020
),
season_win_rates AS (
    SELECT
        season_start_year,
        team_id,
        AVG(win::numeric) AS win_rate
    FROM team_games
    GROUP BY season_start_year, team_id
)
SELECT
    t.full_name AS team_name,
    ROUND(AVG(swr.win_rate), 4) AS avg_win_rate,
    ROUND(STDDEV_POP(swr.win_rate), 4) AS win_rate_variability,
    COUNT(*) AS seasons_analyzed
FROM season_win_rates swr
JOIN team t
    ON t.team_id = swr.team_id
GROUP BY t.team_id, t.full_name
HAVING COUNT(*) >= 5
ORDER BY
    avg_win_rate DESC,
    win_rate_variability ASC;

-- ============================================================
-- B. TENDENCIA DE CRECIMIENTO
-- Objetivo:
-- Comparar el porcentaje de victorias de 2015 contra 2020
-- para identificar los equipos que mas mejoraron.
-- ============================================================

-- Pregunta 1
-- ¿Qué equipos mejoraron más su porcentaje de victorias entre la temporada 2015 y la temporada 2020?
WITH team_results AS (
    SELECT
        season_start_year,
        home_team_id AS team_id,
        (home_win_loss = 'W')::int AS win
    FROM game
    WHERE season_start_year IN (2015, 2020)

    UNION ALL

    SELECT
        season_start_year,
        away_team_id AS team_id,
        (away_win_loss = 'W')::int AS win
    FROM game
    WHERE season_start_year IN (2015, 2020)
),
season_rates AS (
    SELECT
        season_start_year,
        team_id,
        AVG(win::numeric) AS win_rate
    FROM team_results
    GROUP BY season_start_year, team_id
)
SELECT
    t.full_name AS team_name,

    ROUND(
        MAX(sr.win_rate) FILTER (WHERE sr.season_start_year = 2015),
        4
    ) AS win_rate_2015,

    ROUND(
        MAX(sr.win_rate) FILTER (WHERE sr.season_start_year = 2020),
        4
    ) AS win_rate_2020,

    ROUND(
        MAX(sr.win_rate) FILTER (WHERE sr.season_start_year = 2020)
        -
        MAX(sr.win_rate) FILTER (WHERE sr.season_start_year = 2015),
        4
    ) AS improvement

FROM season_rates sr
JOIN team t
    ON t.team_id = sr.team_id

GROUP BY t.team_id, t.full_name

HAVING
    COUNT(*) FILTER (WHERE sr.season_start_year = 2015) > 0
    AND
    COUNT(*) FILTER (WHERE sr.season_start_year = 2020) > 0

ORDER BY improvement DESC;

-- ============================================================
-- C. MARGEN PROMEDIO DE PUNTOS
-- Objetivo:
-- Medir la diferencia promedio de puntos de cada equipo
-- entre 2015 y 2020 para identificar equipos que ganan
-- con mayor solidez.
-- ============================================================

WITH team_point_margins AS (
    SELECT
        season_start_year,
        home_team_id AS team_id,
        home_points - away_points AS point_margin
    FROM game
    WHERE season_start_year BETWEEN 2015 AND 2020
      AND home_points IS NOT NULL
      AND away_points IS NOT NULL

    UNION ALL

    SELECT
        season_start_year,
        away_team_id AS team_id,
        away_points - home_points AS point_margin
    FROM game
    WHERE season_start_year BETWEEN 2015 AND 2020
      AND home_points IS NOT NULL
      AND away_points IS NOT NULL
)
SELECT
    t.full_name AS team_name,
    ROUND(AVG(tpm.point_margin), 2) AS avg_point_margin,
    COUNT(*) AS games_analyzed
FROM team_point_margins tpm
JOIN team t
    ON t.team_id = tpm.team_id
GROUP BY t.team_id, t.full_name
ORDER BY avg_point_margin DESC;

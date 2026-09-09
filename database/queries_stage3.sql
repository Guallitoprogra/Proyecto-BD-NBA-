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

-- ============================================================
-- D. EFICIENCIA FINANCIERA
-- Objetivo:
-- Comparar el rendimiento deportivo con el gasto salarial
-- para medir qué equipos obtienen más victorias por cada
-- millón de dólares de nómina.
-- ============================================================

WITH team_results AS (
    SELECT
        home_team_id AS team_id,
        (home_win_loss = 'W')::int AS win
    FROM game
    WHERE season_start_year = 2020

    UNION ALL

    SELECT
        away_team_id AS team_id,
        (away_win_loss = 'W')::int AS win
    FROM game
    WHERE season_start_year = 2020
),
team_performance AS (
    SELECT
        team_id,
        COUNT(*) AS games_played,
        SUM(win) AS wins,
        AVG(win::numeric) AS win_rate
    FROM team_results
    GROUP BY team_id
)
SELECT
    t.full_name AS team_name,
    tp.games_played,
    tp.wins,
    ROUND(tp.win_rate, 4) AS win_rate,
    ts.salary_2020_21 AS team_salary,
    ROUND(
        tp.wins / NULLIF(ts.salary_2020_21 / 1000000.0, 0),
        4
    ) AS wins_per_million
FROM team_performance tp
JOIN team t
    ON t.team_id = tp.team_id
JOIN team_salary ts
    ON LOWER(TRIM(ts.team_name)) = LOWER(TRIM(t.full_name))
WHERE ts.salary_2020_21 IS NOT NULL
ORDER BY wins_per_million DESC;

-- ============================================================
-- E. CALIDAD DEL TALENTO - NBA API
-- Objetivo:
-- Comparar la calidad del talento de cada equipo utilizando
-- las estadisticas de jugadores de la temporada 2021-22
-- obtenidas mediante NBA API.
-- ============================================================

SELECT
    t.full_name AS team_name,
    COUNT(pss.player_id) AS players_analyzed,
    ROUND(AVG(pss.points), 2) AS avg_points,
    ROUND(AVG(pss.assists), 2) AS avg_assists,
    ROUND(AVG(pss.rebounds), 2) AS avg_rebounds,
    ROUND(AVG(pss.plus_minus), 2) AS avg_plus_minus,
    ROUND(
        AVG(pss.points)
        + AVG(pss.assists)
        + AVG(pss.rebounds),
        2
    ) AS talent_score
FROM player_season_stat pss
JOIN team t
    ON t.team_id = pss.team_id
WHERE pss.season = '2021-22'
  AND pss.team_id <> 0
GROUP BY
    t.team_id,
    t.full_name
ORDER BY talent_score DESC;

-- ============================================================
-- F. DEPENDENCIA DE UNA ESTRELLA
-- Objetivo:
-- Medir cuanto depende cada equipo de su maximo anotador
-- durante la temporada 2021-22.
-- Un porcentaje alto indica mayor dependencia de una estrella.
-- ============================================================

WITH team_scoring AS (
    SELECT
        team_id,
        SUM(points) AS total_player_points,
        MAX(points) AS top_scorer_points
    FROM player_season_stat
    WHERE season = '2021-22'
      AND team_id <> 0
      AND points IS NOT NULL
    GROUP BY team_id
),
top_scorer AS (
    SELECT DISTINCT ON (team_id)
        team_id,
        player_name AS top_scorer_name,
        points AS top_scorer_points
    FROM player_season_stat
    WHERE season = '2021-22'
      AND team_id <> 0
      AND points IS NOT NULL
    ORDER BY
        team_id,
        points DESC,
        player_name
)
SELECT
    t.full_name AS team_name,
    tsr.top_scorer_name,
    ROUND(ts.top_scorer_points, 2) AS top_scorer_points,
    ROUND(ts.total_player_points, 2) AS total_player_points,
    ROUND(
        (ts.top_scorer_points / NULLIF(ts.total_player_points, 0)) * 100,
        2
    ) AS star_dependency_pct
FROM team_scoring ts
JOIN top_scorer tsr
    ON tsr.team_id = ts.team_id
JOIN team t
    ON t.team_id = ts.team_id
ORDER BY star_dependency_pct DESC;
-- ============================================================
-- G. RANKING FINAL DE INVERSION
-- Objetivo:
-- Combinar rendimiento deportivo, eficiencia financiera
-- y calidad del talento en un indice final de inversion.
--
-- Pesos:
-- 33.33% rendimiento deportivo
-- 33.33% eficiencia financiera
-- 33.33% calidad del talento
-- ============================================================

WITH team_results AS (
    SELECT
        home_team_id AS team_id,
        (home_win_loss = 'W')::int AS win
    FROM game
    WHERE season_start_year = 2020

    UNION ALL

    SELECT
        away_team_id AS team_id,
        (away_win_loss = 'W')::int AS win
    FROM game
    WHERE season_start_year = 2020
),

performance AS (
    SELECT
        team_id,
        AVG(win::numeric) AS win_rate,
        SUM(win) AS wins
    FROM team_results
    GROUP BY team_id
),

financial AS (
    SELECT
        p.team_id,
        p.wins / NULLIF(ts.salary_2020_21 / 1000000.0, 0)
            AS wins_per_million
    FROM performance p
    JOIN team t
        ON t.team_id = p.team_id
    JOIN team_salary ts
        ON LOWER(TRIM(ts.team_name)) = LOWER(TRIM(t.full_name))
    WHERE ts.salary_2020_21 IS NOT NULL
),

talent AS (
    SELECT
        team_id,
        AVG(points)
        + AVG(assists)
        + AVG(rebounds) AS talent_score
    FROM player_season_stat
    WHERE season = '2021-22'
      AND team_id <> 0
    GROUP BY team_id
),

metrics AS (
    SELECT
        t.team_id,
        t.full_name AS team_name,
        p.win_rate,
        f.wins_per_million,
        ta.talent_score
    FROM team t
    JOIN performance p
        ON p.team_id = t.team_id
    JOIN financial f
        ON f.team_id = t.team_id
    JOIN talent ta
        ON ta.team_id = t.team_id
),

normalized AS (
    SELECT
        *,
        100 * (
            win_rate - MIN(win_rate) OVER ()
        ) / NULLIF(
            MAX(win_rate) OVER () - MIN(win_rate) OVER (),
            0
        ) AS performance_score,

        100 * (
            wins_per_million - MIN(wins_per_million) OVER ()
        ) / NULLIF(
            MAX(wins_per_million) OVER ()
            - MIN(wins_per_million) OVER (),
            0
        ) AS financial_score,

        100 * (
            talent_score - MIN(talent_score) OVER ()
        ) / NULLIF(
            MAX(talent_score) OVER ()
            - MIN(talent_score) OVER (),
            0
        ) AS talent_score_normalized

    FROM metrics
),

final_ranking AS (
    SELECT
        team_name,

        ROUND(win_rate, 4) AS win_rate,

        ROUND(wins_per_million, 4)
            AS wins_per_million,

        ROUND(talent_score, 2)
            AS talent_score,

        ROUND(performance_score, 2)
            AS performance_score,

        ROUND(financial_score, 2)
            AS financial_score,

        ROUND(talent_score_normalized, 2)
            AS talent_score_normalized,

        ROUND(
            performance_score * 0.3333
            + financial_score * 0.3333
            + talent_score_normalized * 0.3334,
            2
        ) AS investment_score

    FROM normalized
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY investment_score DESC
    ) AS ranking,

    team_name,
    win_rate,
    wins_per_million,
    talent_score,
    performance_score,
    financial_score,
    talent_score_normalized,
    investment_score

FROM final_ranking

ORDER BY investment_score DESC
LIMIT 5;
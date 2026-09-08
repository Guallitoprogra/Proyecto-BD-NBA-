-- Etapa 3
-- Preguntas propias

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


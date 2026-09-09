-- 1A. Jugador activo más alto

SELECT
    p.player_id,
    p.full_name,
    pa.height,
    pa.height::NUMERIC AS height_inches
FROM player p
JOIN player_attribute pa
    ON pa.player_id = p.player_id
WHERE p.is_active = TRUE
  AND pa.height ~ '^[0-9]+(\.[0-9]+)?$'
ORDER BY pa.height::NUMERIC DESC
LIMIT 1;

-- 1B. Jugador activo más bajo
SELECT
    p.player_id,
    p.full_name,
    pa.height,
    pa.height::NUMERIC AS height_inches
FROM player p
JOIN player_attribute pa
    ON pa.player_id = p.player_id
WHERE p.is_active = TRUE
  AND pa.height ~ '^[0-9]+(\.[0-9]+)?$'
ORDER BY pa.height::NUMERIC ASC
LIMIT 1;

-- 2. Promedio de puntos anotados y recibidos por equipo y temporada.

WITH team_games AS (
    SELECT season_start_year, home_team_id AS team_id, home_team_name AS team_name,
           home_points AS points_for, away_points AS points_against
    FROM game
    UNION ALL
    SELECT season_start_year, away_team_id, away_team_name,
           away_points, home_points
    FROM game
)
SELECT season_start_year, team_id, MAX(team_name) AS team_name,
       ROUND(AVG(points_for), 2) AS avg_points_for,
       ROUND(AVG(points_against), 2) AS avg_points_against
FROM team_games
WHERE season_start_year BETWEEN 2015 AND 2020
  AND points_for IS NOT NULL AND points_against IS NOT NULL
GROUP BY season_start_year, team_id
ORDER BY season_start_year, team_name;

-- 3. Top 5 de árbitros por cantidad de derrotas visitantes.

SELECT o.official_id,
       concat_ws(' ', o.first_name, o.last_name) AS official_name,
       COUNT(*) AS away_losses
FROM game g
JOIN game_official gof ON gof.game_id = g.game_id
JOIN official o ON o.official_id = gof.official_id
WHERE g.away_win_loss = 'L'
GROUP BY o.official_id, o.first_name, o.last_name
ORDER BY away_losses DESC, official_name
LIMIT 5;

-- 4. Nómina y valor deportivo en 2020-21, última temporada previa a invertir.
-- Valor = PTS + AST + REB por partido; mínimo 20 juegos.
-- No confundimos salario con rendimiento. La correlación describe asociación.
WITH talent AS (
    SELECT team_id, MAX(points + assists + rebounds) AS best_player_value
    FROM player_season_stat WHERE season='2020-21' AND games_played >= 20
    GROUP BY team_id
), comparison AS (
    SELECT t.full_name AS team_name, ts.salary_2020_21 AS payroll,
           ta.best_player_value
    FROM team t JOIN team_salary ts ON lower(t.full_name)=lower(ts.team_name)
    LEFT JOIN talent ta ON ta.team_id=t.team_id
)
SELECT *, RANK() OVER (ORDER BY payroll DESC) AS payroll_rank,
       RANK() OVER (ORDER BY best_player_value DESC NULLS LAST) AS talent_rank,
       (SELECT corr(payroll::float, best_player_value::float) FROM comparison)
           AS salary_talent_correlation
FROM comparison ORDER BY payroll DESC;

-- 5A. Temporada(s) con mayor cantidad de partidos.

WITH games_per_season AS (
    SELECT
        season_start_year,
        COUNT(*) AS total_games
    FROM game
    GROUP BY season_start_year
)

SELECT
    season_start_year,
    total_games
FROM games_per_season
WHERE total_games = (
    SELECT MAX(total_games)
    FROM games_per_season
)
ORDER BY season_start_year;

-- 5B. Temporada con mayor duración.

SELECT
    season_start_year,
    MIN(game_date) AS first_game,
    MAX(game_date) AS last_game,
    MAX(game_date) - MIN(game_date) AS duration_days
FROM game
GROUP BY season_start_year
ORDER BY duration_days DESC
LIMIT 1;

-- 6. Mayor margen promedio por partido en 2017 y 2018.

WITH team_margins AS (
    SELECT season_start_year, home_team_id AS team_id, home_team_name AS team_name,
           home_points - away_points AS margin
    FROM game
    UNION ALL
    SELECT season_start_year, away_team_id, away_team_name,
           away_points - home_points
    FROM game
), ranked AS (
    SELECT season_start_year, team_id, MAX(team_name) AS team_name,
           ROUND(AVG(margin), 2) AS avg_margin,
           RANK() OVER (PARTITION BY season_start_year ORDER BY AVG(margin) DESC) AS position
    FROM team_margins
    WHERE season_start_year IN (2017, 2018) AND margin IS NOT NULL
    GROUP BY season_start_year, team_id
)
SELECT season_start_year, team_id, team_name, avg_margin
FROM ranked
WHERE position = 1
ORDER BY season_start_year;

-- 7. Valor deportivo del draft 2018 en la misma temporada 2020-21.
-- Se enlaza por ID y se muestran empates. 20 juegos evitan muestras mínimas.
WITH candidates AS (
    SELECT p.player_id, MAX(p.player_name) AS player_name, SUM(p.games_played) AS games_played,
           ROUND(SUM(p.points*p.games_played)/SUM(p.games_played),2) AS points,
           ROUND(SUM(p.assists*p.games_played)/SUM(p.games_played),2) AS assists,
           ROUND(SUM(p.rebounds*p.games_played)/SUM(p.games_played),2) AS rebounds,
           ROUND(SUM((p.points+p.assists+p.rebounds)*p.games_played)/SUM(p.games_played),2) AS player_value
    FROM player_season_stat p
    WHERE p.season='2020-21' AND p.games_played>0
      AND EXISTS (SELECT 1 FROM draft_pick d
                  WHERE d.player_id=p.player_id AND d.draft_year=2018)
    GROUP BY p.player_id HAVING SUM(p.games_played)>=20
)
SELECT * FROM candidates
WHERE player_value=(SELECT MAX(player_value) FROM candidates)
ORDER BY player_id;

-- 8. Top 5 de estados con mayor gasto salarial
-- en 2020-21 y 2021-22.

WITH state_salaries AS (

    SELECT
        t.state,
        '2020-21' AS season,
        ts.salary_2020_21 AS salary
    FROM team_salary ts
    JOIN team t
        ON LOWER(ts.team_name) = LOWER(t.full_name)

    UNION ALL

    SELECT
        t.state,
        '2021-22' AS season,
        ts.salary_2021_22 AS salary
    FROM team_salary ts
    JOIN team t
        ON LOWER(ts.team_name) = LOWER(t.full_name)
),

totals AS (
    SELECT
        season,
        state,
        SUM(salary) AS total_salary
    FROM state_salaries
    WHERE salary IS NOT NULL
    GROUP BY season, state
),

ranked AS (
    SELECT
        season,
        state,
        total_salary,
        RANK() OVER (
            PARTITION BY season
            ORDER BY total_salary DESC
        ) AS position
    FROM totals
)

SELECT
    season,
    state,
    total_salary,
    position
FROM ranked
WHERE position <= 5
ORDER BY season, position;

-- Pregunta propia A. Consistencia: victorias y porcentaje por temporada.

WITH team_results AS (
    SELECT season_start_year, home_team_id AS team_id, home_team_name AS team_name,
           (home_win_loss = 'W')::int AS win
    FROM game
    UNION ALL
    SELECT season_start_year, away_team_id, away_team_name,
           (away_win_loss = 'W')::int
    FROM game
)
SELECT season_start_year, team_id, MAX(team_name) AS team_name,
       SUM(win) AS wins, COUNT(*) AS games,
       ROUND(SUM(win)::numeric / NULLIF(COUNT(*), 0), 4) AS win_rate
FROM team_results
WHERE season_start_year BETWEEN 2015 AND 2020
GROUP BY season_start_year, team_id
ORDER BY season_start_year, win_rate DESC;

-- Pregunta propia B. Eficiencia salarial aproximada en 2020/21.

WITH results AS (
    SELECT home_team_id AS team_id, (home_win_loss = 'W')::int AS win
    FROM game WHERE season_start_year = 2020
    UNION ALL
    SELECT away_team_id, (away_win_loss = 'W')::int
    FROM game WHERE season_start_year = 2020
), wins AS (
    SELECT team_id, SUM(win) AS wins
    FROM results GROUP BY team_id
)
SELECT t.full_name AS team_name, w.wins, ts.salary_2020_21,
       ROUND(w.wins / NULLIF(ts.salary_2020_21 / 1000000, 0), 3)
           AS wins_per_million
FROM wins w
JOIN team t ON t.team_id = w.team_id
JOIN team_salary ts ON lower(ts.team_name) = lower(t.full_name)
ORDER BY wins_per_million DESC NULLS LAST;

-- Consultas iniciales. Cada resultado debe revisarse y documentarse.

-- 1A. Jugador activo más alto.
-- HEIGHT viene como texto (por ejemplo 6-11), por eso se convierte a pulgadas.
WITH active_heights AS (
    SELECT p.player_id, p.full_name, pa.height,
           split_part(pa.height, '-', 1)::int * 12
             + split_part(pa.height, '-', 2)::int AS height_inches
    FROM player p
    JOIN player_attribute pa ON pa.player_id = p.player_id
    WHERE p.is_active AND pa.height ~ '^[0-9]+-[0-9]+$'
)
SELECT * FROM active_heights
ORDER BY height_inches DESC, full_name
LIMIT 1;

-- 1B. Jugador activo más bajo.
WITH active_heights AS (
    SELECT p.player_id, p.full_name, pa.height,
           split_part(pa.height, '-', 1)::int * 12
             + split_part(pa.height, '-', 2)::int AS height_inches
    FROM player p
    JOIN player_attribute pa ON pa.player_id = p.player_id
    WHERE p.is_active AND pa.height ~ '^[0-9]+-[0-9]+$'
)
SELECT * FROM active_heights
ORDER BY height_inches, full_name
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
    SELECT home_team_name AS team_name, (home_win_loss = 'W')::int AS win
    FROM game WHERE season_start_year = 2020
    UNION ALL
    SELECT away_team_name, (away_win_loss = 'W')::int
    FROM game WHERE season_start_year = 2020
), wins AS (
    SELECT team_name, SUM(win) AS wins
    FROM results GROUP BY team_name
)
SELECT w.team_name, w.wins, ts.salary_2020_21,
       ROUND(w.wins / NULLIF(ts.salary_2020_21 / 1000000, 0), 3)
           AS wins_per_million
FROM wins w
JOIN team_salary ts ON lower(ts.team_name) = lower(w.team_name)
ORDER BY wins_per_million DESC NULLS LAST;

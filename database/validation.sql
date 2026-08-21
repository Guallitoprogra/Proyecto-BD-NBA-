-- Conteos y controles rápidos después de la carga.
SELECT 'team' AS table_name, COUNT(*) AS rows FROM team
UNION ALL SELECT 'player', COUNT(*) FROM player
UNION ALL SELECT 'player_attribute', COUNT(*) FROM player_attribute
UNION ALL SELECT 'game', COUNT(*) FROM game
UNION ALL SELECT 'official', COUNT(*) FROM official
UNION ALL SELECT 'game_official', COUNT(*) FROM game_official
UNION ALL SELECT 'player_salary', COUNT(*) FROM player_salary
UNION ALL SELECT 'team_salary', COUNT(*) FROM team_salary
UNION ALL SELECT 'draft_pick', COUNT(*) FROM draft_pick
ORDER BY table_name;

-- Partidos sin marcador: deben analizarse antes de las consultas deportivas.
SELECT COUNT(*) AS games_without_complete_score
FROM game
WHERE home_points IS NULL OR away_points IS NULL;

-- Cobertura mínima solicitada: 2015/16 a 2020/21.
SELECT season_start_year, COUNT(*) AS games
FROM game
WHERE season_start_year BETWEEN 2015 AND 2020
GROUP BY season_start_year
ORDER BY season_start_year;

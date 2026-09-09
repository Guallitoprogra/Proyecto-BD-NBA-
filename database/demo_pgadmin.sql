-- Abrir en Query Tool de nba_project. Seleccionar y ejecutar cada consulta.
SELECT ranking,team_name,ROUND(investment_score,2) AS score
FROM v_investment_ranking ORDER BY ranking;

SELECT * FROM v_team_seasons WHERE season_start_year=2020 ORDER BY win_rate DESC;

SELECT * FROM v_team_talent ORDER BY talent DESC;

SELECT season,COUNT(*) AS records,COUNT(DISTINCT player_id) AS players
FROM player_season_stat GROUP BY season ORDER BY season;

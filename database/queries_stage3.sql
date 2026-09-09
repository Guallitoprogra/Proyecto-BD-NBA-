-- Ejecutar analytics_views.sql antes de este archivo.
-- A. Promedio y variabilidad en las seis temporadas.
SELECT t.full_name AS team_name,ROUND(AVG(s.win_rate),4) AS mean_win_rate,
 ROUND(STDDEV_POP(s.win_rate),4) AS variability,COUNT(*) AS seasons
FROM v_team_seasons s JOIN team t USING(team_id)
GROUP BY t.team_id,t.full_name HAVING COUNT(*)=6 ORDER BY mean_win_rate DESC;

-- B. Crecimiento: diferencia en puntos porcentuales, no crecimiento relativo.
SELECT team_name,ROUND(growth*100,2) AS growth_percentage_points
FROM v_investment_metrics ORDER BY growth DESC;

-- C. Margen medio por partido, ponderado por cantidad de juegos.
SELECT team_name,ROUND(mean_margin,2) AS mean_margin
FROM v_investment_metrics ORDER BY mean_margin DESC;

-- D. Victorias por millón de nómina. No equivale a rentabilidad monetaria.
SELECT team_name,wins,ROUND(win_rate,4) AS win_rate,payroll,
 ROUND(wins_per_million,4) AS wins_per_million
FROM v_investment_metrics ORDER BY wins_per_million DESC;

-- E. Promedios de jugador ponderados por juegos, no puntos totales del equipo.
SELECT t.full_name AS team_name,a.player_stints,ROUND(a.points,2) AS points,
 ROUND(a.assists,2) AS assists,ROUND(a.rebounds,2) AS rebounds,
 ROUND(a.plus_minus,2) AS plus_minus,ROUND(a.talent,2) AS talent
FROM v_team_talent a JOIN team t USING(team_id) ORDER BY talent DESC;

-- F. Proporción aproximada de puntos de la figura: PPG por juegos de su periodo.
-- PPG llega redondeado de NBA API; la proporción es una estimación.
SELECT t.full_name AS team_name,ROUND(a.dependency*100,2) AS dependency_pct
FROM v_team_talent a JOIN team t USING(team_id) ORDER BY dependency_pct DESC;

-- G. Ranking: un tercio para cada pilar. Ordenamos antes de redondear.
SELECT ranking,team_name,ROUND(performance_score,2) AS performance_score,
 ROUND(financial_score,2) AS financial_score,ROUND(talent_score,2) AS talent_score,
 ROUND(investment_score,2) AS investment_score
FROM v_investment_ranking ORDER BY ranking LIMIT 5;

-- H. Sensibilidad: ¿cambia el ganador al darle 50% a un pilar?
WITH weights(scenario,sport,finance,talent) AS (
 VALUES ('equilibrado',1.0/3,1.0/3,1.0/3),('deportivo',0.5,0.25,0.25),
        ('financiero',0.25,0.5,0.25),('talento',0.25,0.25,0.5)
), ranked AS (
 SELECT w.scenario,r.team_name,
  r.performance_score*w.sport+r.financial_score*w.finance+r.talent_score*w.talent AS score,
  ROW_NUMBER() OVER(PARTITION BY w.scenario ORDER BY
   r.performance_score*w.sport+r.financial_score*w.finance+r.talent_score*w.talent DESC,r.team_id) AS pos
 FROM weights w CROSS JOIN v_investment_ranking r
)
SELECT scenario,team_name,ROUND(score,2) AS score FROM ranked WHERE pos=1 ORDER BY scenario;

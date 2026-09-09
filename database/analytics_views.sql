-- Vistas para revisar la Etapa 3 desde pgAdmin.
-- Corte: temporada regular 2020-21. No se usan resultados de 2021-22.
CREATE OR REPLACE VIEW v_team_seasons AS
WITH games AS (
 SELECT season_start_year,home_team_id AS team_id,
        (home_points>away_points)::int AS win,home_points-away_points AS margin
 FROM game WHERE home_points IS NOT NULL AND away_points IS NOT NULL AND home_points<>away_points
 UNION ALL
 SELECT season_start_year,away_team_id,(away_points>home_points)::int,away_points-home_points
 FROM game WHERE home_points IS NOT NULL AND away_points IS NOT NULL AND home_points<>away_points
)
SELECT season_start_year,team_id,COUNT(*) AS games,SUM(win) AS wins,
 AVG(win::numeric) AS win_rate,AVG(margin) AS point_margin
FROM games WHERE season_start_year BETWEEN 2015 AND 2020
GROUP BY season_start_year,team_id;

CREATE OR REPLACE VIEW v_team_talent AS
SELECT team_id,COUNT(*) AS player_stints,
 SUM(points*games_played)/NULLIF(SUM(games_played),0) AS points,
 SUM(assists*games_played)/NULLIF(SUM(games_played),0) AS assists,
 SUM(rebounds*games_played)/NULLIF(SUM(games_played),0) AS rebounds,
 SUM(plus_minus*games_played)/NULLIF(SUM(games_played),0) AS plus_minus,
 SUM((points+assists+rebounds)*games_played)/NULLIF(SUM(games_played),0) AS talent,
 MAX(points*games_played)/NULLIF(SUM(points*games_played),0) AS dependency
FROM player_season_stat WHERE season='2020-21' AND team_id<>0 AND games_played>0
GROUP BY team_id;

CREATE OR REPLACE VIEW v_investment_metrics AS
WITH history AS (
 SELECT team_id,AVG(win_rate) AS mean_win_rate,STDDEV_POP(win_rate) AS variability,
        SUM(point_margin*games)/SUM(games) AS mean_margin,
        MAX(win_rate) FILTER(WHERE season_start_year=2020)
         -MAX(win_rate) FILTER(WHERE season_start_year=2015) AS growth
 FROM v_team_seasons GROUP BY team_id HAVING COUNT(*)=6
)
SELECT t.team_id,t.full_name AS team_name,h.mean_win_rate,h.variability,h.mean_margin,h.growth,
 s.win_rate,s.wins,ts.salary_2020_21 AS payroll,
 s.wins/NULLIF(ts.salary_2020_21/1000000,0) AS wins_per_million,
 a.talent,a.plus_minus,a.dependency
FROM team t JOIN history h USING(team_id)
JOIN v_team_seasons s ON s.team_id=t.team_id AND s.season_start_year=2020
JOIN team_salary ts ON lower(ts.team_name)=lower(t.full_name)
JOIN v_team_talent a ON a.team_id=t.team_id;

CREATE OR REPLACE VIEW v_investment_ranking AS
WITH n AS (
 SELECT *,
 100*(mean_win_rate-MIN(mean_win_rate) OVER())/NULLIF(MAX(mean_win_rate) OVER()-MIN(mean_win_rate) OVER(),0) AS n_win,
 100*(MAX(variability) OVER()-variability)/NULLIF(MAX(variability) OVER()-MIN(variability) OVER(),0) AS n_stability,
 100*(mean_margin-MIN(mean_margin) OVER())/NULLIF(MAX(mean_margin) OVER()-MIN(mean_margin) OVER(),0) AS n_margin,
 100*(growth-MIN(growth) OVER())/NULLIF(MAX(growth) OVER()-MIN(growth) OVER(),0) AS n_growth,
 100*(wins_per_million-MIN(wins_per_million) OVER())/NULLIF(MAX(wins_per_million) OVER()-MIN(wins_per_million) OVER(),0) AS financial_score,
 100*(talent-MIN(talent) OVER())/NULLIF(MAX(talent) OVER()-MIN(talent) OVER(),0) AS n_talent,
 100*(plus_minus-MIN(plus_minus) OVER())/NULLIF(MAX(plus_minus) OVER()-MIN(plus_minus) OVER(),0) AS n_plus_minus,
 100*(MAX(dependency) OVER()-dependency)/NULLIF(MAX(dependency) OVER()-MIN(dependency) OVER(),0) AS n_depth
 FROM v_investment_metrics
), pillars AS (
 SELECT *, (n_win+n_stability+n_margin+n_growth)/4 AS performance_score,
           (n_talent+n_plus_minus+n_depth)/3 AS talent_score
 FROM n
), scores AS (
 SELECT *, (performance_score+financial_score+talent_score)/3 AS investment_score
 FROM pillars
)
SELECT ROW_NUMBER() OVER(ORDER BY investment_score DESC,team_id) AS ranking,
 team_id,team_name,performance_score,financial_score,talent_score,investment_score
FROM scores;

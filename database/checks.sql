-- Estos controles lanzan un error si una carga queda incompleta.
DO $$
BEGIN
 IF (SELECT COUNT(*) FROM team)<>30 THEN RAISE EXCEPTION 'Faltan equipos'; END IF;
 IF (SELECT COUNT(*) FROM draft_pick)<>7890 THEN RAISE EXCEPTION 'Faltan selecciones del draft'; END IF;
 IF EXISTS (SELECT 1 FROM game WHERE home_points=away_points OR home_points IS NULL
            OR away_points IS NULL OR home_win_loss IS NULL OR away_win_loss IS NULL)
 THEN RAISE EXCEPTION 'Hay partidos sin resultado válido'; END IF;
 IF (SELECT COUNT(DISTINCT team_id) FROM player_season_stat WHERE season='2020-21')<>30
 THEN RAISE EXCEPTION 'Faltan equipos en NBA API'; END IF;
 IF (SELECT COUNT(*) FROM team_salary s JOIN team t ON lower(t.full_name)=lower(s.team_name))<>30
 THEN RAISE EXCEPTION 'El JOIN salarial pierde equipos'; END IF;
END $$;

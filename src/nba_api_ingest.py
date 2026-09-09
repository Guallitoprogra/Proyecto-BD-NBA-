from pathlib import Path
import os
import sys
from concurrent.futures import ThreadPoolExecutor

ROOT = Path(__file__).resolve().parents[1]
SEASON = os.getenv("NBA_SEASON", "2020-21")


def prepare_rows(records, season):
    """Convierte los registros del API al formato usado por PostgreSQL."""
    rows = []

    for r in records:
        rows.append((
            int(r["PLAYER_ID"]),
            season,
            int(r["TEAM_ID"]),
            r["PLAYER_NAME"],
            r["TEAM_ABBREVIATION"] or None,
            int(r["GP"]),
            float(r["PTS"]),
            float(r["AST"]),
            float(r["REB"]),
            float(r["PLUS_MINUS"]),
        ))

    return rows


def fetch_player_stats(season, team_id=None, per_mode='PerGame'):
    """Consulta NBA API y devuelve las estadísticas necesarias."""
    from nba_api.stats.endpoints import leaguedashplayerstats

    response = leaguedashplayerstats.LeagueDashPlayerStats(
        season=season,
        season_type_all_star="Regular Season",
        per_mode_detailed=per_mode,
        team_id_nullable=team_id or '',
        timeout=60,
    )

    data = response.get_data_frames()[0]

    columns = [
        "PLAYER_ID",
        "PLAYER_NAME",
        "TEAM_ID",
        "TEAM_ABBREVIATION",
        "GP",
        "PTS",
        "AST",
        "REB",
        "PLUS_MINUS",
    ]

    result = data[columns].copy()
    if per_mode == 'Totals':
        for column in ['PTS', 'AST', 'REB', 'PLUS_MINUS']:
            result[column] = (result[column] / result['GP'].replace(0, float('nan'))).round(1)
    if team_id:
        # El endpoint conserva a veces el ID del último equipo en la respuesta.
        # Las estadísticas están filtradas por el equipo solicitado.
        from nba_api.stats.static import teams
        result['TEAM_ID'] = team_id
        result['TEAM_ABBREVIATION'] = teams.find_team_name_by_id(team_id)['abbreviation']
    return result


def load_to_postgres(conn, rows):
    """Inserta o actualiza los datos descargados desde NBA API."""
    sql = """
        INSERT INTO player_season_stat (
            player_id,
            season,
            team_id,
            player_name,
            team_abbreviation,
            games_played,
            points,
            assists,
            rebounds,
            plus_minus
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (player_id, season, team_id)
        DO UPDATE SET
            player_name = EXCLUDED.player_name,
            team_abbreviation = EXCLUDED.team_abbreviation,
            games_played = EXCLUDED.games_played,
            points = EXCLUDED.points,
            assists = EXCLUDED.assists,
            rebounds = EXCLUDED.rebounds,
            plus_minus = EXCLUDED.plus_minus,
            loaded_at = CURRENT_TIMESTAMP
    """

    with conn.cursor() as cur:
        cur.execute('CREATE TEMP TABLE api_keys(player_id bigint,season text,team_id bigint) ON COMMIT DROP')
        cur.executemany('INSERT INTO api_keys VALUES (%s,%s,%s)',
                        [(r[0],r[1],r[2]) for r in rows])
        # Retiramos únicamente filas de esta temporada que no están en la descarga completa.
        cur.execute('''SELECT p.* FROM player_season_stat p
            WHERE p.season IN (SELECT season FROM api_keys)
            AND NOT EXISTS (SELECT 1 FROM api_keys k WHERE
              k.player_id=p.player_id AND k.season=p.season AND k.team_id=p.team_id)''')
        stale = cur.fetchall()
        if stale:
            import json
            backup=ROOT/'data'/'raw'/'api_previous_rows.json'
            backup.write_text(json.dumps(stale,default=str,ensure_ascii=False),encoding='utf-8')
            cur.execute('''DELETE FROM player_season_stat p
                WHERE p.season IN (SELECT season FROM api_keys)
                AND NOT EXISTS (SELECT 1 FROM api_keys k WHERE
                  k.player_id=p.player_id AND k.season=p.season AND k.team_id=p.team_id)''')
            print(f'Retiradas {len(stale)} filas anteriores; respaldo local: {backup.name}')
        cur.executemany(sql, rows)

    conn.commit()
    return len(rows)


def main():
    from dotenv import load_dotenv
    import psycopg

    load_dotenv(os.getenv('PROJECT_ENV_FILE', str(ROOT / '.env')))

    print(f"Consultando NBA API para la temporada {SEASON}...")

    try:
        # Cada consulta de equipo separa los periodos de jugadores traspasados.
        from nba_api.stats.static import teams
        import pandas as pd
        def fetch_team(t):
            cache = ROOT / 'data' / 'raw' / f"api_{SEASON}_{t['id']}.csv"
            if cache.exists():
                return pd.read_csv(cache)
            error = None
            for attempt in range(3):
                try:
                    frame = fetch_player_stats(SEASON, t['id'], 'PerGame' if attempt == 0 else 'Totals')
                    cache.parent.mkdir(parents=True, exist_ok=True)
                    frame.to_csv(cache, index=False)
                    print(f"API {t['abbreviation']}: {len(frame)} registros", flush=True)
                    return frame
                except Exception as exc:
                    error = exc
            raise RuntimeError(f"No se pudo consultar {t['abbreviation']}") from error
        with ThreadPoolExecutor(max_workers=3) as pool:
            frames = list(pool.map(fetch_team, teams.get_teams()))
        data = pd.concat(frames, ignore_index=True)
        if len(data['TEAM_ID'].unique()) != 30 or data.duplicated(['PLAYER_ID','TEAM_ID']).any():
            raise ValueError('La descarga debe cubrir 30 equipos sin duplicar jugador-equipo')
    except Exception as exc:
        print(f"ERROR consultando NBA API: {exc}", file=sys.stderr)
        return 1

    if data.empty:
        print("ERROR: NBA API no devolvió registros.", file=sys.stderr)
        return 1

    # Guardamos una copia local como evidencia de la ingesta.
    output = ROOT / "data" / "raw" / f"nba_api_player_stats_{SEASON.replace('-', '_')}.csv"
    output.parent.mkdir(parents=True, exist_ok=True)
    data.to_csv(output, index=False)

    rows = prepare_rows(data.to_dict("records"), SEASON)

    connection_kwargs = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": os.getenv("DB_PORT", "5432"),
        "dbname": os.getenv("DB_NAME", "nba_project"),
        "user": os.getenv("DB_USER", "postgres"),
        "password": os.getenv("DB_PASSWORD", ""),
    }

    try:
        with psycopg.connect(**connection_kwargs) as conn:
            total = load_to_postgres(conn, rows)
    except psycopg.Error as exc:
        print(f"ERROR cargando PostgreSQL: {exc}", file=sys.stderr)
        return 1

    print(f"OK: {total} registros jugador-equipo cargados desde NBA API.")
    print(f"Copia local: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

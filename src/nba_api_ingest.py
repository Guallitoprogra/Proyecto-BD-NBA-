from pathlib import Path
import os
import sys

ROOT = Path(__file__).resolve().parents[1]
SEASON = "2021-22"


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


def fetch_player_stats(season):
    """Consulta NBA API y devuelve las estadísticas necesarias."""
    from nba_api.stats.endpoints import leaguedashplayerstats

    response = leaguedashplayerstats.LeagueDashPlayerStats(
        season=season,
        season_type_all_star="Regular Season",
        per_mode_detailed="PerGame",
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

    return data[columns].copy()


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
        cur.executemany(sql, rows)

    conn.commit()
    return len(rows)


def main():
    from dotenv import load_dotenv
    import psycopg

    load_dotenv(ROOT / ".env")

    print(f"Consultando NBA API para la temporada {SEASON}...")

    try:
        data = fetch_player_stats(SEASON)
    except Exception as exc:
        print(f"ERROR consultando NBA API: {exc}", file=sys.stderr)
        return 1

    if data.empty:
        print("ERROR: NBA API no devolvió registros.", file=sys.stderr)
        return 1

    # Guardamos una copia local como evidencia de la ingesta.
    output = ROOT / "data" / "raw" / "nba_api_player_stats_2021_22.csv"
    output.parent.mkdir(parents=True, exist_ok=True)
    data.to_csv(output, index=False)

    rows = prepare_rows(data.to_dict("records"), SEASON)

    connection_kwargs = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": os.getenv("DB_PORT", "5432"),
        "dbname": os.getenv("DB_NAME", "nba_investment"),
        "user": os.getenv("DB_USER", "postgres"),
        "password": os.getenv("DB_PASSWORD", ""),
    }

    try:
        with psycopg.connect(**connection_kwargs) as conn:
            total = load_to_postgres(conn, rows)
    except psycopg.Error as exc:
        print(f"ERROR cargando PostgreSQL: {exc}", file=sys.stderr)
        return 1

    print(f"OK: {total} jugadores cargados desde NBA API.")
    print(f"Copia local: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Carga reproducible de los CSV principales a PostgreSQL.

Lee Data.zip directamente; no requiere extraer ni versionar archivos grandes.
"""

from __future__ import annotations

import csv
import io
import os
import sys
import zipfile
from collections.abc import Iterable, Iterator
from pathlib import Path

import psycopg
from dotenv import load_dotenv

csv.field_size_limit(10_000_000)
ROOT = Path(__file__).resolve().parents[1]


def blank_to_none(value: str | None):
    if value is None:
        return None
    value = value.strip()
    return value if value else None


def as_int(value: str | None):
    value = blank_to_none(value)
    if value is None:
        return None
    try:
        return int(float(value))
    except ValueError:
        # Algunos campos supuestamente numéricos usan etiquetas como "Undrafted".
        return None


def as_decimal(value: str | None):
    return blank_to_none(value)


def as_bool(value: str | None):
    value = (blank_to_none(value) or "").lower()
    if value in {"1", "true", "t", "yes", "y"}:
        return True
    if value in {"0", "false", "f", "no", "n"}:
        return False
    return None


def rows_from_zip(archive: zipfile.ZipFile, filename: str) -> Iterator[dict[str, str]]:
    member = f"Data/{filename}"
    with archive.open(member) as raw:
        with io.TextIOWrapper(raw, encoding="utf-8-sig", errors="replace", newline="") as text:
            yield from csv.DictReader(text)


def batches(rows: Iterable[tuple], size: int = 2_000) -> Iterator[list[tuple]]:
    batch: list[tuple] = []
    for row in rows:
        batch.append(row)
        if len(batch) >= size:
            yield batch
            batch = []
    if batch:
        yield batch


def execute_batches(conn: psycopg.Connection, sql: str, rows: Iterable[tuple]) -> int:
    total = 0
    with conn.cursor() as cur:
        for batch in batches(rows):
            cur.executemany(sql, batch)
            total += len(batch)
    conn.commit()
    return total


def load_teams(conn, archive):
    sql = """INSERT INTO team
        (team_id, full_name, abbreviation, nickname, city, state, year_founded)
        VALUES (%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (team_id) DO UPDATE SET
        full_name=EXCLUDED.full_name, abbreviation=EXCLUDED.abbreviation,
        nickname=EXCLUDED.nickname, city=EXCLUDED.city, state=EXCLUDED.state,
        year_founded=EXCLUDED.year_founded"""
    rows = ((as_int(r["id"]), r["full_name"], r["abbreviation"],
             blank_to_none(r["nickname"]), blank_to_none(r["city"]),
             blank_to_none(r["state"]), as_int(r["year_founded"]))
            for r in rows_from_zip(archive, "Team.csv"))
    return execute_batches(conn, sql, rows)


def load_players(conn, archive):
    sql = """INSERT INTO player
        (player_id, full_name, first_name, last_name, is_active)
        VALUES (%s,%s,%s,%s,%s)
        ON CONFLICT (player_id) DO UPDATE SET
        full_name=EXCLUDED.full_name, first_name=EXCLUDED.first_name,
        last_name=EXCLUDED.last_name, is_active=EXCLUDED.is_active"""
    rows = ((as_int(r["id"]), r["full_name"], blank_to_none(r["first_name"]),
             blank_to_none(r["last_name"]), as_bool(r["is_active"]) or False)
            for r in rows_from_zip(archive, "Player.csv"))
    return execute_batches(conn, sql, rows)


def load_player_attributes(conn, archive):
    sql = """INSERT INTO player_attribute
        (player_id,birthdate,school,country,height,weight,season_experience,
         position,roster_status,current_team_id,current_team_name,from_year,to_year,
         draft_year,draft_round,draft_number,points,assists,rebounds,
         all_star_appearances,pie)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (player_id) DO UPDATE SET
        birthdate=EXCLUDED.birthdate, school=EXCLUDED.school, country=EXCLUDED.country,
        height=EXCLUDED.height, weight=EXCLUDED.weight,
        season_experience=EXCLUDED.season_experience, position=EXCLUDED.position,
        roster_status=EXCLUDED.roster_status, current_team_id=EXCLUDED.current_team_id,
        current_team_name=EXCLUDED.current_team_name, from_year=EXCLUDED.from_year,
        to_year=EXCLUDED.to_year, draft_year=EXCLUDED.draft_year,
        draft_round=EXCLUDED.draft_round, draft_number=EXCLUDED.draft_number,
        points=EXCLUDED.points, assists=EXCLUDED.assists, rebounds=EXCLUDED.rebounds,
        all_star_appearances=EXCLUDED.all_star_appearances, pie=EXCLUDED.pie"""
    def transform(r):
        birthdate = blank_to_none(r["BIRTHDATE"])
        if birthdate:
            birthdate = birthdate[:10]
        return (as_int(r["ID"]), birthdate, blank_to_none(r["SCHOOL"]),
                blank_to_none(r["COUNTRY"]), blank_to_none(r["HEIGHT"]),
                as_decimal(r["WEIGHT"]), as_int(r["SEASON_EXP"]),
                blank_to_none(r["POSITION"]), blank_to_none(r["ROSTERSTATUS"]),
                as_int(r["TEAM_ID"]), blank_to_none(r["TEAM_NAME"]),
                as_int(r["FROM_YEAR"]), as_int(r["TO_YEAR"]),
                as_int(r["DRAFT_YEAR"]), as_int(r["DRAFT_ROUND"]),
                as_int(r["DRAFT_NUMBER"]), as_decimal(r["PTS"]),
                as_decimal(r["AST"]), as_decimal(r["REB"]),
                as_int(r["ALL_STAR_APPEARANCES"]), as_decimal(r["PIE"]))
    return execute_batches(conn, sql, map(transform, rows_from_zip(archive, "Player_Attributes.csv")))


def load_games(conn, archive):
    sql = """INSERT INTO game
        (game_id,season_id,season_start_year,game_date,home_team_id,home_team_name,
         home_win_loss,home_points,away_team_id,away_team_name,away_win_loss,
         away_points,attendance)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (game_id) DO UPDATE SET
        season_id=EXCLUDED.season_id, season_start_year=EXCLUDED.season_start_year,
        game_date=EXCLUDED.game_date, home_team_id=EXCLUDED.home_team_id,
        home_team_name=EXCLUDED.home_team_name, home_win_loss=EXCLUDED.home_win_loss,
        home_points=EXCLUDED.home_points, away_team_id=EXCLUDED.away_team_id,
        away_team_name=EXCLUDED.away_team_name, away_win_loss=EXCLUDED.away_win_loss,
        away_points=EXCLUDED.away_points, attendance=EXCLUDED.attendance"""
    def transform(r):
        return (r["GAME_ID"], blank_to_none(r["SEASON_ID"]), as_int(r["SEASON"]),
                r["GAME_DATE"][:10], as_int(r["TEAM_ID_HOME"]),
                blank_to_none(r["TEAM_NAME_HOME"]), blank_to_none(r["WL_HOME"]),
                as_int(r["PTS_HOME"]), as_int(r["TEAM_ID_AWAY"]),
                blank_to_none(r["TEAM_NAME_AWAY"]), blank_to_none(r["WL_AWAY"]),
                as_int(r["PTS_AWAY"]), as_int(r["ATTENDANCE"]))
    return execute_batches(conn, sql, map(transform, rows_from_zip(archive, "Game.csv")))


def load_officials(conn, archive):
    source = list(rows_from_zip(archive, "Game_Officials.csv"))
    official_sql = """INSERT INTO official
        (official_id,first_name,last_name,jersey_number) VALUES (%s,%s,%s,%s)
        ON CONFLICT (official_id) DO UPDATE SET first_name=EXCLUDED.first_name,
        last_name=EXCLUDED.last_name, jersey_number=EXCLUDED.jersey_number"""
    unique = {}
    for r in source:
        unique[as_int(r["OFFICIAL_ID"])] = (
            as_int(r["OFFICIAL_ID"]), blank_to_none(r["FIRST_NAME"]),
            blank_to_none(r["LAST_NAME"]), blank_to_none(r["JERSEY_NUM"]))
    count = execute_batches(conn, official_sql, unique.values())
    link_sql = """INSERT INTO game_official (game_id,official_id) VALUES (%s,%s)
        ON CONFLICT DO NOTHING"""
    links = ((r["GAME_ID"], as_int(r["OFFICIAL_ID"])) for r in source)
    count += execute_batches(conn, link_sql, links)
    return count


def load_player_salaries(conn, archive):
    sql = """INSERT INTO player_salary
        (season,team_name,player_name,player_status,is_final_season,is_waived,
         is_on_roster,contract_detail,salary_value)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s) ON CONFLICT DO NOTHING"""
    rows = ((r["slugSeason"], r["nameTeam"], r["namePlayer"],
             blank_to_none(r["statusPlayer"]), as_bool(r["isFinalSeason"]),
             as_bool(r["isWaived"]), as_bool(r["isOnRoster"]),
             blank_to_none(r["typeContractDetail"]) or "", as_decimal(r["value"]))
            for r in rows_from_zip(archive, "Player_Salary.csv"))
    return execute_batches(conn, sql, rows)


def load_team_salaries(conn, archive):
    sql = """INSERT INTO team_salary
        (team_name,team_slug,salary_2020_21,salary_2021_22,salary_2022_23,
         salary_2023_24,salary_2024_25,salary_2025_26)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (team_name) DO UPDATE SET team_slug=EXCLUDED.team_slug,
        salary_2020_21=EXCLUDED.salary_2020_21,salary_2021_22=EXCLUDED.salary_2021_22,
        salary_2022_23=EXCLUDED.salary_2022_23,salary_2023_24=EXCLUDED.salary_2023_24,
        salary_2024_25=EXCLUDED.salary_2024_25,salary_2025_26=EXCLUDED.salary_2025_26"""
    rows = ((r["nameTeam"], r["slugTeam"], as_decimal(r["X2020-21"]),
             as_decimal(r["X2021-22"]), as_decimal(r["X2022-23"]),
             as_decimal(r["X2023-24"]), as_decimal(r["X2024-25"]),
             as_decimal(r["X2025-26"]))
            for r in rows_from_zip(archive, "Team_Salary.csv"))
    return execute_batches(conn, sql, rows)


def load_draft(conn, archive):
    sql = """INSERT INTO draft_pick
        (draft_year,overall_pick,round_number,round_pick,player_id,player_name,
         team_id,team_name,organization_from)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (draft_year,overall_pick) DO UPDATE SET
        round_number=EXCLUDED.round_number, round_pick=EXCLUDED.round_pick,
        player_id=EXCLUDED.player_id, player_name=EXCLUDED.player_name,
        team_id=EXCLUDED.team_id, team_name=EXCLUDED.team_name,
        organization_from=EXCLUDED.organization_from"""
    rows = ((as_int(r["yearDraft"]), as_int(r["numberPickOverall"]),
             as_int(r["numberRound"]), as_int(r["numberRoundPick"]),
             as_int(r["idPlayer"]), r["namePlayer"], as_int(r["idTeam"]),
             blank_to_none(r["nameTeam"]), blank_to_none(r["nameOrganizationFrom"]))
            for r in rows_from_zip(archive, "Draft.csv")
            if blank_to_none(r["yearDraft"]) and blank_to_none(r["numberPickOverall"]))
    return execute_batches(conn, sql, rows)


def main() -> int:
    load_dotenv(ROOT / ".env")
    zip_path = Path(os.environ.get("DATA_ZIP", ""))
    if not zip_path.is_file():
        print(f"ERROR: DATA_ZIP no apunta a un archivo válido: {zip_path}", file=sys.stderr)
        return 1

    connection_kwargs = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": os.getenv("DB_PORT", "5432"),
        "dbname": os.getenv("DB_NAME", "nba_investment"),
        "user": os.getenv("DB_USER", "postgres"),
        "password": os.getenv("DB_PASSWORD", ""),
    }

    loaders = [
        ("team", load_teams), ("player", load_players),
        ("player_attribute", load_player_attributes), ("game", load_games),
        ("official + game_official", load_officials),
        ("player_salary", load_player_salaries),
        ("team_salary", load_team_salaries), ("draft_pick", load_draft),
    ]
    try:
        with psycopg.connect(**connection_kwargs) as conn, zipfile.ZipFile(zip_path) as archive:
            for label, loader in loaders:
                count = loader(conn, archive)
                print(f"OK {label}: {count:,} filas procesadas")
    except (psycopg.Error, zipfile.BadZipFile, KeyError, ValueError) as exc:
        print(f"ERROR durante la carga: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

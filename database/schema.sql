-- Proyecto NBA - esquema inicial PostgreSQL
-- Se conservan nombres en snake_case y tipos explícitos.

BEGIN;

CREATE TABLE IF NOT EXISTS team (
    team_id         BIGINT PRIMARY KEY,
    full_name       TEXT NOT NULL,
    abbreviation    VARCHAR(5) NOT NULL,
    nickname        TEXT,
    city            TEXT,
    state           TEXT,
    year_founded    SMALLINT
);

CREATE TABLE IF NOT EXISTS player (
    player_id       BIGINT PRIMARY KEY,
    full_name       TEXT NOT NULL,
    first_name      TEXT,
    last_name       TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS player_attribute (
    player_id               BIGINT PRIMARY KEY REFERENCES player(player_id),
    birthdate               DATE,
    school                  TEXT,
    country                 TEXT,
    height                  VARCHAR(10),
    weight                  NUMERIC(6,2),
    season_experience       SMALLINT,
    position                VARCHAR(20),
    roster_status           TEXT,
    current_team_id         BIGINT,
    current_team_name       TEXT,
    from_year               SMALLINT,
    to_year                 SMALLINT,
    draft_year              SMALLINT,
    draft_round             SMALLINT,
    draft_number            SMALLINT,
    points                  NUMERIC(8,3),
    assists                 NUMERIC(8,3),
    rebounds                NUMERIC(8,3),
    all_star_appearances    SMALLINT,
    pie                     NUMERIC(10,5)
);

CREATE TABLE IF NOT EXISTS game (
    game_id             VARCHAR(20) PRIMARY KEY,
    season_id           VARCHAR(20),
    season_start_year   SMALLINT,
    game_date           DATE NOT NULL,
    home_team_id        BIGINT NOT NULL,
    home_team_name      TEXT,
    home_win_loss       CHAR(1),
    home_points         SMALLINT,
    away_team_id        BIGINT NOT NULL,
    away_team_name      TEXT,
    away_win_loss       CHAR(1),
    away_points         SMALLINT,
    attendance          INTEGER,
    CONSTRAINT different_game_teams CHECK (home_team_id <> away_team_id)
);

CREATE INDEX IF NOT EXISTS idx_game_season ON game(season_start_year);
CREATE INDEX IF NOT EXISTS idx_game_home_team ON game(home_team_id);
CREATE INDEX IF NOT EXISTS idx_game_away_team ON game(away_team_id);

CREATE TABLE IF NOT EXISTS official (
    official_id     BIGINT PRIMARY KEY,
    first_name      TEXT,
    last_name       TEXT,
    jersey_number   VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS game_official (
    game_id         VARCHAR(20) REFERENCES game(game_id) ON DELETE CASCADE,
    official_id     BIGINT REFERENCES official(official_id),
    PRIMARY KEY (game_id, official_id)
);

CREATE TABLE IF NOT EXISTS player_salary (
    salary_id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    season                  VARCHAR(7) NOT NULL,
    team_name               TEXT NOT NULL,
    player_name             TEXT NOT NULL,
    player_status           TEXT,
    is_final_season         BOOLEAN,
    is_waived               BOOLEAN,
    is_on_roster            BOOLEAN,
    contract_detail         TEXT NOT NULL DEFAULT '',
    salary_value            NUMERIC(14,2) NOT NULL,
    UNIQUE (season, team_name, player_name, contract_detail, salary_value)
);

CREATE INDEX IF NOT EXISTS idx_player_salary_season_team
    ON player_salary(season, team_name);

CREATE TABLE IF NOT EXISTS team_salary (
    team_name       TEXT PRIMARY KEY,
    team_slug       VARCHAR(5),
    salary_2020_21  NUMERIC(14,2),
    salary_2021_22  NUMERIC(14,2),
    salary_2022_23  NUMERIC(14,2),
    salary_2023_24  NUMERIC(14,2),
    salary_2024_25  NUMERIC(14,2),
    salary_2025_26  NUMERIC(14,2)
);

CREATE TABLE IF NOT EXISTS draft_pick (
    draft_year          SMALLINT NOT NULL,
    overall_pick        SMALLINT NOT NULL,
    round_number        SMALLINT,
    round_pick          SMALLINT,
    player_id           BIGINT,
    player_name         TEXT NOT NULL,
    team_id             BIGINT,
    team_name           TEXT,
    organization_from   TEXT,
    PRIMARY KEY (draft_year, overall_pick)
);

COMMIT;

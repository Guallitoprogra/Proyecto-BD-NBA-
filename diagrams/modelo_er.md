# Modelo entidad-relación preliminar

Este modelo incluye únicamente las entidades necesarias para el primer análisis. Es deliberadamente menor que los 149 campos del archivo de partidos.

```mermaid
erDiagram
    TEAM {
        bigint team_id PK
        text full_name
        varchar abbreviation
        text city
    }
    PLAYER {
        bigint player_id PK
        text full_name
        boolean is_active
    }
    PLAYER_ATTRIBUTE {
        bigint player_id PK,FK
        varchar height
        bigint current_team_id
        numeric points
        numeric assists
        numeric rebounds
        numeric pie
    }
    GAME {
        varchar game_id PK
        smallint season_start_year
        date game_date
        bigint home_team_id
        bigint away_team_id
        smallint home_points
        smallint away_points
    }
    OFFICIAL {
        bigint official_id PK
        text first_name
        text last_name
    }
    GAME_OFFICIAL {
        varchar game_id PK,FK
        bigint official_id PK,FK
    }
    PLAYER_SALARY {
        bigint salary_id PK
        varchar season
        text team_name
        text player_name
        numeric salary_value
    }
    TEAM_SALARY {
        text team_name PK
        numeric salary_2020_21
        numeric salary_2021_22
    }
    DRAFT_PICK {
        smallint draft_year PK
        smallint overall_pick PK
        bigint player_id
        bigint team_id
    }

    PLAYER ||--o| PLAYER_ATTRIBUTE : tiene
    GAME ||--o{ GAME_OFFICIAL : incluye
    OFFICIAL ||--o{ GAME_OFFICIAL : participa
    TEAM ||--o{ PLAYER_ATTRIBUTE : equipo_actual
    TEAM ||--o{ GAME : juega_local
    TEAM ||--o{ GAME : juega_visitante
    PLAYER ||--o{ PLAYER_SALARY : recibe
    PLAYER ||--o| DRAFT_PICK : seleccionado
    TEAM ||--o{ DRAFT_PICK : selecciona
```

## Nota sobre integridad referencial

Los partidos incluyen franquicias históricas que no aparecen en `Team.csv`, que contiene 30 equipos actuales. Por eso las relaciones desde `game` hacia `team` se documentan conceptualmente, pero el esquema inicial no impone esas claves foráneas. Primero debemos incorporar `Team_History.csv` o diseñar una dimensión histórica de franquicias.

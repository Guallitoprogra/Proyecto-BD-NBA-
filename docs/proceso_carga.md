# Proceso de carga de datos

Este documento explica cómo pasamos los archivos entregados y los datos de NBA API a PostgreSQL. La idea es que cualquier integrante pueda repetir el proceso sin copiar contraseñas ni subir archivos pesados al repositorio.

## Origen de los datos

- `Data.zip`: contiene los CSV entregados para el proyecto. El cargador lo lee directamente, por lo que no hace falta descomprimirlo.
- NBA API: aporta las estadísticas por jugador y equipo de la temporada 2020-21.

De los 14 CSV disponibles se cargan los ocho que corresponden al alcance actual:

| Archivo | Tabla de destino |
| --- | --- |
| `team.csv` | `team` |
| `player.csv` | `player` |
| `player_attributes.csv` | `player_attribute` |
| `games.csv` | `game` |
| `officials.csv` | `official` y `game_official` |
| `player_salary.csv` | `player_salary` |
| `team_salary.csv` | `team_salary` |
| `draft.csv` | `draft_pick` |

Las estadísticas obtenidas de NBA API se guardan en `player_season_stat`.

## Orden para ejecutar el proyecto

1. Crear la base de datos `nba_project` en pgAdmin.
2. Abrir el Query Tool y ejecutar `database/schema.sql`.
3. Copiar `.env.example` como `.env` y completar la conexión y la ruta de `Data.zip`.
4. Instalar las dependencias y ejecutar los cargadores:

```powershell
python -m pip install -r requirements.txt
python src/load_data.py
python src/nba_api_ingest.py
```

5. En pgAdmin ejecutar, en este orden:

```text
database/checks.sql
database/validation.sql
database/queries_stage2.sql
database/analytics_views.sql
database/queries_stage3.sql
```

También se pueden guardar los resultados de las consultas en archivos JSON:

```powershell
python src/check_project.py database/validation.sql database/queries_stage2.sql database/queries_stage3.sql
```

Si el archivo de configuración tiene otro nombre o está en otra carpeta, se indica antes de ejecutar los cargadores:

```powershell
$env:PROJECT_ENV_FILE = "C:\ruta\a\mi-configuracion.env"
python src/load_data.py
python src/nba_api_ingest.py
```

## Decisiones tomadas durante la carga

- Los cargadores usan `ON CONFLICT`, así que se pueden ejecutar de nuevo sin duplicar los registros principales.
- Los campos vacíos se convierten a `NULL` y los valores numéricos se normalizan antes de insertarlos.
- Los oficiales repetidos se guardan una sola vez y la asignación de cada oficial a cada juego queda en `game_official`.
- Los resultados de partidos se reconstruyen para corregir inconsistencias de victorias y derrotas encontradas en el CSV.
- NBA API se consulta por equipo para conservar correctamente a los jugadores que estuvieron en más de un equipo durante la temporada.
- La respuesta de NBA API queda en caché dentro de `data/raw`; estos archivos locales no se versionan.

## Comprobación realizada

Se probó la instalación desde cero y también una segunda ejecución sobre la misma base. En ambos casos se conservaron los conteos esperados. La carga actual contiene 62,379 partidos, 7,890 registros de draft y 626 registros jugador-equipo de NBA API, correspondientes a 540 jugadores únicos.

El modelo ER se generó tomando como referencia `database/schema.sql` y se comparó con las llaves y columnas existentes en PostgreSQL. El archivo `docs/diagrams/schema_snapshot.json` deja una evidencia de esa comparación sin guardar datos ni credenciales.

## Archivos que no deben subirse

- `.env` o cualquier archivo que contenga la contraseña de PostgreSQL.
- `Data.zip` y los CSV originales.
- La caché descargada desde NBA API.

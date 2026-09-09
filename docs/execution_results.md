# Resultados de ejecución - Persona 1

> Registro de la primera prueba. Para los resultados corregidos del 8 de septiembre,
> consultar `cierre_persona1.md` y `results/`. Los conteos y conclusiones de abajo son históricos.

Fecha de validación: 7 de septiembre de 2026.

## Base de datos

Se utilizó PostgreSQL 18 con la base `nba_project`. El archivo `database/schema.sql`
se ejecutó correctamente y dejó disponibles diez tablas.

## Carga de CSV

| Tabla | Filas almacenadas |
|---|---:|
| team | 30 |
| player | 4,501 |
| player_attribute | 4,500 |
| game | 62,379 |
| official | 143 |
| game_official | 65,158 |
| player_salary | 1,292 |
| team_salary | 30 |
| draft_pick | 7,361 |

El cargador procesó 62,448 filas de partidos, pero quedaron 62,379 juegos porque
`game_id` es único y el archivo contiene 69 identificadores repetidos. En el draft,
los registros que repiten la combinación año/número de selección también se
actualizan mediante `UPSERT`.

No se encontraron partidos sin marcador. La cobertura mínima quedó validada:

| Temporada | Partidos |
|---:|---:|
| 2015 | 1,230 |
| 2016 | 1,230 |
| 2017 | 1,230 |
| 2018 | 1,230 |
| 2019 | 1,059 |
| 2020 | 1,080 |

## Ingesta desde NBA API

`src/nba_api_ingest.py` consultó la temporada 2021-22 y cargó 605 jugadores en
`player_season_stat`. Se verificaron los campos de partidos jugados, puntos,
asistencias, rebotes y plus/minus. La copia CSV se guarda localmente en
`data/raw/` y no se publica en GitHub.

## Consultas de la Etapa 2

Las ocho preguntas obligatorias ejecutaron sin errores. Algunos resultados de
control fueron:

- Jugador activo más alto: Tacko Fall, 89 pulgadas.
- Jugador activo más bajo: Chris Clemons, 69 pulgadas.
- Mayor margen promedio en 2017: Houston Rockets, 8.48 puntos.
- Mayor margen promedio en 2018: Milwaukee Bucks, 8.87 puntos.
- Draft 2018 con mayor salario disponible: Deandre Ayton.
- La temporada 2019 tuvo la mayor duración: 297 días.

## Problema corregido

La consulta de eficiencia salarial devolvía 29 equipos porque los partidos usan
`LA Clippers` y la tabla de salarios usa `Los Angeles Clippers`. También se encontró
que Phoenix usa `PHX` y `PHO` en archivos diferentes. Se reemplazó la relación
directa: ahora se enlaza primero por `team_id` y después por el nombre canónico de
`team`. La consulta devuelve los 30 equipos.

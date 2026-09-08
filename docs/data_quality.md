# Registro de calidad y decisiones

Este archivo debe actualizarse durante todo el proyecto. Cada decisión debe tener evidencia y autor.

| Fecha | Hallazgo | Decisión inicial | Estado |
|---|---|---|---|
| 2026-08-20 | `Game.csv` tiene 62,448 filas, pero 62,379 `GAME_ID` únicos: 69 identificadores aparecen dos veces. | Cargar con `UPSERT` por `game_id`; comparar duplicados antes del informe final. | Pendiente de análisis |
| 2026-08-20 | `Game.csv` contiene 149 columnas, muchas redundantes o especializadas. | Cargar un subconjunto útil para las preguntas actuales y ampliar bajo demanda. | Aceptado para MVP |
| 2026-08-20 | `Player.csv` tiene 4,501 filas y `Player_Attributes.csv` 4,500. | Usar `Player.csv` como tabla padre. Se identificó a Makhtar N'diaye (`player_id` 1626122) como el jugador sin atributos. | Identificado |
| 2026-08-20 | `Team.csv` solo contiene equipos actuales; los juegos comienzan en 1946. | No imponer aún FK de equipos en `game`; modelar historia de franquicias después. | Pendiente |
| 2026-08-20 | La altura está almacenada como texto, por ejemplo `6-11`. | Conservar el valor original y convertir a pulgadas en consultas documentadas. | Aceptado |
| 2026-08-20 | Los salarios usan nombres de jugadores/equipos, no identificadores. | Mantener nombres originales; crear una estrategia de correspondencia antes de hacer JOIN de jugadores. | Pendiente |
| 2026-08-20 | El documento pide 2021/22 en una pregunta, aunque los partidos llegan hasta mayo de 2021. | Usar salarios 2021/22 disponibles y explicar la cobertura; evaluar NBA API para completar datos. | Pendiente |
| 2026-09-07 | La carga procesó 62,448 filas de `Game.csv`, pero PostgreSQL almacenó 62,379 juegos únicos. | Mantener `game_id` como llave primaria y el `UPSERT` del cargador. | Validado |
| 2026-09-07 | Los partidos usan `LA Clippers` y salarios usa `Los Angeles Clippers`; además Phoenix usa las abreviaturas `PHX` y `PHO`. La consulta de eficiencia salarial devolvía 29 de 30 equipos. | La consulta ahora relaciona el `team_id` del partido con el nombre canónico de `team` y después con `team_salary`. | Resuelto |
| 2026-09-07 | NBA API devolvió y cargó 605 jugadores para 2021-22. | Conservar `player_season_stat` como evidencia de la ingesta y validar una muestra de estadísticas. | Validado |
| 2026-09-07 | Las consultas obligatorias 1 a 8 ejecutaron sin errores sobre `nba_project`. | Continuar con la interpretación de negocio para el informe final. | Validado técnicamente |

## Plantilla para nuevos hallazgos

```text
Fecha:
Archivo/tabla:
Problema observado:
Consulta o evidencia:
Decisión:
Responsable:
```

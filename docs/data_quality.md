# Registro de calidad y decisiones

Este archivo debe actualizarse durante todo el proyecto. Cada decisión debe tener evidencia y autor.

| Fecha | Hallazgo | Decisión inicial | Estado |
|---|---|---|---|
| 2026-08-20 | `Game.csv` tiene 62,448 filas, pero 62,379 `GAME_ID` únicos: 69 identificadores aparecen dos veces. | Cargar con `UPSERT` por `game_id`; comparar duplicados antes del informe final. | Pendiente de análisis |
| 2026-08-20 | `Game.csv` contiene 149 columnas, muchas redundantes o especializadas. | Cargar un subconjunto útil para las preguntas actuales y ampliar bajo demanda. | Aceptado para MVP |
| 2026-08-20 | `Player.csv` tiene 4,501 filas y `Player_Attributes.csv` 4,500. | Usar `Player.csv` como tabla padre e identificar el jugador sin atributos. | Pendiente |
| 2026-08-20 | `Team.csv` solo contiene equipos actuales; los juegos comienzan en 1946. | No imponer aún FK de equipos en `game`; modelar historia de franquicias después. | Pendiente |
| 2026-08-20 | La altura está almacenada como texto, por ejemplo `6-11`. | Conservar el valor original y convertir a pulgadas en consultas documentadas. | Aceptado |
| 2026-08-20 | Los salarios usan nombres de jugadores/equipos, no identificadores. | Mantener nombres originales; crear una estrategia de correspondencia antes de hacer JOIN de jugadores. | Pendiente |
| 2026-08-20 | El documento pide 2021/22 en una pregunta, aunque los partidos llegan hasta mayo de 2021. | Usar salarios 2021/22 disponibles y explicar la cobertura; evaluar NBA API para completar datos. | Pendiente |

## Plantilla para nuevos hallazgos

```text
Fecha:
Archivo/tabla:
Problema observado:
Consulta o evidencia:
Decisión:
Responsable:
```

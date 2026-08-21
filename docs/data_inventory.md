# Inventario inicial de datos

Conteos obtenidos directamente de `Data.zip` el 20 de agosto de 2026.

| Archivo | Filas | Columnas | Uso propuesto |
|---|---:|---:|---|
| Team_Attributes.csv | 30 | 14 | Información administrativa y redes de equipos |
| Player.csv | 4,501 | 5 | Catálogo principal de jugadores |
| Draft.csv | 7,890 | 16 | Selecciones históricas del draft |
| Team_History.csv | 60 | 5 | Ciudades y nombres históricos |
| Player_Salary.csv | 1,292 | 12 | Contratos por jugador y temporada |
| Game_Officials.csv | 65,158 | 5 | Relación partido-árbitro |
| Team_Salary.csv | 30 | 9 | Nóminas de 2020/21 a 2025/26 |
| News_Missing.csv | 62 | 3 | Errores de extracción de noticias; fuera del MVP |
| Player_Attributes.csv | 4,500 | 37 | Perfil y estadísticas agregadas del jugador |
| News.csv | 1,195 | 33 | Noticias; posible fuente adicional, fuera del MVP |
| Team.csv | 30 | 7 | Catálogo de equipos actuales |
| Draft_Combine.csv | 1,395 | 116 | Mediciones y pruebas físicas del combine |
| Game.csv | 62,448 | 149 | Partidos, resultados y estadísticas |
| Game_Inactive_Players.csv | 98,679 | 9 | Jugadores inactivos por partido |

## Archivos incluidos en la primera carga

`Team.csv`, `Player.csv`, `Player_Attributes.csv`, `Game.csv`, `Game_Officials.csv`, `Player_Salary.csv`, `Team_Salary.csv` y `Draft.csv`.

## Archivos pospuestos

- `News.csv` y `News_Missing.csv`: no son necesarios para responder las consultas mínimas.
- `Draft_Combine.csv`: tiene 116 columnas; se incorporará si una pregunta propia usa potencial físico.
- `Game_Inactive_Players.csv`: se incorporará si analizamos disponibilidad o lesiones.
- `Team_History.csv`: necesario antes de imponer claves foráneas históricas.
- `Team_Attributes.csv`: útil para capacidad de arena o análisis comercial posterior.

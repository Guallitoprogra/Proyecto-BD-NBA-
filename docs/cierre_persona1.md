# Cierre de Persona 1 - 8 de septiembre

Probamos el esquema y la carga desde cero en `nba_revision_20260908`, una base independiente.
Repetimos la carga: los conteos no cambiaron. La base de trabajo es `nba_project`.
Este documento sustituye las conclusiones preliminares de `execution_results.md`.

- Se reconstruyó W/L con los marcadores. En 2020 había 40 partidos con algún W/L vacío.
- Los 69 juegos duplicados coinciden en fecha, equipos y marcador. Quedan 62379 juegos.
- La llave del draft ahora incluye el nombre: varios jugadores históricos comparten selección 0.
  La llave anterior perdía 529 registros. Ahora quedan los 7890 del archivo.
- Consultamos NBA API 2020-21 por equipo, separando periodos de jugadores traspasados.
  Quedan 626 registros jugador-equipo y 540 jugadores distintos. Portland se recuperó
  del bloque de la primera descarga completa tras comprobar los otros 29 bloques.
  Se retiraron cinco filas obsoletas de la ingesta agregada, respaldadas localmente
  en `data/raw/api_previous_rows.json`. El script guarda caché y reintenta fallos de red.
  La ingesta 2021-22 se conserva, pero no interviene en la recomendación.
- Las preguntas 4 y 7 usan PTS+AST+REB como indicador de valor deportivo y 20 partidos
  como mínimo. No es el premio MVP ni una valoración de mercado. Se usa 2020-21,
  última temporada completa antes de invertir; no contratos futuros de temporadas distintas.
- La pregunta 7 enlaza por ID y pondera por juegos los periodos de jugadores traspasados.
  Quince seleccionados de 2018 no tienen estadísticas NBA 2020-21; están listados en
  validación y no se les inventan valores.
- La altura de este archivo es numérica en pulgadas, no texto del tipo `6-11`.

Los resultados completos están en `results/validation.json` y `results/queries_stage2.json`,
en el orden de los SELECT. Se regeneran con `src/check_project.py`.

## Cómo interpretar la Etapa 2

Q1 describe jugadores activos en la captura original, no en 2026.
Q2 muestra ataque y defensa. Q3 cuenta derrotas visitantes sin atribuirlas al árbitro.
Q4 compara nómina y talento, con rankings y correlación. Q5 se limita a la historia
disponible y mide días transcurridos. Q6 usa el año de inicio de temporada.
Q7 compara el draft con un criterio común. Q8 usa nóminas y compromisos del CSV,
no pagos auditados; Toronto se agrupa en Ontario, que es una provincia canadiense.

## Límites

Los resultados siguen dependiendo de la calidad de los marcadores proporcionados.
Los salarios son una captura de contratos, no estados financieros auditados.
La suma PTS+AST+REB es un criterio del grupo, no una medida universal de talento.
Persona 3 debe actualizar la llave del draft en el diagrama.

# Cierre de Persona 2

Las consultas A-G del plan quedaron implementadas y ejecutadas para los 30 equipos.
Agregamos H para comprobar sensibilidad de los pesos. El Top 5 y las interpretaciones
están en `resultado_inversion.md`; los resultados completos en `results/queries_stage3.json`.

## Requisitos SQL

Hay 12 SELECT finales en Etapa 2 y 8 en Etapa 3. Incluso contando las variantes
1A/1B y 5A/5B como una sola pregunta, se superan las 15 consultas solicitadas.

Ejemplos verificables:
- GROUP BY: Etapa 2 preguntas 2, 3 y 8.
- JOIN: Etapa 2 preguntas 1, 3 y 4.
- Subconsultas explícitas en tres consultas diferentes: pregunta 4 usa SELECT corr;
  pregunta 5A compara contra SELECT MAX; pregunta 7 usa EXISTS y SELECT MAX.
  No contamos los WITH como sustituto de este requisito.

## Para revisar en pgAdmin

En `nba_project > Schemas > public > Views` están `v_team_seasons`, `v_team_talent`,
`v_investment_metrics` y `v_investment_ranking`. Actualizar el árbol si no aparecen.
Abrir `database/demo_pgadmin.sql` en Query Tool y ejecutar el SELECT elegido.

## Para Persona 3

Usar el ranking corregido de Utah Jazz, no el documento anterior de Brooklyn.
Actualizar el ER con la llave compuesta del draft (año, selección, nombre).
Las vistas son auxiliares y no sustituyen las diez tablas. Diferenciar relaciones
conceptuales de las FK reales. Los archivos JSON guardan todas las tablas para
preparar las gráficas y el PDF. La presentación y el informe final siguen pendientes.

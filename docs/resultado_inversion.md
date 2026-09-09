# Recomendación de inversión: Utah Jazz

La revisión del 8 de septiembre reemplaza el ranking anterior que recomendaba Brooklyn.
Se corrigieron los W/L faltantes, los periodos de jugadores traspasados y el uso de
estadísticas de una temporada posterior a la decisión.

## Resultado

| Puesto | Equipo | Deportivo | Financiero | Talento | Total |
|---:|---|---:|---:|---:|---:|
| 1 | Utah Jazz | 82.69 | 81.67 | 61.06 | 75.14 |
| 2 | Milwaukee Bucks | 70.25 | 70.14 | 63.91 | 68.10 |
| 3 | Los Angeles Clippers | 76.38 | 65.07 | 57.38 | 66.28 |
| 4 | Denver Nuggets | 68.64 | 80.58 | 38.39 | 62.54 |
| 5 | Portland Trail Blazers | 66.40 | 63.38 | 49.53 | 59.77 |

Utah combina un buen historial deportivo con eficiencia salarial. No necesita
liderar todos los indicadores para obtener el mejor resultado conjunto.
Es la recomendación de nuestro modelo para 2021-22; no una garantía de rentabilidad.

## Cómo calculamos el ranking

Usamos las temporadas 2015-16 a 2020-21 para el historial y 2020-21 para nómina y
talento. La consulta API se hizo hoy sobre datos históricos; no usamos el desempeño
de 2021-22 para anticipar esa temporada.

Cada indicador se normaliza entre 0 y 100 respecto de los 30 equipos. Para
variabilidad y dependencia, un valor menor recibe un puntaje mayor.

- Deportivo: promedio de cuatro puntajes: win rate medio, estabilidad, crecimiento
  entre los extremos del periodo y margen medio de puntos.
- Financiero: victorias de 2020-21 por millón de nómina de esa temporada.
- Talento: promedio de los puntajes de PTS+AST+REB, plus/minus y menor dependencia
  del máximo anotador. Los promedios de jugador se ponderan por sus partidos.
- Total: promedio simple de los tres pilares, exactamente un tercio cada uno.

Damos el mismo peso a los pilares porque no tenemos una razón respaldada por datos
para privilegiar uno. Dentro de cada pilar usamos pesos iguales por la misma razón.
Esto modifica el ranking anterior, que no incorporaba varios indicadores calculados.

## Qué muestra cada consulta

A. Consistencia: compara el porcentaje de victorias de seis temporadas y su dispersión.
B. Crecimiento: muestra el cambio en puntos porcentuales entre 2015 y 2020.
C. Margen: diferencia de puntos por partido; ponderamos por cantidad de juegos.
D. Finanzas: victorias por millón, sin confundir eficiencia deportiva con ganancias.
E. Talento: promedios de jugador ponderados por juegos; no son puntos totales de equipo.
F. Dependencia: puntos aproximados del máximo aportante divididos entre los del equipo,
estimados con promedio por partido multiplicado por juegos de cada periodo.
G. Ranking: combina los tres pilares y muestra el Top 5.
H. Sensibilidad: cambia los pesos para saber si la elección depende de un solo reparto.

## Sensibilidad y límites

Utah sigue primero con pesos 50/25/25, 25/50/25 y 25/25/50:
77.02, 76.77 y 71.62 puntos, respectivamente. Esto respalda la elección dentro de
esos escenarios, pero no prueba que sea la mejor inversión con cualquier modelo.

No tenemos ingresos, precio de compra de franquicias, beneficios ni previsiones.
Las nóminas vienen de una captura de contratos. PTS, AST, REB y plus/minus no
capturan por sí solos toda la calidad deportiva. Hay correlación entre algunas
métricas, especialmente victorias y eficiencia salarial. Los promedios del API
están redondeados: los puntos acumulados y la dependencia son aproximados.
El corte usa la plantilla histórica 2020-21, sin modelar fichajes de 2021-22.

## Evidencia

El cálculo está en `database/analytics_views.sql` y las ocho consultas en
`database/queries_stage3.sql`. Los resultados completos están en
`docs/results/queries_stage3.json`, en el mismo orden A-H.

# Plan de trabajo para tres integrantes

Sustituir “Integrante A/B/C” por los nombres reales. Cada persona debe usar su propia cuenta de GitHub y dejar commits verificables.

## Entregable para la primera revisión

- Repositorio y convenciones acordadas.
- Inventario de datos.
- Modelo ER preliminar.
- Esquema PostgreSQL.
- Carga reproducible de las tablas principales.
- Dos o más consultas ejecutadas con evidencia.

## División sugerida

### Integrante A - Datos y ETL

- [ ] Instalar dependencias y probar `src/load_data.py`.
- [ ] Analizar los 69 `GAME_ID` duplicados.
- [ ] Encontrar el jugador que no tiene registro en `Player_Attributes.csv`.
- [ ] Registrar hallazgos en `docs/data_quality.md`.
- [ ] Mejorar manejo de errores y métricas del cargador.

### Integrante B - Modelo y PostgreSQL

- [ ] Revisar tipos y restricciones de `database/schema.sql`.
- [ ] Ejecutar `database/validation.sql` después de la carga.
- [ ] Diseñar cómo representar equipos/franquicias históricas.
- [ ] Exportar el diagrama ER a PNG o PDF para la presentación.
- [ ] Documentar las relaciones y cardinalidades.

### Integrante C - SQL y análisis de negocio

- [ ] Validar resultados de `database/queries_stage2.sql`.
- [ ] Completar las ocho preguntas obligatorias de la Etapa 2.
- [ ] Proponer al menos siete preguntas propias para llegar a 15 consultas.
- [ ] Llevar una matriz de cumplimiento: `GROUP BY`, `JOIN`, subquery.
- [ ] Diseñar la métrica de inversión y posibles gráficas.

## Trabajo conjunto

- [ ] Elegir y justificar la hipótesis de inversión.
- [ ] Seleccionar qué información incorporar desde NBA API.
- [ ] Revisar Pull Requests de otra persona.
- [ ] Preparar demostración y registrar decisiones.

## Próximo backlog técnico

1. Cargar y validar las ocho tablas del MVP.
2. Resolver correspondencias por nombre en salarios.
3. Completar las ocho consultas obligatorias.
4. Diseñar al menos siete consultas propias.
5. Integrar una ingesta reproducible desde NBA API.
6. Construir visualizaciones y el PDF final.

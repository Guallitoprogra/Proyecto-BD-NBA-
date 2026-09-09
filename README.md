# Proyecto 01 - Base de datos NBA

Proyecto grupal de CC3088 Base de Datos 1. Construiremos una base de datos PostgreSQL a partir de los CSV proporcionados para responder:

> ¿En qué equipo de la NBA invertiríamos para la temporada 2021/2022?


## Avance actual

- Inventario de los 14 CSV y diccionario inicial de datos.
- Diez tablas creadas y validadas en PostgreSQL (`nba_project`).
- Cargador Python ejecutado con los ocho CSV principales de `Data.zip`.
- NBA API 2020-21 por equipo: 626 registros de 540 jugadores para el análisis.
- Ocho preguntas obligatorias, dos análisis adicionales y ocho consultas de Etapa 3 ejecutadas.
- Ranking revisado: Utah Jazz, con prueba de sensibilidad de pesos.
- Problemas de calidad identificados y documentados.

## Documentación

- [Inventario de datos](docs/data_inventory.md)
- [Decisiones y calidad](docs/data_quality.md)
- [Resultados de ejecución](docs/execution_results.md)
- [Cierre Persona 1](docs/cierre_persona1.md)
- [Cierre Persona 2](docs/cierre_persona2.md)
- [Recomendación corregida](docs/resultado_inversion.md)

## Ejecutar en otra computadora

1. Instalar PostgreSQL y Python, crear `nba_project` y ejecutar `database/schema.sql`.
2. Instalar dependencias con `pip install -r requirements.txt`.
3. Copiar `.env.example` a `.env` y ajustar contraseña y ruta de Data.zip.
4. Ejecutar `python src/load_data.py` y `python src/nba_api_ingest.py`.
5. En pgAdmin ejecutar `database/checks.sql`, `database/validation.sql` y
   `database/queries_stage2.sql`.
6. Ejecutar `database/analytics_views.sql` y después `database/queries_stage3.sql`.

NBA API usa 2020-21 por defecto y guarda caché por equipo en `data/raw`.
Puede elegirse otra temporada con `NBA_SEASON`, pero el ranking conserva el corte 2020-21.
Los archivos locales de datos y contraseñas no se suben a Git.
Para guardar resultados: `python src/check_project.py database/validation.sql database/queries_stage2.sql database/queries_stage3.sql`.
En esta computadora la configuración está en el archivo del escritorio; puede indicarse
con `PROJECT_ENV_FILE` a los cargadores o con `--env` al comprobador.



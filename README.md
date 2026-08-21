# Proyecto 01 - Base de datos NBA

Proyecto grupal de CC3088 Base de Datos 1. Construiremos una base de datos PostgreSQL a partir de los CSV proporcionados para responder:

> ¿En qué equipo de la NBA invertiríamos para la temporada 2021/2022?

## Hipótesis inicial

La recomendación combinará rendimiento deportivo y eficiencia financiera entre 2015/16 y 2020/21. Evaluaremos porcentaje de victorias, margen de puntos, tendencia del rendimiento, nómina y valor de los jugadores. La hipótesis puede cambiar cuando terminemos de validar los datos.

## Avance actual

- Inventario de los 14 CSV y diccionario inicial de datos.
- Modelo entidad-relación preliminar.
- Esquema PostgreSQL reproducible.
- Cargador Python para ocho archivos principales, leyendo directamente `Data.zip`.
- Consultas iniciales de validación y análisis.
- Distribución de tareas y criterios de colaboración.

## Inicio rápido

### 1. Requisitos

- Git
- Python 3.11 o posterior
- PostgreSQL 15 o posterior

### 2. Preparar Python

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Editar `.env` con las credenciales locales y la ruta absoluta de `Data.zip`.

### 3. Crear la base

Crear una base llamada `nba_investment` desde pgAdmin o con:

```powershell
createdb -U postgres nba_investment
psql -U postgres -d nba_investment -f database/schema.sql
```

### 4. Cargar los datos

```powershell
python src/load_data.py
```

El programa lee los CSV dentro del ZIP, transforma únicamente las columnas necesarias y muestra el número de filas procesadas. Puede ejecutarse de nuevo: las tablas principales usan `UPSERT` y las tablas puente evitan duplicados.

### 5. Ejecutar consultas

```powershell
psql -U postgres -d nba_investment -f database/queries_stage2.sql
```

## Estructura

```text
database/   DDL y consultas SQL
data/raw/   Datos locales ignorados por Git
diagrams/   Modelo entidad-relación
docs/       Inventario, decisiones y tareas
src/        Proceso de carga
```

## Documentación

- [Inventario de datos](docs/data_inventory.md)
- [Decisiones y calidad](docs/data_quality.md)
- [Plan de trabajo](docs/team_plan.md)
- [Modelo ER](diagrams/modelo_er.md)

## Convenciones del equipo

1. Crear una rama por tarea: `feature/nombre-corto`.
2. Hacer commits pequeños y descriptivos.
3. Abrir un Pull Request y solicitar revisión de otra persona.
4. No subir contraseñas, `.env` ni los CSV grandes.
5. Documentar problemas de calidad y decisiones en `docs/data_quality.md`.

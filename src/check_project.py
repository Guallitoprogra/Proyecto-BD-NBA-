"""Ejecuta SQL y guarda las tablas de resultados para revisar en equipo."""
import argparse
import json
import os
from pathlib import Path
from decimal import Decimal
import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+")
    parser.add_argument("--env", default=str(ROOT / ".env"))
    parser.add_argument("--database", default="nba_project")
    args = parser.parse_args()
    load_dotenv(args.env, override=True)
    out = ROOT / "docs" / "results"
    out.mkdir(parents=True, exist_ok=True)
    with psycopg.connect(host=os.getenv("DB_HOST", "localhost"),
                         port=os.getenv("DB_PORT", "5432"),
                         user=os.getenv("DB_USER", "postgres"),
                         password=os.getenv("DB_PASSWORD"), dbname=args.database) as conn:
        for filename in args.files:
            path = ROOT / filename
            results = []
            with conn.cursor() as cur:
                cur.execute(path.read_text(encoding="utf-8"))
                while True:
                    if cur.description:
                        names = [c.name for c in cur.description]
                        rows = [dict(zip(names, row)) for row in cur.fetchall()]
                        results.append(rows)
                        print(path.name, "resultado", len(results), "filas", len(rows))
                    if not cur.nextset():
                        break
            if results:
                (out / (path.stem + ".json")).write_text(
                    json.dumps(results, ensure_ascii=False, indent=2,
                               default=lambda x: float(x) if isinstance(x, Decimal) else str(x)),
                    encoding="utf-8")

if __name__ == "__main__":
    main()

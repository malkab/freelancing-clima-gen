import os

import psycopg
from fastapi import FastAPI, HTTPException
from psycopg import sql
from psycopg.rows import dict_row


app = FastAPI(title="API", version="0.1.0")

DB_HOST = os.getenv("DB_HOST", "postgres")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "climagen")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")


@app.get("/v1/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/v1/table/{table_name}")
def get_table_rows(table_name: str) -> dict[str, object]:
    print("D: 000", table_name)

    query = sql.SQL("SELECT * FROM climagen.{table_name}").format(
        table_name=sql.Identifier(table_name)
    )

    print("D: 000", query)

    try:
        with psycopg.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
        ) as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(query)
                rows = cur.fetchall()
    except psycopg.Error as exc:
        raise HTTPException(status_code=500, detail=f"Database error: {exc}") from exc

    return {"table": table_name, "rows": rows}

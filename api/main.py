import math
import os

import psycopg
from fastapi import FastAPI, HTTPException
from psycopg import sql
from psycopg.rows import dict_row

app = FastAPI(title="API", version="0.1.0")

DB_HOST = os.getenv("PGHOST", "postgres")
DB_PORT = int(os.getenv("PGPORT", "5432"))
DB_NAME = os.getenv("PGDATABASE", "climagen")
DB_USER = os.getenv("PGUSER", "postgres")
DB_PASSWORD = os.getenv("PGPASSWORD", "postgres")


@app.get("/api/v1/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/v1/variable/{territory}")
def get_variable(territory: str) -> dict[str, object]:

    if territory not in ["autonomia", "provincia", "municipio"]:
        raise HTTPException(status_code=400, detail="Invalid territory")

    query = sql.SQL("SELECT * FROM climagen.variable")

    if territory == "autonomia":
        query += sql.SQL(" WHERE autonomia is true")
    elif territory == "provincia":
        query += sql.SQL(" WHERE provincia is true")
    elif territory == "municipio":
        query += sql.SQL(" WHERE municipio is true")

    query += sql.SQL(" ORDER BY variable_order")

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

    return {"rows": rows}


@app.get("/api/v1/carto/{territory}/{variable}")
def get_carto(territory: str, variable: str) -> dict[str, object]:

    color_ramp = [
        "#0074ae",
        "#3dbe43",
        "#fff700",
        "#ff420e",
        "#ff0000"
    ]

    if territory not in ["autonomia", "provincia", "municipio"]:
        raise HTTPException(status_code=400, detail="Invalid territory")

    query = sql.SQL("""
        SELECT array_agg({}) as values
        FROM {}
        WHERE {} IS NOT NULL
    """).format(
        sql.Identifier(variable),
        sql.Identifier("climagen", territory),
        sql.Identifier(variable)
    )

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
                row = cur.fetchone()

    except psycopg.Error as exc:
        raise HTTPException(status_code=500, detail=f"Database error: {exc}") from exc

    if row is None:
        raise HTTPException(status_code=404, detail="Carto not found")

    data = [ float(i) for i in row["values"] ]

    min_data = min(data)
    max_data = max(data)

    range_data = max_data - min_data
    step = range_data / 5

    steps = [ math.ceil(min_data + step * i) for i in range(0, 6) ]

    variable_area = {
        "id": "variable_area",
        "type": "fill",
        "source": f"{territory}_area",
        "source-layer": territory,
        "metadata": { "group": "variable" },
        "filter": [
            "all",
            ["has", variable],
            ["!=", ["get", variable], None]
        ],
        "paint": {
            "fill-outline-color": "#00000000",
            "fill-color": [
                "interpolate",
                ["linear"],
                ["to-number", ["get", variable]],
                steps[0],  color_ramp[0],
                steps[1],  color_ramp[1],
                steps[2],  color_ramp[2],
                steps[3],  color_ramp[3],
                steps[4],  color_ramp[4]
            ],
            "fill-opacity": 0.3
        },
        "layout": {
            "visibility": "visible"
        }
    }

    variable_borde = {
        "id": "variable_borde",
        "type": "line",
        "source": f"{territory}_borde",
        "source-layer": f"{territory}.1",
        "metadata": { "group": "variable" },
        "filter": [
            "all",
            ["has", variable],
            ["!=", ["get", variable], None]
        ],
        "paint": {
            "line-color": "#222222cc",
            "line-width": 0.25,
            "line-opacity": 0.5
        },
        "layout": {
            "visibility": "visible"
        }
    }

    variable_centroid = {
        "id": "variable_centroid",
        "type": "circle",
        "source": f"{territory}_centroid",
        "source-layer": f"{territory}.2",
        "metadata": { "group": "variable" },
        "filter": [
            "all",
            ["has", variable],
            ["!=", ["get", variable], None]
        ],
        "paint": {
            "circle-color": [
                "interpolate",
                ["linear"],
                ["to-number", ["get", variable]],
                steps[0],  color_ramp[0],
                steps[1],  color_ramp[1],
                steps[2],  color_ramp[2],
                steps[3],  color_ramp[3],
                steps[4],  color_ramp[4]
            ],
            "circle-radius": [
                "interpolate",
                ["linear"],
                ["to-number", ["get", variable]],
                steps[0],  2,
                steps[4],  10
            ],
            "circle-opacity": 1,
            "circle-stroke-color": "#000000cc",
            "circle-stroke-width": 0.25
        },
        "layout": {
            "visibility": "visible",
            "circle-sort-key": ["to-number", ["get", variable]]
        }
    }

    return {"variable_area": variable_area, "variable_borde": variable_borde, "variable_centroid": variable_centroid}
from __future__ import annotations

import re
from pathlib import Path
from urllib.parse import quote_plus

import pandas as pd
from sqlalchemy import create_engine


# Common substitutions for Spanish characters to ASCII equivalents, suitable for PostgreSQL column names.
STANDARD_SPANISH_CHAR_SUBSTITUTIONS = {
    "á": "a",
    "é": "e",
    "í": "i",
    "ó": "o",
    "ú": "u",
    "ü": "u",
    "ñ": "ny",
}


def normalize_column_name(
    name: object,
    chr_substitutions: dict[str, str] = STANDARD_SPANISH_CHAR_SUBSTITUTIONS,
) -> str:
    """Normalizes column names for proper PostgreSQL formats.

    Args:
        name (object): Column name to normalize.
        chr_substitutions (dict[str, str]): Character substitution mapping in lowercase. Defaults to a standard Spanish character set.

    Returns:
        str: Normalized column name.
    """
    s = str(name).strip().lower()

    # Special character substitutions after lowercasing
    special_substitutions = str.maketrans(chr_substitutions)
    s = s.translate(special_substitutions)

    s = re.sub(r"\s+", "_", s)
    s = re.sub(r"[^a-z0-9_]+", "_", s)
    s = re.sub(r"_+", "_", s)
    s = s.strip("_")

    if not s:
        s = "col"

    if s[0].isdigit():
        s = f"c_{s}"

    return s


def parse_excel_range(range_spec: str) -> tuple[str, int, int]:
    """
    Convert Excel range like 'B3:H200' into pandas read_excel args:
    - usecols='B:H'
    - skiprows=2
    - nrows=198

    Assumes the first row of the range is the header row.

    Args:
        range_spec (str): Excel range specification, e.g. 'B3:H200'.

    Returns:
        tuple[str, int, int]: (usecols, skiprows, nrows)
    """
    m = re.fullmatch(r"([A-Z]+)(\d+):([A-Z]+)(\d+)", range_spec.upper())
    if not m:
        raise ValueError(
            f"Invalid range '{range_spec}'. Expected format like B3:H200"
        )

    col_start, row_start, col_end, row_end = m.groups()
    row_start_i = int(row_start)
    row_end_i = int(row_end)

    if row_end_i < row_start_i:
        raise ValueError(f"Invalid range '{range_spec}': end row before start row")

    usecols = f"{col_start}:{col_end}"
    skiprows = row_start_i - 1
    nrows = row_end_i - row_start_i + 1

    return usecols, skiprows, nrows


def make_pg_conn_sqlalchemy(
    host: str,
    port: int,
    user: str,
    password: str,
    dbname: str,
) -> str:
    """Generates a SQLAlchemy connection string from traditional PG connection parameters.

    Args:
        host (str): The PG host.
        port (int): The PG port.
        user (str): The PG user.
        password (str): The PG password.
        dbname (str): The PG DB name.

    Returns:
        str: The SQLAlchemy connection string.
    """
    return (
        "postgresql+psycopg2://"
        f"{quote_plus(user)}:{quote_plus(password)}"
        f"@{host}:{port}/{quote_plus(dbname)}"
    )


def import_excel_range_to_pg(
    excel_path: str,
    sheet_name: str,
    schema: str,
    table_name: str,
    pg_conn_sqlalchemy: str,
    excel_range: str | None = None,
    if_exists: str = "replace",   # fail | replace | append
    chunksize: int = 1000,
) -> None:
    """
    Import an Excel sheet or a rectangular range into PostgreSQL.

    Example range:
        B3:H200
    """
    read_kwargs: dict = {
        "io": Path(excel_path),
        "sheet_name": sheet_name,
        "engine": "openpyxl",
    }

    if excel_range:
        usecols, skiprows, nrows = parse_excel_range(excel_range)
        read_kwargs.update(
            {
                "usecols": usecols,
                "skiprows": skiprows,
                "nrows": nrows,
                "header": 0,   # first row inside the selected range becomes header
            }
        )
    else:
        read_kwargs["header"] = 0

    df = pd.read_excel(**read_kwargs)

    # Drop fully empty rows
    df = df.dropna(axis=0, how="all")

    # Normalize column names
    df.columns = [normalize_column_name(c) for c in df.columns]

    engine = create_engine(pg_conn_sqlalchemy)

    with engine.begin() as conn:
        df.to_sql(
            name=table_name,
            con=conn,
            schema=schema,
            if_exists=if_exists,
            index=False,
            chunksize=chunksize,
            method="multi",
        )


# ---

pg_conn = make_pg_conn_sqlalchemy(
    host="postgres",
    port=5432,
    user="postgres",
    password="postgres",
    dbname="climagen",
)

# Regional

import_excel_range_to_pg(
    excel_path="../data/0100_in/datos_proyecto/Datos Regional DEF.xlsx",
    sheet_name="Datos ponderados",
    schema="raw",
    table_name="autonomias_datos_ponderados",
    pg_conn_sqlalchemy=pg_conn,
    excel_range="A1:BE20",
)

import_excel_range_to_pg(
    excel_path="../data/0100_in/datos_proyecto/Datos Regional DEF.xlsx",
    sheet_name="Índice Clima-Gen + CC",
    schema="raw",
    table_name="autonomias_datos_indice",
    pg_conn_sqlalchemy=pg_conn,
    excel_range="A2:N21",
)


# Provincial

import_excel_range_to_pg(
    excel_path="../data/0100_in/datos_proyecto/Datos Provincial DEF.xlsx",
    sheet_name="Datos ponderados",
    schema="raw",
    table_name="provincias_datos_ponderados",
    pg_conn_sqlalchemy=pg_conn,
    excel_range="A1:AS53",
)

import_excel_range_to_pg(
    excel_path="../data/0100_in/datos_proyecto/Datos Provincial DEF.xlsx",
    sheet_name="Índice Clima-Gen + CC",
    schema="raw",
    table_name="provincias_datos_indice",
    pg_conn_sqlalchemy=pg_conn,
    excel_range="A2:N54",
)


# Municipio

import_excel_range_to_pg(
    excel_path="../data/0100_in/datos_proyecto/Datos Municipal DEF.xlsx",
    sheet_name="Datos ponderados",
    schema="raw",
    table_name="municipios_datos_ponderados",
    pg_conn_sqlalchemy=pg_conn,
    excel_range="A1:AM8133",
)

import_excel_range_to_pg(
    excel_path="../data/0100_in/datos_proyecto/Datos Municipal DEF.xlsx",
    sheet_name="Índice Clima-Gen + CC",
    schema="raw",
    table_name="municipios_datos_indice",
    pg_conn_sqlalchemy=pg_conn,
    excel_range="A2:N8134",
)
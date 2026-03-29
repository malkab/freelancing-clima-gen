#!/bin/bash

EPSG_CODE=4258

PG_HOST=$PGHOST
PG_PORT=$PGPORT
PG_USER=$PGUSER
PG_PASS=$PGPASSWORD
PG_DB=$PGDATABASE

PG_CONN="host=${PG_HOST} user=${PG_USER} dbname=${PG_DB} password=${PG_PASS} port=${PG_PORT}"

PGCLIENTENCODING=UTF8 ogr2ogr -overwrite -progress \
	-f "PostgreSQL" PG:"${PG_CONN}" \
	-a_srs "EPSG:${EPSG_CODE}" \
	-lco SCHEMA=raw \
	-lco FID=gid \
	-lco OVERWRITE=YES \
	-nln autonomias_peninbal \
	-lco GEOMETRY_NAME=geom \
	-nlt MULTIPOLYGON \
	../data/0100_in/lineas_limite/SHP_ETRS89/recintos_autonomicas_inspire_peninbal_etrs89/recintos_autonomicas_inspire_peninbal_etrs89.shp

PGCLIENTENCODING=UTF8 ogr2ogr -overwrite -progress \
	-f "PostgreSQL" PG:"${PG_CONN}" \
	-a_srs "EPSG:${EPSG_CODE}" \
	-lco SCHEMA=raw \
	-lco FID=gid \
	-lco OVERWRITE=YES \
	-nln autonomias_regcan \
	-lco GEOMETRY_NAME=geom \
	-nlt MULTIPOLYGON \
	../data/0100_in/lineas_limite/SHP_REGCAN95/recintos_autonomicas_inspire_canarias_regcan95/recintos_autonomicas_inspire_canarias_regcan95.shp

PGCLIENTENCODING=UTF8 ogr2ogr -overwrite -progress \
	-f "PostgreSQL" PG:"${PG_CONN}" \
	-a_srs "EPSG:${EPSG_CODE}" \
	-lco SCHEMA=raw \
	-lco FID=gid \
	-lco OVERWRITE=YES \
	-nln provincias_peninbal \
	-lco GEOMETRY_NAME=geom \
	-nlt MULTIPOLYGON \
	../data/0100_in/lineas_limite/SHP_ETRS89/recintos_provinciales_inspire_peninbal_etrs89/recintos_provinciales_inspire_peninbal_etrs89.shp

PGCLIENTENCODING=UTF8 ogr2ogr -overwrite -progress \
	-f "PostgreSQL" PG:"${PG_CONN}" \
	-a_srs "EPSG:${EPSG_CODE}" \
	-lco SCHEMA=raw \
	-lco FID=gid \
	-lco OVERWRITE=YES \
	-nln provincias_regcan \
	-lco GEOMETRY_NAME=geom \
	-nlt MULTIPOLYGON \
	../data/0100_in/lineas_limite/SHP_REGCAN95/recintos_provinciales_inspire_canarias_regcan95/recintos_provinciales_inspire_canarias_regcan95.shp

PGCLIENTENCODING=UTF8 ogr2ogr -overwrite -progress \
	-f "PostgreSQL" PG:"${PG_CONN}" \
	-a_srs "EPSG:${EPSG_CODE}" \
	-lco SCHEMA=raw \
	-lco FID=gid \
	-lco OVERWRITE=YES \
	-nln municipios_peninbal \
	-lco GEOMETRY_NAME=geom \
	-nlt MULTIPOLYGON \
	../data/0100_in/lineas_limite/SHP_ETRS89/recintos_municipales_inspire_peninbal_etrs89/recintos_municipales_inspire_peninbal_etrs89.shp

PGCLIENTENCODING=UTF8 ogr2ogr -overwrite -progress \
	-f "PostgreSQL" PG:"${PG_CONN}" \
	-a_srs "EPSG:${EPSG_CODE}" \
	-lco SCHEMA=raw \
	-lco FID=gid \
	-lco OVERWRITE=YES \
	-nln municipios_regcan \
	-lco GEOMETRY_NAME=geom \
	-nlt MULTIPOLYGON \
	../data/0100_in/lineas_limite/SHP_REGCAN95/recintos_municipales_inspire_canarias_regcan95/recintos_municipales_inspire_canarias_regcan95.shp
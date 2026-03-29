# ----------------------------------
#
# Cabecera, no tocar, debe estar aquí.
#
# ----------------------------------
.ONESHELL:
SHELL := /bin/bash
PWD := $(shell pwd)
INSIDE_CONTAINER := $(shell [ -f /.dockerenv ] && echo true || echo false)
DATE := $(shell date +%Y%m%d_%H%M%S)
RUFF_NO_COLOR ?= 0
RUFF_ENV := $(if $(filter 1,$(RUFF_NO_COLOR)),NO_COLOR=1,)
TEST_PATH ?= src
TEST_ARGS ?=


# ----------------------------------
#
# Configuración.
#
# ----------------------------------
# Los targets phony son aquellos que no hacen referencia a ningún fichero a
# compilar.
.PHONY:
# Estos ficheros env se aplican en el orden dado y las variables en ellos se van
# sobreescribiendo.
ENV_FILES := ./.devcontainer/assets/env
# Nombre base de los objetos devcontainer, para los targets que manipulan los
# contenedores.
BASE_NAME := freelancing-clima-gen
PG_DUMP_FILE := climagen.pgdump


# ----------------------------------
#
# Targets.
#
# ----------------------------------
# Exec en un contenedor.
ifeq ($(INSIDE_CONTAINER),false)
docker_exec_python:
	$(LOAD_ENV)
	docker exec -ti \
		--workdir /workspace \
		$(BASE_NAME)-python \
		/bin/bash
endif


# Apaga el Compose.
ifeq ($(INSIDE_CONTAINER),false)
docker_compose_down:
	$(LOAD_ENV)
	docker compose \
		-f .devcontainer/docker-compose.yml \
		-p $(BASE_NAME) \
		down
endif


# Para los contenedores.
ifeq ($(INSIDE_CONTAINER),false)
docker_containers_stop:
	$(LOAD_ENV)
	docker ps --filter name=$(BASE_NAME)* -q | xargs -r docker stop
endif


# Limpia contenedores.
ifeq ($(INSIDE_CONTAINER),false)
docker_containers_rm:
	$(LOAD_ENV)
	read -p "¿Eliminar contenedores [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker ps --filter name=$(BASE_NAME)* -q | xargs -r docker stop
		docker ps -a --filter name=$(BASE_NAME)* -q | xargs -r docker rm
	fi
endif


# psql.
ifeq ($(INSIDE_CONTAINER),false)
pg_psql:
	$(LOAD_ENV)
	docker run -ti --rm \
		--workdir /workspace \
		-v $(PWD):/workspace \
		--network $(BASE_NAME) \
		--entrypoint psql \
		-e PGHOST=$$PGHOST \
		-e PGPORT=$$PGPORT \
		-e PGUSER=$$PGUSER \
		-e PGDATABASE=$$PGDATABASE \
		-e PGPASSWORD=$$PGPASSWORD \
		freelancing-clima-gen-postgres
endif


# ¡MUCHO CUIDADO! Tira los volúmenes.
ifeq ($(INSIDE_CONTAINER),false)
docker_volume_rm:
	$(LOAD_ENV)
	read -p "¿Eliminar volúmenes [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker volume ls -q | grep $(BASE_NAME) | xargs -r docker volume rm
	fi
endif


# PG backup.
ifeq ($(INSIDE_CONTAINER),false)
pg_dump:
	$(LOAD_ENV)
	read -p "¿Se ha configurado correctamente el backup [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker run -ti --rm \
			-v $(PWD):/workspace/ \
			--workdir /workspace/ \
			--entrypoint pg_dump \
			--network $(BASE_NAME) \
			-e PGHOST=$$PGHOST \
			-e PGPORT=$$PGPORT \
			-e PGUSER=$$PGUSER \
			-e PGDATABASE=$$PGDATABASE \
			-e PGPASSWORD=$$PGPASSWORD \
			-e PGCLIENTENCODING=UTF8 \
			-e PGOPTIONS='-c statement_timeout=0 -c idle_in_transaction_session_timeout=0' \
			freelancing-clima-gen-postgres \
			-b -F c -v -Z 9 \
			--no-privileges \
			-f $(DATE)-$(PG_DUMP_FILE)
	fi
endif


# ----------------------------------
#
# Funciones auxiliares.
#
# ----------------------------------
# Carga de variables de entorno
define LOAD_ENV
@set -a
@for f in $(ENV_FILES); do
  [ -f $$f ] && . $$f
@done
@set +a
endef

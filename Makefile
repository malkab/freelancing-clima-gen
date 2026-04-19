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
ENV_FILES := ./docker/assets/env
# Nombre base de los objetos devcontainer, para los targets que manipulan los
# contenedores.
BASE_NAME := freelancing-clima-gen
PG_DUMP_FILE := 20260419_123422-climagen.pgdump


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


# ----------------------------------
#
# Targets.
#
# ----------------------------------
# Exec en Python.
ifeq ($(INSIDE_CONTAINER),false)
docker-exec-python:
	$(LOAD_ENV)
	docker exec -ti \
		--workdir /workspace \
		$(BASE_NAME)-python \
		/bin/bash
endif


# Exec en Node.
ifeq ($(INSIDE_CONTAINER),false)
docker-exec-node:
	$(LOAD_ENV)
	docker exec -ti \
		--user node \
		--workdir /workspace \
		$(BASE_NAME)-node \
		/bin/bash
endif


# Arranca el Compose.
ifeq ($(INSIDE_CONTAINER),false)
docker-compose-up:
	$(LOAD_ENV)
	docker compose \
		-f docker/docker-compose.yml \
		-p $(BASE_NAME) \
		up -d
endif


# Apaga el Compose.
ifeq ($(INSIDE_CONTAINER),false)
docker-compose-down:
	$(LOAD_ENV)
	docker compose \
		-f docker/docker-compose.yml \
		-p $(BASE_NAME) \
		down
endif


# Para los contenedores.
ifeq ($(INSIDE_CONTAINER),false)
docker-containers-stop:
	$(LOAD_ENV)
	docker ps --filter name=$(BASE_NAME)* -q | xargs -r docker stop
endif


# Limpia contenedores.
ifeq ($(INSIDE_CONTAINER),false)
docker-containers-rm:
	$(LOAD_ENV)
	read -p "¿Eliminar contenedores [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker ps --filter name=$(BASE_NAME)* -q | xargs -r docker stop
		docker ps -a --filter name=$(BASE_NAME)* -q | xargs -r docker rm
	fi
endif


# psql.
ifeq ($(INSIDE_CONTAINER),false)
pg-psql:
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
docker-volume-rm:
	$(LOAD_ENV)
	read -p "¿Eliminar volúmenes [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker volume ls -q | grep $(BASE_NAME) | xargs -r docker volume rm
	fi
endif


# PG backup.
ifeq ($(INSIDE_CONTAINER),false)
pg-dump:
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
			$(BASE_NAME)-postgres \
			-b -F c -v -Z 9 \
			--no-privileges \
			-f $(DATE)-$(PG_DUMP_FILE)
	fi
endif


# Borra todo rastro del Compose salvo los volúmenes, aunque
# borrar los volúmenes huérfanos.
ifeq ($(INSIDE_CONTAINER),false)
docker-compose-rm:
	$(LOAD_ENV)
	read -p "¿Eliminar infraestructura Docker (salvo volúmenes) [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker ps --filter name=$(BASE_NAME)* -q | xargs -r docker stop -t0
		docker ps -a --filter name=$(BASE_NAME)* -q | xargs -r docker rm
		docker image ls --filter reference=*$(BASE_NAME)* -q | xargs -r docker image rm
		docker network ls --filter name=$(BASE_NAME) -q | xargs -r docker network rm
		docker volume prune -f
	fi
endif


# Logs de la API Python.
ifeq ($(INSIDE_CONTAINER),false)
docker-logs-python:
	$(LOAD_ENV)
	docker logs -f $(BASE_NAME)-python
endif


# Logs de NGINX.
ifeq ($(INSIDE_CONTAINER),false)
docker-logs-nginx:
	$(LOAD_ENV)
	docker logs -f $(BASE_NAME)-nginx
endif


# Reiniciar el NGINX.
ifeq ($(INSIDE_CONTAINER),false)
docker-restart-nginx:
	$(LOAD_ENV)
	docker restart $(BASE_NAME)-nginx
endif


# Reiniciar el NGINX.
ifeq ($(INSIDE_CONTAINER),false)
docker-restart-martin:
	$(LOAD_ENV)
	docker restart $(BASE_NAME)-martin
endif


# Ejecución del servidor de desarrollo.
ifeq ($(INSIDE_CONTAINER),false)
docker-node-run-dev:
	$(LOAD_ENV)
	docker exec -ti \
		--workdir /workspace/frontend \
		--user node \
		$(BASE_NAME)-node \
		npm run dev
endif


# Restauración de la base de datos.
#
# Selección de objetos, se pueden combinar múltiples opciones
# según haga falta:
#
# Exportación de esquemas específicos: 		-n 'schema*'
# Exportación de tablas específicas: 		-t 'schema*.table*'
# Excluir esquemas específicos: 			-N 'schema*'
# Excluir tablas específicas: 				-T 'schema*.table*'
# Libre de owner y privilegios: 			--no-owner --no-privileges
ifeq ($(INSIDE_CONTAINER),false)
pg-restore:
	$(LOAD_ENV)
	read -p "¿Se ha configurado correctamente el restore, seguro que quiere restaurar [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker run -ti --rm \
			-v $(PWD):/workspace/ \
			--workdir /workspace/ \
			--entrypoint pg_restore \
			--network $(BASE_NAME) \
			-e PGHOST=$$PGHOST \
			-e PGPORT=$$PGPORT \
			-e PGUSER=$$PGUSER \
			-e PGPASSWORD=$$PGPASSWORD \
			-e PGCLIENTENCODING=UTF8 \
			-e PGOPTIONS='-c statement_timeout=0 -c idle_in_transaction_session_timeout=0' \
			$(BASE_NAME)-postgres \
			-F c -v -j 8 \
			--no-owner --no-privileges \
			-d $$PGDATABASE \
			$(PG_DUMP_FILE)
	fi
	echo "No olvidar restaurar usuarios y privilegios si es necesario y hacer un vacuum analyze."
endif
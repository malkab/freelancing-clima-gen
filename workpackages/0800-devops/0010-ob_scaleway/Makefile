# ----------------------------------
#
# Cabecera, no tocar, debe estar aquí.
# Las variables que se definen aquí se expanden
# con $(VARIABLE).
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
# Los targets phony son aquellos que no hacen referencia a ningún
# fichero a compilar.
.PHONY:
# Estos ficheros env se aplican en el orden dado y las variables
# en ellos se van sobreescribiendo. Las variables que se definen
# aquí se expanden con $$VARIABLE
ENV_FILES := ./assets/env
# Nombre base de los objetos devcontainer, para los targets que
# manipulan los contenedores.
BASE_NAME := clima-gen
PG_DUMP_FILE := climagen-produccion.pgdump

# Directorio de la base de código.
CODE_BASE_DIR := $(PWD)/../../..

# Versiones imágenes básicas.
NGINX_PRODUCTION_DOCKER_TAG := 1.30.0-alpine3.23
POSTGRES_PRODUCTION_DOCKER_TAG := 18-3.6
MARTIN_PRODUCTION_DOCKER_TAG := v0.16.0
NODE_BUILD_DOCKER_TAG := trixie
PYTHON_API_DOCKER_TAG := 3.12-slim



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


# ------------------------------
#
# Targets.
#
# ------------------------------
# Arranca un Compose con un perfil opcional.
docker-compose-up:
	$(LOAD_ENV)
	docker compose \
		-f docker-compose.yml \
		-p $(BASE_NAME) \
		up -d


# Detiene el Compose.
docker-compose-down:
	$(LOAD_ENV)
	docker compose \
		-f docker-compose.yml \
		-p $(BASE_NAME) \
		down


# Eliminamos el Compose, salvo volúmenes.
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


# Mega build
build: build-frontend build-postgres build-api


# Build del frontend.
build-frontend:
	$(LOAD_ENV)

	docker pull nginx:$(NGINX_PRODUCTION_DOCKER_TAG)
	docker pull node:$(NODE_BUILD_DOCKER_TAG)

	rm -rf ${CODE_BASE_DIR}/frontend/dist

	docker run --rm \
		-v ${CODE_BASE_DIR}/frontend:/workspace/frontend \
		--workdir /workspace/frontend \
		--entrypoint /bin/bash \
		--user node:node \
		node:$(NODE_BUILD_DOCKER_TAG) \
		-c "npm install ; npm run build"

	rm -rf ./assets/nginx/src
	mkdir -p ./assets/nginx/src

	rsync -ravhP --info=progress2 --delete --delete-excluded \
		${CODE_BASE_DIR}/frontend/dist/ \
		./assets/nginx/src

	cd ./assets/nginx

	docker build \
		--build-arg TAG=$(NGINX_PRODUCTION_DOCKER_TAG) \
		-t $(BASE_NAME)-nginx:latest .


# Build de la API.
build-api:
	$(LOAD_ENV)

	docker pull python:$(PYTHON_API_DOCKER_TAG)

	rm -rf ./assets/api/src
	mkdir -p ./assets/api/src

	rsync -ravhP --info=progress2 --delete --delete-excluded \
		--exclude "__pycache__" \
		${CODE_BASE_DIR}/api/ \
		./assets/api/src

	cd ./assets/api

	docker build \
		--build-arg TAG=$(PYTHON_API_DOCKER_TAG) \
		-t $(BASE_NAME)-api:latest .


# Build de la PostgreSQL.
build-postgres:
	$(LOAD_ENV)

	docker pull postgis/postgis:18-3.6

	cd ./assets/postgresql

	docker build \
		--build-arg TAG=$(POSTGRES_PRODUCTION_DOCKER_TAG) \
		-t $(BASE_NAME)-postgres:latest .


# psql.
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
		$(BASE_NAME)-postgres


# Restore database.
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


# Guardar las imágenes Docker.
images-save:
	$(LOAD_ENV)

	rm -Rf images
	mkdir -p images

	cd ./images/

	docker save $(BASE_NAME)-nginx:latest | gzip > $(BASE_NAME)-nginx.tar.gz

	docker save $(BASE_NAME)-postgres:latest | gzip > $(BASE_NAME)-postgres.tar.gz

	docker save ghcr.io/maplibre/martin:v0.16.0 | gzip > martin.tar.gz

	docker save $(BASE_NAME)-api:latest | gzip > $(BASE_NAME)-api.tar.gz

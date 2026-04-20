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
DATE := $(shell date +%Y%m%d_%H%M%S)
HOSTNAME := $(strip $(shell hostname -s))
PROD_HOSTNAME := ubuntu


# ----------------------------------
#
# Configuración.
#
# ----------------------------------
# Estos ficheros env se aplican en el orden dado y las variables
# en ellos se van sobreescribiendo. Las variables que se definen
# aquí se expanden con $$VARIABLE.
ENV_FILES := ./assets/env_files/postgresql.env \
			 ./assets/env_files/deployment.env
# Nombre base de los objetos devcontainer, para los targets que
# manipulan los contenedores.
BASE_NAME := clima-gen-test
PG_DUMP_FILE := climagen-produccion.pgdump

# Directorio de la base de código.
CODE_BASE_DIR := $(PWD)/../../..

# Versiones imágenes básicas.
NGINX_PRODUCTION_DOCKER_TAG := 1.30.0-alpine3.23
POSTGRES_PRODUCTION_DOCKER_TAG := 18-3.6
MARTIN_PRODUCTION_DOCKER_TAG := 1.6.0
PYTHON_API_PRODUCTION_DOCKER_TAG := 3.12-slim
NODE_BUILD_DOCKER_TAG := trixie


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
# Targets específicos del host remoto.
#
# ------------------------------
ifeq ($(HOSTNAME),$(PROD_HOSTNAME))


.PHONY: docker-compose-up docker-compose-down docker-compose-rm pg-psql pg-init pg-restore docker-images-load docker-volume-mount


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


# psql.
pg-psql:
	$(LOAD_ENV)
	docker run -ti --rm \
		--workdir /workspace \
		--network $(BASE_NAME) \
		--entrypoint psql \
		-e PGHOST=$$PGHOST \
		-e PGPORT=$$PGPORT \
		-e PGUSER=$$PGUSER \
		-e PGDATABASE=$$PGDATABASE \
		-e PGPASSWORD=$$PGPASSWORD \
		-v $(PWD):/workspace \
		$(BASE_NAME)-postgres


# Inicializa la base de datos.
pg-init:
	$(LOAD_ENV)
	echo "Creando volumen para datos de PostgreSQL..."

	docker volume create $(BASE_NAME)-postgres-data

	echo "Iniciando contenedor temporal para configurar la base de datos..."

	docker run -d \
		--name $(BASE_NAME)-postgres-init \
		--workdir /workspace/ \
		-e POSTGRES_PASSWORD=$$PGPASSWORD \
		-v $(PWD):/workspace/ \
		-v $(BASE_NAME)-postgres-data:/var/lib/postgresql/ \
		-v ./assets/postgresql/postgresql.conf:/etc/postgresql/postgresql.conf:ro \
		$(BASE_NAME)-postgres

	sleep 15

	echo "Restaurando base de datos desde dump..."

	docker exec -ti \
		-e PGHOST=localhost \
		-e PGPORT=$$PGPORT \
		-e PGUSER=$$PGUSER \
		-e PGPASSWORD=$$PGPASSWORD \
		-e PGCLIENTENCODING=UTF8 \
		-e PGOPTIONS='-c statement_timeout=0 -c idle_in_transaction_session_timeout=0' \
		$(BASE_NAME)-postgres-init \
		pg_restore \
			-F c -v -j 8 \
			--no-owner --no-privileges \
			-d $$PGDATABASE \
			$(PG_DUMP_FILE)

	echo "Realizando vacuum analyze..."

	docker exec -ti \
		-e PGHOST=localhost \
		-e PGPORT=$$PGPORT \
		-e PGUSER=$$PGUSER \
		-e PGPASSWORD=$$PGPASSWORD \
		-e PGCLIENTENCODING=UTF8 \
		-e PGOPTIONS='-c statement_timeout=0 -c idle_in_transaction_session_timeout=0' \
		$(BASE_NAME)-postgres-init \
		psql -d $$PGDATABASE -c "vacuum analyze;"

	sleep 5

	echo "Limpiando contenedor temporal..."

	docker stop $(BASE_NAME)-postgres-init
	docker rm $(BASE_NAME)-postgres-init


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


# Carga las imágenes.
docker-images-load:
	$(LOAD_ENV)
	cd ./images/

	docker image load < $(BASE_NAME)-nginx.tar.gz
	docker image load < $(BASE_NAME)-postgres.tar.gz
	docker image load < $(BASE_NAME)-martin.tar.gz
	docker image load < $(BASE_NAME)-api.tar.gz


# Montaje de volúmenes.
docker-volume-mount:
	$(LOAD_ENV)
	docker run -ti --rm \
		--entrypoint /bin/bash \
		--workdir / \
		-v $(BASE_NAME)-postgres-data:/volume-$(BASE_NAME)-postgres-data \
		$(BASE_NAME)-api:latest


endif


# ------------------------------
#
# Targets específicos del host de build.
#
# ------------------------------
ifneq ($(HOSTNAME),$(PROD_HOSTNAME))


.PHONY: build build-frontend build-api build-postgres docker-images-load docker-images-save docker-images-rm rsync-delete-dryrun rsync-delete


# Mega build
build: build-frontend build-postgres build-api


# Build del frontend.
build-frontend:
	$(LOAD_ENV)
	rm -rf $(CODE_BASE_DIR)/frontend/dist

	docker run --rm \
		-v $(CODE_BASE_DIR)/frontend:/workspace/frontend \
		--workdir /workspace/frontend \
		--entrypoint /bin/bash \
		--user node:node \
		node:$(NODE_BUILD_DOCKER_TAG) \
		-c "npm install ; npm run build"

	rm -rf ./assets/nginx/src
	mkdir -p ./assets/nginx/src

	rsync -ravhP --info=progress2 --delete --delete-excluded \
		$(CODE_BASE_DIR)/frontend/dist/ \
		./assets/nginx/src

	cd ./assets/nginx

	docker build \
		--build-arg TAG=$(NGINX_PRODUCTION_DOCKER_TAG) \
		-t $(BASE_NAME)-nginx:latest .


# Build de la API.
build-api:
	$(LOAD_ENV)
	rm -rf ./assets/api/src
	mkdir -p ./assets/api/src

	rsync -ravhP --info=progress2 --delete --delete-excluded \
		--exclude "__pycache__" \
		$(CODE_BASE_DIR)/api/ \
		./assets/api/src

	cd ./assets/api

	docker build \
		--build-arg TAG=$(PYTHON_API_PRODUCTION_DOCKER_TAG) \
		-t $(BASE_NAME)-api:latest .


# Build de la PostgreSQL.
build-postgres:
	$(LOAD_ENV)
	cd ./assets/postgresql

	docker build \
		--build-arg TAG=$(POSTGRES_PRODUCTION_DOCKER_TAG) \
		-t $(BASE_NAME)-postgres:latest .


# Elimina las imágenes Docker.
docker-images-rm:
	$(LOAD_ENV)
	read -p "¿Eliminar imágenes Docker [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker image ls --filter reference=*$(BASE_NAME)* -q | xargs -r docker image rm
		docker image rm ghcr.io/maplibre/martin:$(MARTIN_PRODUCTION_DOCKER_TAG)
	fi


# Hace pull de las imágenes Docker base.
docker-images-pull:
	$(LOAD_ENV)
	echo "$${GITHUB_TOKEN}" | docker login ghcr.io -u $${GITHUB_USERNAME} --password-stdin

	docker pull ghcr.io/maplibre/martin:$(MARTIN_PRODUCTION_DOCKER_TAG)
	docker pull python:$(PYTHON_API_PRODUCTION_DOCKER_TAG)
	docker pull nginx:$(NGINX_PRODUCTION_DOCKER_TAG)
	docker pull postgis/postgis:$(POSTGRES_PRODUCTION_DOCKER_TAG)
	docker pull node:$(NODE_BUILD_DOCKER_TAG)


# Guardar las imágenes Docker.
docker-images-save:
	$(LOAD_ENV)
	rm -Rf images
	mkdir -p images

	cd ./images/

	docker save $(BASE_NAME)-nginx:latest | gzip > $(BASE_NAME)-nginx.tar.gz
	docker save $(BASE_NAME)-postgres:latest | gzip > $(BASE_NAME)-postgres.tar.gz
	docker save ghcr.io/maplibre/martin:$(MARTIN_PRODUCTION_DOCKER_TAG) | gzip > $(BASE_NAME)-martin.tar.gz
	docker save $(BASE_NAME)-api:latest | gzip > $(BASE_NAME)-api.tar.gz


# rsync delete dry.
rsync-delete-dryrun:
	$(LOAD_ENV)
	rsync -ravhPz --info=progress2 --delete --delete-excluded --dry-run \
		--exclude-from="${PWD}/rsync-exclude" \
		"${PWD}/" \
		"$$SSH_HOST:$$DEPLOYMENT_FOLDER/"


# rsync delete.
rsync-delete:
	$(LOAD_ENV)
	read -p "¡OJO! Este rsync es destructivo. Comprobar primero con rsync-dryrun_delete. ¿Continuar [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		rsync -ravhPz --info=progress2 --delete --delete-excluded \
			--exclude-from="${PWD}/rsync-exclude" \
			"${PWD}/" \
			"$$SSH_HOST:$$DEPLOYMENT_FOLDER/"
	fi


endif
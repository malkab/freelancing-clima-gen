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
# Targets específicos del host remoto.
#
# ------------------------------
ifeq ($(HOSTNAME),$(PROD_HOSTNAME))


.PHONY: docker-compose-up docker-compose-down docker-compose-rm tls-init tls-status pg-psql pg-init pg-restore images-load docker-volume-mount


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


# Primera emisión de certificado TLS con Let's Encrypt.
tls-init:
	$(LOAD_ENV)
	if [ -z "$$LETSENCRYPT_DOMAIN" ] || [ -z "$$LETSENCRYPT_EMAIL" ]; then
		echo "Defina LETSENCRYPT_DOMAIN y LETSENCRYPT_EMAIL en assets/env";
		exit 1;
	fi

	DOMAIN_ARGS="-d $$LETSENCRYPT_DOMAIN"
	if [ -n "$$LETSENCRYPT_DOMAIN_WWW" ]; then
		DOMAIN_ARGS="$$DOMAIN_ARGS -d $$LETSENCRYPT_DOMAIN_WWW"
	fi

	STAGING_FLAG=""
	if [ "$$LETSENCRYPT_STAGING" = "1" ]; then
		STAGING_FLAG="--staging"
	fi

	docker volume create clima-gen-letsencrypt-data
	docker volume create clima-gen-certbot-www

	docker run -d \
		--name $(BASE_NAME)-nginx-tls-init \
		-p 80:80 \
		-v clima-gen-letsencrypt-data:/etc/letsencrypt \
		-v clima-gen-certbot-www:/var/www/certbot \
		-v ./assets/nginx/nginx-tls-init.conf:/etc/nginx/nginx.conf:ro \
		$(BASE_NAME)-nginx:latest

	docker run --rm \
		-v clima-gen-certbot-www:/var/www/certbot \
		--entrypoint /bin/sh \
		certbot/certbot:v2.11.0 \
		-c 'mkdir -p /var/www/certbot/.well-known/acme-challenge && echo preflight-ok > /var/www/certbot/.well-known/acme-challenge/preflight'

	curl -fsS "http://$$LETSENCRYPT_DOMAIN/.well-known/acme-challenge/preflight" >/dev/null || { \
		echo "Preflight ACME check failed: no se puede resolver /.well-known/acme-challenge/preflight"; \
		echo "Revise DNS, apertura de puerto 80 y configuración de NGINX para webroot ACME."; \
		exit 1; \
	}

	docker run -ti \
		--name $(BASE_NAME)-certbot-init \
	    -v clima-gen-letsencrypt-data:/etc/letsencrypt \
      	-v clima-gen-certbot-www:/var/www/certbot \
		--entrypoint certbot \
		certbot/certbot:v2.11.0 \
		certonly --webroot -w /var/www/certbot \
  			--preferred-challenges http \
  			--cert-name default \
  			--email $$LETSENCRYPT_EMAIL \
  			--agree-tos --no-eff-email \
  			$$DOMAIN_ARGS

	docker stop $(BASE_NAME)-nginx-tls-init
	docker rm $(BASE_NAME)-nginx-tls-init $(BASE_NAME)-certbot-init


# Muestra la caducidad actual del certificado activo.
tls-status:
	$(LOAD_ENV)
	docker compose -f docker-compose.yml -p $(BASE_NAME) exec nginx \
		openssl x509 -in /etc/letsencrypt/live/default/fullchain.pem -noout -issuer -subject -dates


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


# Inicializa la base de datos.
pg-init:
	$(LOAD_ENV)
	docker volume create clima-gen-postgres-data2

	docker run -d \
		--name $(BASE_NAME)-postgres-init \
		-v $(PWD):/workspace/ \
		--workdir /workspace/ \
      	-v clima-gen-postgres-data2:/var/lib/postgresql/ \
      	-v ./assets/postgresql/postgresql.conf:/etc/postgresql/postgresql.conf:ro \
		$(BASE_NAME)-postgres

	sleep 30

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
images-load:
	$(LOAD_ENV)

	cd ./images/

	docker image load < $(BASE_NAME)-nginx.tar.gz
	docker image load < $(BASE_NAME)-postgres.tar.gz
	docker image load < martin.tar.gz
	docker image load < $(BASE_NAME)-api.tar.gz
	docker image load < certbot.tar.gz


# Montaje de volúmenes.
docker-volume-mount:
	$(LOAD_ENV)
	docker run -ti --rm \
		--entrypoint /bin/bash \
		--workdir / \
		-v clima-gen-postgres-data:/volume-clima-gen-postgres-data \
		-v clima-gen-letsencrypt-data:/volume-clima-gen-letsencrypt-data \
		-v clima-gen-certbot-www:/volume-clima-gen-certbot-www \
		clima-gen-api:latest


endif


# ------------------------------
#
# Targets específicos del host de build.
#
# ------------------------------
ifneq ($(HOSTNAME),$(PROD_HOSTNAME))


.PHONY: build build-frontend build-api build-postgres images-save rsync-delete-dryrun rsync-delete


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


# Guardar las imágenes Docker.
images-save:
	$(LOAD_ENV)

	docker pull certbot/certbot:v2.11.0

	rm -Rf images
	mkdir -p images

	cd ./images/

	docker save $(BASE_NAME)-nginx:latest | gzip > $(BASE_NAME)-nginx.tar.gz
	docker save $(BASE_NAME)-postgres:latest | gzip > $(BASE_NAME)-postgres.tar.gz
	docker save ghcr.io/maplibre/martin:v0.16.0 | gzip > martin.tar.gz
	docker save $(BASE_NAME)-api:latest | gzip > $(BASE_NAME)-api.tar.gz
	docker save certbot/certbot:v2.11.0 | gzip > certbot.tar.gz


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
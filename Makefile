# ----------------------------------
#
# Cabecera, no tocar, debe estar aquí.
#
# ----------------------------------
.ONESHELL:
SHELL := /bin/bash
PWD := $(shell pwd)
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
ENV_FILES := ./docker/assets/env_files/env.env ./docker/assets/env_files/deployment.env
# Nombre base de los objetos devcontainer, para los targets que manipulan los
# contenedores.
BASE_NAME := freelancing-clima-gen
PG_DUMP_FILE := climagen.pgdump

# Versiones imágenes básicas.
POSTGRES_DOCKER_TAG := 18-3.6
MARTIN_DOCKER_TAG := 1.6.0
NODE_DOCKER_TAG := trixie
NGINX_DOCKER_TAG := 1.29.2-trixie


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
docker-exec-python:
	$(LOAD_ENV)
	docker exec -ti \
		--workdir /workspace \
		$(BASE_NAME)-python \
		/bin/bash


# Exec en Node.
docker-exec-node:
	$(LOAD_ENV)
	docker exec -ti \
		--user node \
		--workdir /workspace \
		$(BASE_NAME)-node \
		/bin/bash


# Arranca el Compose.
docker-compose-up:
	$(LOAD_ENV)
	docker compose \
		-f docker/docker-compose.yml \
		-p $(BASE_NAME) \
		up -d


# Apaga el Compose.
docker-compose-down:
	$(LOAD_ENV)
	docker compose \
		-f docker/docker-compose.yml \
		-p $(BASE_NAME) \
		down


# Para los contenedores.
docker-containers-stop:
	$(LOAD_ENV)
	docker ps --filter name=$(BASE_NAME)* -q | xargs -r docker stop


# Limpia contenedores.
docker-containers-rm:
	$(LOAD_ENV)
	read -p "¿Eliminar contenedores [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker ps --filter name=$(BASE_NAME)* -q | xargs -r docker stop
		docker ps -a --filter name=$(BASE_NAME)* -q | xargs -r docker rm
	fi


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


# ¡MUCHO CUIDADO! Tira los volúmenes.
docker-volume-rm:
	$(LOAD_ENV)
	read -p "¿Eliminar volúmenes [s/N]? " confirm
	if [ "$$confirm" = "s" ]; then
		docker volume ls -q | grep $(BASE_NAME) | xargs -r docker volume rm
	fi


# Respaldo de la base de datos.
#
# Selección de objetos, se pueden combinar múltiples opciones
# según haga falta:
#
#
# Exportación de esquemas específicos: 		-n 'schema*'
# Exportación de tablas específicas: 		-t 'schema*.table*'
# Excluir esquemas específicos: 			-N 'schema*'
# Excluir tablas específicas: 				-T 'schema*.table*'
#
# ¡Ojo! Los -n y los -t no se pueden mezclar.
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


# Dump excluyendo el esquema raw.
pg-dump-produccion:
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
			-N raw \
			--no-privileges \
			-f $(DATE)-climagen-produccion.pgdump
	fi


# Borra todo rastro del Compose salvo los volúmenes, aunque
# borrar los volúmenes huérfanos.
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


# Hace pull de las imágenes Docker base.
docker-images-pull:
	$(LOAD_ENV)
	echo "$${GITHUB_TOKEN}" | docker login ghcr.io -u $${GITHUB_USERNAME} --password-stdin

	scp ob:/home/obs/imagenes_docker/data_awkward_armadillo_9dca87.tar.gz .
	docker image load < data_awkward_armadillo_9dca87.tar.gz

	docker pull ghcr.io/maplibre/martin:$(MARTIN_DOCKER_TAG)
	docker pull postgis/postgis:$(POSTGRES_DOCKER_TAG)
	docker pull node:$(NODE_DOCKER_TAG)
	docker pull nginx:$(NGINX_DOCKER_TAG)

	rm ./data_awkward_armadillo_9dca87.tar.gz


# Logs de la API Python.
docker-logs-python:
	$(LOAD_ENV)
	docker logs -f $(BASE_NAME)-python


# Logs de NGINX.
docker-logs-nginx:
	$(LOAD_ENV)
	docker logs -f $(BASE_NAME)-nginx


# Reiniciar el NGINX.
docker-restart-nginx:
	$(LOAD_ENV)
	docker restart $(BASE_NAME)-nginx


# Reiniciar el NGINX.
docker-restart-martin:
	$(LOAD_ENV)
	docker restart $(BASE_NAME)-martin


# Ejecución del servidor de desarrollo.
docker-exec-node-run-dev:
	$(LOAD_ENV)
	docker exec -ti \
		--workdir /workspace/frontend \
		--user node \
		$(BASE_NAME)-node \
		npm run dev


# Ejecución del servidor de desarrollo.
docker-exec-node-run-build:
	$(LOAD_ENV)
	docker exec -ti \
		--workdir /workspace/frontend \
		--user node \
		$(BASE_NAME)-node \
		npm run build


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


# OpenCode.
docker-exec-opencode-python:
	$(LOAD_ENV)
	docker exec -ti \
		--workdir /workspace \
		--user vscode \
		$(BASE_NAME)-python \
		/bin/bash -c "/home/vscode/.opencode/bin/opencode"


docker-exec-opencode-node:
	$(LOAD_ENV)
	docker exec -ti \
		--workdir /workspace \
		--user node \
		$(BASE_NAME)-node \
		/bin/bash -c "/home/node/.opencode/bin/opencode"


# Sirve el dist del frontend para depuración.
docker-nginx-serve-dist:
	$(LOAD_ENV)
	echo "Sirviendo el dist del frontend en http://localhost:8090"

	docker run -ti --rm \
		--network $(BASE_NAME) \
		-v $(PWD)/docker/assets/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
		-v $(PWD)/frontend/dist:/app:ro \
		-v $(PWD)/docker/assets/nginx/runtime-config.json:/app/runtime-config.json:ro \
		-p 8090:80 \
		nginx:$(NGINX_DOCKER_TAG)
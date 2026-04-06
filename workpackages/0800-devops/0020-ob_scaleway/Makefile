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
# Los targets phony son aquellos que no hacen referencia a ningún fichero a
# compilar.
.PHONY:
# Estos ficheros env se aplican en el orden dado y las variables en ellos se van
# sobreescribiendo.
# Las variables que se definen aquí se expanden con $$VARIABLE
ENV_FILES := ./.devcontainer/assets/env ./.devcontainer/assets/env2
# Nombre base de los objetos devcontainer, para los targets que manipulan los
# contenedores.
BASE_NAME := freelancing-clima-gen
PG_DUMP_FILE := dump_file.pgdump


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
# Iniciar servicios.
docker_compose_up:
	$(LOAD_ENV)
	docker compose -p $$BASE_NAME -f docker-compose.yml up -d


# # Parar servicios.
# docker_compose_down:
# 	$(LOAD_ENV)
# 	docker compose -p $$BASE_NAME -f docker-compose.yml down


# # Arranca sólo la base de datos.
# docker_compose_up_pg:
# 	$(LOAD_ENV)
# 	docker compose -p $$BASE_NAME -f docker-compose.yml \
# 		up -d rdg-datalake-postgres


# # Refresca el Compose.
# docker_compose_recreate:
# 	$(LOAD_ENV)
# 	docker compose -p $$BASE_NAME -f docker-compose.yml \
# 		up --force-recreate -d


# # Borrar los contenedores.
# docker_container_rm:
# 	$(LOAD_ENV)
# 	read -p "¿Eliminar contenedores [s/N]? " confirm
# 	if [ "$$confirm" = "s" ]; then
# 		docker ps --filter name="$$BASE_NAME*" -q | xargs -r docker stop
# 		docker ps -a --filter name="$$BASE_NAME*" -q | xargs -r docker rm
# 	fi


# # Refresca el frontend, imagen incluida.
# docker_compose_recreate_frontend_image:
# 	$(LOAD_ENV)
# 	docker stop rdg-datalake-rdg-datalake-frontend-1
# 	docker rm rdg-datalake-rdg-datalake-frontend-1

# 	cd ./images/
# 	docker load < rdg-base-frontend.tar.gz
# 	cd ..

# 	docker compose -p $$BASE_NAME -f docker-compose.yml \
# 		up -d rdg-datalake-frontend


# # Refresca el frontend sin refrescar la imagen.
# docker_compose_recreate_frontend:
# 	$(LOAD_ENV)
# 	docker stop rdg-datalake-rdg-datalake-frontend-1
# 	docker rm rdg-datalake-rdg-datalake-frontend-1

# 	docker compose -p $$BASE_NAME -f docker-compose.yml \
# 		up -d rdg-datalake-frontend


# # Hace exec en el contenedor del frontend.
# docker_exec_frontend:
# 	$(LOAD_ENV)
# 	docker exec -ti rdg-datalake-rdg-datalake-frontend-1 /bin/bash


# # Hace exec en el contenedor del API.
# docker_exec_api:
# 	$(LOAD_ENV)
# 	docker exec -ti rdg-datalake-rdg-datalake-api-1 /bin/bash


# # Hace exec en el contenedor del Airflow webserver.
# docker_exec_airflow_webserver:
# 	$(LOAD_ENV)
# 	docker exec -ti rdg-datalake-rdg-datalake-airflow-webserver-1 /bin/bash


# # Conectar a PostgreSQL
# pg_psql:
# 	$(LOAD_ENV)
# 	docker run --rm -ti \
# 		--entrypoint /bin/bash \
# 		--network $$NETWORK_NAME \
# 		-v $(PWD)/assets:/assets \
# 		rdg-base-postgis \
# 		-c " \
# 			PGPASSWORD=$$PG_PASS \
# 			PGOPTIONS='-c statement_timeout=0 -c idle_in_transaction_session_timeout=0' \
# 			psql -h $$PG_HOST -p $$PG_PORT -U $$PG_USER postgres"


# # Restaurar backup en PostgreSQL
# pg_restore:
# 	$(LOAD_ENV)
# 	docker run --rm -ti \
# 		--entrypoint /bin/bash \
# 		--network $$NETWORK_NAME \
# 		--workdir /db_dumps \
# 		-v $(PWD)/assets/postgres/db_dumps/:/db_dumps/ \
# 		rdg-base-postgis \
# 		-c " \
# 			PGPASSWORD=$$PG_PASS \
# 			PGOPTIONS='-c statement_timeout=0 -c idle_in_transaction_session_timeout=0' \
# 			pg_restore -F c -v -j 2 \
# 				--no-owner --no-privileges \
# 				-h $$PG_HOST \
# 				-p $$PG_PORT \
# 				-U $$PG_USER \
# 				-d datalake \
# 				$(PG_DUMP_FILE) \
# 		"


# # Backup de PostgreSQL
# pg_backup:
# 	@read -p "¿Se ha configurado correctamente el backup [s/N]? " confirm && \
# 	if [ "$$confirm" = "s" ]; then \
# 		docker run -ti --rm \
# 			--entrypoint /bin/bash \
# 			--network $$NETWORK_NAME \
# 			--workdir /db_dumps \
# 			-v $(PWD)/assets/postgres/db_dumps/:/db_dumps/ \
# 			rdg-base-postgis \
# 			-c " \
# 				PGPASSWORD=$$PG_PASS \
# 				PGOPTIONS='-c statement_timeout=0 -c idle_in_transaction_session_timeout=0' \
# 				pg_dump -b -F c -v -Z 9 \
# 					-f $$DATE-datalake_backup.pgdump \
# 					-h $$PG_HOST \
# 					-p $$PG_PORT \
# 					-U $$PG_USER \
# 					datalake \
# 			" ; \
# 	fi ; \
# 	exit 0


# # Traer datos de otros repositorios
# assets_gather:
# 	$(LOAD_ENV)

# 	cd assets

# 	./assets_gather.sh


# # Carga datos en MinIO
# minio_load_data:
# 	$(LOAD_ENV)
# 	docker run --rm -ti \
# 		--entrypoint /bin/bash \
# 		--network $$NETWORK_NAME \
# 		-v $(PWD)/assets/minio/:/data \
# 		-e MINIO_HOST=$$MINIO_HOST \
# 		-e MINIO_PORT=$$MINIO_PORT \
# 		-e MINIO_ROOT_USER=$$MINIO_ROOT_USER \
# 		-e MINIO_ROOT_PASSWORD=$$MINIO_ROOT_PASSWORD \
# 		rdg-base-minio \
# 		-c "/data/load_data.sh"


# # Despliega las imágenes Docker.
# docker_images_load: docker_images_load_airflow docker_images_load_api docker_images_load_frontend
# 	$(LOAD_ENV)
# 	cd ./images/
# 	docker load < rdg-base-keycloak.tar.gz
# 	docker load < rdg-base-martin.tar.gz
# 	docker load < rdg-base-minio.tar.gz
# 	docker load < rdg-base-nginx.tar.gz
# 	docker load < rdg-base-postgis.tar.gz
# 	docker load < rdg-base-rabbitmq.tar.gz
# 	docker load < rdg-base-redis.tar.gz


# # Despliega la imagen Docker del frontend.
# docker_images_load_frontend:
# 	$(LOAD_ENV)
# 	cd ./images/
# 	docker load < rdg-base-frontend.tar.gz


# # Despliega la imagen Docker del frontend.
# docker_images_load_api:
# 	$(LOAD_ENV)
# 	cd ./images/
# 	docker load < rdg-base-api.tar.gz


# # Despliega la imagen Docker del frontend.
# docker_images_load_airflow:
# 	$(LOAD_ENV)
# 	cd ./images/
# 	docker load < rdg-base-airflow.tar.gz


# # Monta los volúmenes.
# docker_volumes_mount:
# 	$(LOAD_ENV)
# 	docker run -ti --rm --init \
# 		--entrypoint /bin/bash \
#  		-v rdg-datalake-minio-data:/rdg-datalake-minio-data \
# 		-v rdg-datalake-postgres-data:/rdg-datalake-postgres-data \
# 		-v $(PWD):/workspace \
# 		rdg-base-api:latest


# # rsync dry.
# rsync_delete_dryrun:
# 	$(LOAD_ENV)
# 	cd ..
# 	rsync -ravhPz --info=progress2 --delete --delete-excluded --dry-run \
# 		--exclude='**/__pycache__/**' \
#     	$$DEPLOYMENT_NAME \
#     	$$SSH_HOST:$$DEPLOYMENT_FOLDER


# # rsync dry.
# rsync_dryrun:
# 	$(LOAD_ENV)
# 	cd ..
# 	rsync -ravhPz --info=progress2 --dry-run \
# 		--exclude='**/__pycache__/**' \
#     	$$DEPLOYMENT_NAME \
#     	$$SSH_HOST:$$DEPLOYMENT_FOLDER


# # rsync.
# rsync_delete:
# 	$(LOAD_ENV)
# 	@read -p "¡OJO! Este rsync es destructivo. Comprobar primero con rsync_dryrun_delete. ¿Continuar [s/N]? " confirm
# 	if [ "$$confirm" = "s" ]; then
# 		cd ..
# 		rsync -ravhPz --info=progress2 --delete --delete-excluded \
# 			--exclude='**/__pycache__/**' \
# 	    	$$DEPLOYMENT_NAME \
# 	    	$$SSH_HOST:$$DEPLOYMENT_FOLDER
# 	fi


# # rsync.
# rsync:
# 	$(LOAD_ENV)
# 	@read -p "¡OJO! Este rsync no es destructivo pero aún así puede pisar ficheros con el mismo nombre. Comprobar primero con rsync_dryrun. ¿Continuar [s/N]? " confirm
# 	if [ "$$confirm" = "s" ]; then
# 		cd ..

# 		rsync -ravhPz --info=progress2 \
# 			--exclude='**/__pycache__/**' \
# 	    	$$DEPLOYMENT_NAME \
# 	    	$$SSH_HOST:$$DEPLOYMENT_FOLDER
# # 		scp -r \
# # 	    	$$DEPLOYMENT_NAME \
# # 	    	$$SSH_HOST:$$DEPLOYMENT_FOLDER
# 	fi


# # rsync DAGS.
# rsync_dags:
# 	@read -p "Comprobar primero con rsync_dryrun. ¿Continuar [s/N]? " confirm && \
# 	if [ "$$confirm" = "s" ]; then \
# 		cd .. && rsync -avhPz --delete --delete-excluded \
# 			--exclude='**/__pycache__/**' \
# 	    	$$DEPLOYMENT_NAME/assets/api/src/airflow_dags/ \
# 	    	$$SSH_HOST:$$DEPLOYMENT_FOLDER/assets/api/src/airflow_dags/ ; \
# 		rsync -avhPz --delete --delete-excluded \
# 			--exclude='**/__pycache__/**' \
# 	    	$$DEPLOYMENT_NAME/assets/airflow/src/ \
# 	    	$$SSH_HOST:$$DEPLOYMENT_FOLDER/assets/airflow/src/ ; \
# 	fi


# # rync MinIO data.
# rsync_minio_data:
# 	@read -p "Comprobar primero con rsync_dryrun. ¿Continuar [s/N]? " confirm && \
# 	if [ "$$confirm" = "s" ]; then \
# 		cd .. && rsync -avhPz --delete --delete-excluded \
# 			--exclude='**/__pycache__/**' \
# 	    	$$DEPLOYMENT_NAME/assets/minio/ \
# 	    	$$SSH_HOST:$$DEPLOYMENT_FOLDER/assets/minio/ ; \
# 	fi


# # rync MinIO data.
# rsync_pg_dumps:
# 	@read -p "Comprobar primero con rsync_dryrun. ¿Continuar [s/N]? " confirm && \
# 	if [ "$$confirm" = "s" ]; then \
# 		cd .. && rsync -avhPz --delete --delete-excluded \
# 			--exclude='**/__pycache__/**' \
# 	    	$$DEPLOYMENT_NAME/assets/postgres/db_dumps/ \
# 	    	$$SSH_HOST:$$DEPLOYMENT_FOLDER/assets/postgres/db_dumps/ ; \
# 	fi


# # rync Docker images.
# rsync_docker_images:
# 	@read -p "Comprobar primero con rsync_dryrun. ¿Continuar [s/N]? " confirm && \
# 	if [ "$$confirm" = "s" ]; then \
# 		cd .. && rsync -avhPz --delete --delete-excluded \
# 			--exclude='**/__pycache__/**' \
# 	    	$$DEPLOYMENT_NAME/images/ \
# 	    	$$SSH_HOST:$$DEPLOYMENT_FOLDER/images/ ; \
# 	fi


# # Cliente a MinIO
# minio_client:
# 	@docker run -ti --rm \
# 		--entrypoint /bin/bash \
# 		--network $$NETWORK_NAME \
# 		-v $(PWD)/assets/minio/:/data \
# 		-e MINIO_HOST=$$MINIO_HOST \
# 		-e MINIO_PORT=$$MINIO_PORT \
# 		-e MINIO_ROOT_USER=$$MINIO_ROOT_USER \
# 		-e MINIO_ROOT_PASSWORD=$$MINIO_ROOT_PASSWORD \
# 		rdg-base-minio ; \
# 	exit 0


# # Limpia assets problemáticos
# assets_clean:
# 	@sudo rm -rf assets/api/src/


# # Backup de información importante
# info_backup:
# # Copia la base de datos local de autenticación
# 	@mkdir -p $$BACKUP_FOLDER \
# 	&& cp assets/api/src/local_auth.sqlite3 $$BACKUP_FOLDER


# # Restaura la información importante desde el backup
# info_restore:
# # Restaura la base de datos local de autenticación
# 	@read -p "Se va a restaurar un backup. ¿Continuar [s/N]? " confirm && \
# 	if [ "$$confirm" = "s" ]; then \
# 		cp $$BACKUP_FOLDER/local_auth.sqlite3 assets/api/src/ ; \
# 	fi

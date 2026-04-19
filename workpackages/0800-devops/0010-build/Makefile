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
ENV_FILES := ./.devcontainer/assets/env ./.devcontainer/assets/env2
# Nombre base de los objetos devcontainer, para los targets que
# manipulan los contenedores.
BASE_NAME := freelancing-clima-gen
PG_DUMP_FILE := dump_file.pgdump

# Directorio de la base de código.
CODE_BASE_DIR := $(PWD)/../../..

# Versiones imágenes básicas.
NGINX_PRODUCTION_DOCKER_TAG := 1.30.0-alpine3.23
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
# Targets.
#
# ------------------------------
# Mega build
build: build_frontend


# Build del frontend
build-frontend:
	$(LOAD_ENV)

	docker pull nginx:$(NGINX_PRODUCTION_DOCKER_TAG)
	docker pull node:$(NODE_BUILD_DOCKER_TAG)

	docker run --rm \
		-v ${CODE_BASE_DIR}/frontend:/workspace/frontend \
		--workdir /workspace/frontend \
		--entrypoint /bin/bash \
		--user node:node \
		node:$$NODE_BUILD_DOCKER_TAG \
		-c "npm install ; npm run build"

	rm -rf ./assets/nginx/src
	mkdir -p ./assets/nginx/src

	rsync -ravhP --info=progress2 --delete --delete-excluded \
		${CODE_BASE_DIR}/frontend/dist/ \
		./assets/nginx/src

	cd ./assets/nginx

	docker build \
		--build-arg TAG=$(NGINX_PRODUCTION_DOCKER_TAG) \
		-t clima-gen-nginx:latest .



# # Guardar las imágenes Docker.
# docker_images_save: docker_images_save_airflow docker_images_save_frontend docker_images_save_postgis docker_images_save_api
# 	$(LOAD_ENV)

# 	mkdir -p images

# 	cd ./images/

# 	rm -f rdg-base-keycloak.tar.gz
# 	docker save rdg-base-keycloak | gzip > rdg-base-keycloak.tar.gz

# 	rm -f rdg-base-martin.tar.gz
# 	docker save rdg-base-martin | gzip > rdg-base-martin.tar.gz

# 	rm -f rdg-base-minio.tar.gz
# 	docker save rdg-base-minio | gzip > rdg-base-minio.tar.gz

# 	rm -f rdg-base-nginx.tar.gz
# 	docker save rdg-base-nginx | gzip > rdg-base-nginx.tar.gz

# 	rm -f rdg-base-rabbitmq.tar.gz
# 	docker save rdg-base-rabbitmq | gzip > rdg-base-rabbitmq.tar.gz

# 	rm -f rdg-base-redis.tar.gz
# 	docker save rdg-base-redis | gzip > rdg-base-redis.tar.gz

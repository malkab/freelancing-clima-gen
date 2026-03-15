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
ENV_FILES := ./.devcontainer/assets/env ./.devcontainer/assets/env2
# Nombre base de los objetos devcontainer, para los targets que manipulan los
# contenedores.
BASE_NAME := freelancing-clima-gen


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


# Para los contenedores.
ifeq ($(INSIDE_CONTAINER),false)

docker_containers_stop:
	$(LOAD_ENV)

	docker ps --filter name=$(BASE_NAME)* -q | xargs -r docker stop; \

endif


# Limpia contenedores.
ifeq ($(INSIDE_CONTAINER),false)

docker_containers_rm:
	$(LOAD_ENV)

	read -p "¿Eliminar contenedores [s/N]? " confirm

	if [ "$$confirm" = "s" ]; then \
		docker ps --filter name=$(BASE_NAME)* -q | xargs -r docker stop; \
		docker ps -a --filter name=$(BASE_NAME)* -q | xargs -r docker rm; \
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

.ONESHELL:
SHELL := /bin/bash

.PHONY:

# ----------------------------------
#
# Ficheros env.
#
# ----------------------------------
# Nombre base de los objetos devcontainer.
BASE_NAME := freelancing-clima-gen

# Ficheros env en orden de overriding.
ENV_FILES := ./.devcontainer/assets/env

# Helpers.
PWD := $(shell pwd)
INSIDE_CONTAINER := $(shell [ -f /.dockerenv ] && echo true || echo false)
DATE := $(shell date +%Y%m%d_%H%M%S)
RUFF_NO_COLOR ?= 0
RUFF_ENV := $(if $(filter 1,$(RUFF_NO_COLOR)),NO_COLOR=1,)
TEST_PATH ?= src
TEST_ARGS ?=


# ----------------------------------


# Para contenedores.
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

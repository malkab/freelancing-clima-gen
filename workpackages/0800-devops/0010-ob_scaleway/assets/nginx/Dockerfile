ARG TAG=1.29.2-trixie

FROM nginx:${TAG}

LABEL author="Juan Pedro Perez"
LABEL email="jp.perez.alcantara@pm.me"

WORKDIR /

USER root

COPY ./src/ /app/

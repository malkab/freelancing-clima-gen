ARG TAG=1.29.2-trixie

FROM nginx:${TAG}

LABEL author="Juan Pedro Perez"
LABEL email="jp.perez.alcantara@pm.me"

WORKDIR /

USER root

# Actualizar apt.
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade && \
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

COPY ./src/ /app/

COPY ./nginx.conf /etc/nginx/nginx.conf
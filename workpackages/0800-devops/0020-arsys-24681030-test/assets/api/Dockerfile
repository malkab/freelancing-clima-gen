ARG TAG=3.12-slim

FROM python:${TAG}

LABEL author="Juan Pedro Perez"
LABEL email="jp.perez.alcantara@pm.me"

WORKDIR /

USER root

# Actualizar apt.
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade && \
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade && \
    apt-get install -y wget && \
    apt-get autoremove -y

# Instalar dependencias Python de proyecto.
COPY ./requirements.txt /requirements.txt
RUN pip install --upgrade -r /requirements.txt

# Copiar código.
COPY ./src/ /app/

WORKDIR /app
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
ARG TAG=3.12-slim

FROM python:${TAG}

LABEL author="Juan Pedro Perez"
LABEL email="jp.perez.alcantara@pm.me"

WORKDIR /

USER root

# Instalar dependencias Python de proyecto.
COPY ./requirements.txt /requirements.txt
RUN pip install --upgrade -r /requirements.txt

# Copiar código.
COPY ./src/ /app/

WORKDIR /app
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
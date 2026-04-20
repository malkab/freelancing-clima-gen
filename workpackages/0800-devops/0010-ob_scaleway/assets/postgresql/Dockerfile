ARG TAG=18-3.6

FROM postgis/postgis:${TAG}

LABEL author="Juan Pedro Perez"
LABEL email="jp.perez.alcantara@pm.me"

RUN localedef -i es_ES -c -f UTF-8 -A /usr/share/locale/locale.alias es_ES.UTF-8
ENV LANG=es_ES.UTF-8

# Ficheros de inicialización del servidor de base de datos.
# Comentado aquí porque lo cargamos como volumen en la imagen de
# desarrollo para mayor flexibilidad y no tener que rehacer la
# imagen.
COPY ./db_setup.sql /docker-entrypoint-initdb.d/

# Utilizar la configuración personalizada de PostgreSQL.
CMD ["-c", "config_file=/etc/postgresql/postgresql.conf"]

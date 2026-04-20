Puesta en marcha de la versión clima-gen-test.

```shell
# Pull de imágenes
make docker-images-pull

# Build de imágenes
make build

# Guardar las imágenes
make docker-images-save

# Subida
make rsync-delete-dryrun
make rsync-delete

# Carga de imágenes
make docker-images-load

# Inicialización de la base de datos
make pg-init

# Arranque del Compose
make docker-compose-up
```

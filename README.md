# Puesta en marcha del proyecto

Estos pasos son necesarios tras clonar el repo:

- restaurar la base de datos con `make pg_restore`
- entrar en `make docker_exec_node`, ir a frontend y ejecutar `npm install`


# Ejecución del proyecto

Ejecución de la aplicación en modo desarrollo:

- arrancar el Compose con `make docker_compose_up`
- arrancar el Vite del frontend con `make docker_node_run_dev`

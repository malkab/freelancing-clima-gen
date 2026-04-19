# Puesta en marcha del proyecto

Estos pasos son necesarios tras clonar el repo:

- restaurar la base de datos con `make pg_restore`
- entrar en `make docker_exec_node`, ir a frontend y ejecutar `npm install`


# Ejecución del proyecto

Ejecución de la aplicación en modo desarrollo:

- arrancar el Compose con `make docker_compose_up`
- arrancar el Vite del frontend con `make docker_node_run_dev`

El frontend está en `http://localhost:5173` y el backend en `http://localhost:8000/api/v1/health`.


# Proxy

Vite en el docker de Node.js hace de proxy para el backend y el Martin, ver vite.config.js.
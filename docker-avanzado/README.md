# Laboratorio — Docker Avanzado

## De contenedores individuales a una aplicación reproducible con Docker Compose

En la sesión anterior construimos y ejecutamos una aplicación compuesta por tres contenedores:

```text

Usuario

   ↓

Frontend / Nginx

   ↓

Backend / Flask

   ↓

PostgreSQL

```

En esta sesión **no vamos a reconstruir toda la aplicación desde cero**. Vamos a reutilizar las imágenes construidas anteriormente:

```text

saludos-frontend:1.0

saludos-backend:1.0

saludos-db:1.0

```

El objetivo es evolucionar la administración manual de estos contenedores hacia una aplicación definida y administrada mediante Docker Compose.

> **Docker Básico:** construir y ejecutar contenedores.

>

> **Docker Avanzado:** componer, configurar, persistir, verificar y diagnosticar una aplicación multicontenedor.

---

# 1. Prerrequisitos

```bash

docker version

docker compose version

docker image ls

```

Debemos encontrar:

```text

saludos-frontend:1.0

saludos-backend:1.0

saludos-db:1.0

```

---

# 2. Punto de partida

La aplicación anterior está organizada así:

```text

docker-basico/

│

├── frontend/

│   ├── Dockerfile

│   ├── index.html

│   └── nginx.conf

│

├── backend/

│   ├── Dockerfile

│   ├── app.py

│   └── requirements.txt

│

└── db/

    ├── Dockerfile

    └── init.sql

```

Arquitectura:

```text

Frontend

   │

   │ HTTP :5000

   ▼

Backend

   │

   │ PostgreSQL :5432

   ▼

Database

```

---

# 3. Reconocer el estado actual

```bash

docker ps -a

docker network ls

docker volume ls

```

Identificar qué elementos configurábamos manualmente:

- Contenedores

- Nombres

- Puertos

- Red

- Hostnames

- Configuración

- Almacenamiento

- Dependencias

### Pregunta

¿Qué información debería formar parte de una definición reproducible de la aplicación?

---

# 4. Crear `compose.yml` desde cero

El archivo `compose.yml` estará inicialmente vacío.

Agregar:

```yaml

services:

  frontend:

    image: saludos-frontend:1.0

  backend:

    image: saludos-backend:1.0

  database:

    image: saludos-db:1.0

```

Validar:

```bash

docker compose config

```

Levantar:

```bash

docker compose up -d

```

Verificar:

```bash

docker compose ps

```

---

# 5. Publicar el Frontend

Modificar:

```yaml

frontend:

  image: saludos-frontend:1.0

  ports:

    - "8080:80"

```

Aplicar:

```bash

docker compose up -d

```

Probar:

```text

http://localhost:8080

```

`ports` publica un puerto del contenedor hacia el host.

Backend y PostgreSQL no necesitan publicar sus puertos al host para comunicarse internamente.

---

# 6. Networking administrado por Compose

Verificar:

```bash

docker network ls

```

Inspeccionar la red creada por Compose:

```bash

docker network inspect <NOMBRE_DE_LA_RED>

```

Arquitectura:

```text

Frontend

   |

   | Docker Network

   ↓

Backend

   |

   | Docker Network

   ↓

Database

```

En Docker Básico creamos manualmente `saludos-network`. Ahora Compose administra esta red.

---

# 7. Service Discovery

El backend encuentra PostgreSQL utilizando el nombre del servicio:

```text

database

```

Verificar:

```bash

docker compose exec backend getent hosts database

```

La comunicación interna será:

```text

Backend → database:5432

```

No debemos utilizar una IP fija del contenedor.

---

# 8. Identificar configuración hardcodeada en `app.py`

Abrir:

```text

backend/app.py

```

Actualmente:

```python

def get_connection():

    return psycopg2.connect(

        host="database",

        database="saludos_db",

        user="saludos_user",

        password="saludos_password",

        port=5432

    )

```

Tenemos valores hardcodeados:

```text

database

saludos_db

saludos_user

saludos_password

5432

```

Queremos separar:

```text

Código

   ↓

Variables de entorno

   ↓

Configuración del ambiente

```

---

# 9. Refactorizar `app.py`

Agregar:

```python

import os

```

El inicio queda:

```python

from flask import Flask, jsonify

import psycopg2

import os

app = Flask(__name__)

```

Cambiar `get_connection()` por:

```python

def get_connection():

    return psycopg2.connect(

        host=os.getenv("DB_HOST", "database"),

        database=os.getenv("DB_NAME", "saludos_db"),

        user=os.getenv("DB_USER", "saludos_user"),

        password=os.getenv("DB_PASSWORD"),

        port=int(os.getenv("DB_PORT", "5432"))

    )

```

El mapeo será:

```text

DB_HOST       → database

DB_NAME       → saludos_db

DB_USER       → saludos_user

DB_PASSWORD   → contraseña

DB_PORT       → 5432

```

Además de las variables utilizadas para PostgreSQL, queremos que la aplicación conozca en qué ambiente está ejecutándose.

```python

@app.route("/config", methods=["GET"])

def config():

    return jsonify({

        "environment": os.getenv("APP_ENV", "default")

    })

```

La variable `APP_ENV` tendrá un valor diferente según el ambiente.

---

# 10. Reconstruir Backend

Como modificamos `app.py`, debemos reconstruir:

```bash

docker build -t saludos-backend:2.0 ./backend

```

Verificar:

```bash

docker image ls

```

Actualizar Compose:

```yaml

backend:

  image: saludos-backend:2.0

```

### Concepto

Cambiar código dentro de la imagen requiere reconstruirla.

Cambiar valores externos de configuración no requiere reconstruirla.

---

# 11. Revisar el Dockerfile de Database

El Dockerfile original es:

```dockerfile

FROM postgres:16

ENV POSTGRES_DB=saludos_db

ENV POSTGRES_USER=saludos_user

ENV POSTGRES_PASSWORD=saludos_password

COPY init.sql /docker-entrypoint-initdb.d/

```

Actualmente mezcla:

```text

Imagen

+

Configuración

+

Script de inicialización

```

Queremos externalizar la configuración.

---

# 12. Modificar `db/Dockerfile`

Eliminar:

```dockerfile

ENV POSTGRES_DB=saludos_db

ENV POSTGRES_USER=saludos_user

ENV POSTGRES_PASSWORD=saludos_password

```

Mantener:

```dockerfile

FROM postgres:16

COPY init.sql /docker-entrypoint-initdb.d/

```

Ahora:

```text

Dockerfile

   ↓

PostgreSQL + init.sql

```

La configuración será responsabilidad de Compose.

---

# 13. Reconstruir Database

```bash

docker build -t saludos-db:2.0 ./db

```

Actualizar:

```yaml

database:

  image: saludos-db:2.0

```

---

# 14. Configurar PostgreSQL mediante variables

Agregar:

```yaml

database:

  image: saludos-db:2.0

  environment:

    POSTGRES_DB: ${POSTGRES_DB}

    POSTGRES_USER: ${POSTGRES_USER}

    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

```

---

# 15. Configurar Backend mediante variables

Agregar:

```yaml

backend:

  image: saludos-backend:2.0

  environment:

    DB_HOST: ${DB_HOST}

    DB_PORT: ${DB_PORT}

    DB_NAME: ${POSTGRES_DB}

    DB_USER: ${POSTGRES_USER}

    DB_PASSWORD: ${POSTGRES_PASSWORD}

```

La cadena queda:

```text

.env

  ↓

Compose

  ↓

Container environment

  ↓

app.py

  ↓

PostgreSQL

```

---

# 16. Crear `.env.dev`

Crear:

```text

.env.dev

```

Con:

```env

POSTGRES_DB=saludos_db

POSTGRES_USER=saludos_user

POSTGRES_PASSWORD=saludos_dev_password

DB_HOST=database

DB_PORT=5432

BACKEND_HOST=backend

BACKEND_PORT=5000

FRONTEND_PORT=8080

APP_ENV=development

```

---

# 17. Crear `.env.prod`

Crear:

```text

.env.prod

```

Con:

```env

POSTGRES_DB=saludos_db

POSTGRES_USER=saludos_user

POSTGRES_PASSWORD=saludos_prod_password

DB_HOST=database

DB_PORT=5432

BACKEND_HOST=backend

BACKEND_PORT=5000

FRONTEND_PORT=80

APP_ENV=production

```

> Los valores de contraseña son únicamente para fines educativos. En ambientes reales se deben utilizar mecanismos apropiados de gestión de secretos.

---

# 18. Problema adicional: Nginx también tiene configuración hardcodeada

Abrir:

```text

frontend/nginx.conf

```

Actualmente:

```nginx

location /api/ {

    proxy_pass http://backend:5000/;

    proxy_set_header Host $host;

    proxy_set_header X-Real-IP $remote_addr;

    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

}

```

Tenemos:

```text

backend

5000

```

hardcodeados.

---

# 19. Convertir `nginx.conf` en plantilla

Renombrar:

```text

frontend/nginx.conf

```

a:

```text

frontend/nginx.conf.template

```

Cambiar:

```nginx

proxy_pass http://backend:5000/;

```

por:

```nginx

proxy_pass http://${BACKEND_HOST}:${BACKEND_PORT}/;

```

El archivo completo puede quedar:

```nginx

server {

    listen 80 default_server;

    listen [::]:80 default_server;

    root /usr/share/nginx/html;

    index index.html;

    location / {

        try_files $uri $uri/ =404;

    }

    location /api/ {

        proxy_pass http://${BACKEND_HOST}:${BACKEND_PORT}/;

        proxy_set_header Host $host;

        proxy_set_header X-Real-IP $remote_addr;

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    }

}

```

---

# 20. Actualizar el Dockerfile del Frontend

Modificar:

```text

frontend/Dockerfile

```

De:

```dockerfile

FROM nginx:alpine

COPY index.html /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

```

A:

```dockerfile

FROM nginx:alpine

COPY index.html /usr/share/nginx/html/

COPY nginx.conf.template /etc/nginx/templates/default.conf.template

EXPOSE 80

```

La imagen oficial de Nginx utiliza `/etc/nginx/templates/` para trabajar con plantillas al iniciar el contenedor.

---

# 21. Reconstruir Frontend

```bash

docker build -t saludos-frontend:2.0 ./frontend

```

Actualizar Compose:

```yaml

frontend:

  image: saludos-frontend:2.0

```

---

# 22. Inyectar variables en Nginx

Modificar:

```yaml

frontend:

  image: saludos-frontend:2.0

  ports:

    - "8080:80"

  environment:

    BACKEND_HOST: ${BACKEND_HOST}

    BACKEND_PORT: ${BACKEND_PORT}

```

La cadena queda:

```text

.env

   ↓

Compose

   ↓

Environment del container

   ↓

Nginx template

   ↓

Configuración final de Nginx

```

---

# 23. Verificar variables del Backend

```bash

docker compose --env-file .env.dev config

```

Destruir:

```bash

docker compose --env-file .env.dev down -v

```

Levantar:

```bash

docker compose --env-file .env.dev up -d

```

```bash

docker compose exec backend env | grep DB_

```

Esperamos:

```text

DB_HOST=database

DB_PORT=5432

DB_NAME=saludos_db

DB_USER=saludos_user

DB_PASSWORD=...

```

---

# 24. Verificar variables de Nginx





Verificar:

```bash

docker compose exec frontend env | grep BACKEND

```

Esperamos:

```text

BACKEND_HOST=backend

BACKEND_PORT=5000

```

---

# 25. Verificar configuración generada por Nginx

Entrar:

```bash

docker compose exec frontend sh

```

Consultar:

```bash

cat /etc/nginx/conf.d/default.conf

```

Debemos encontrar:

```nginx

proxy_pass http://backend:5000/;

```

La plantilla contiene:

```text

${BACKEND_HOST}

${BACKEND_PORT}

```

pero la configuración final contiene los valores reales.

Salir:

```bash

exit

```

---

# 26. Validar comunicación Frontend → Backend

Verificar:

```bash

docker compose ps

```

Probar:

```text

http://localhost:8080

```

Y:

```text

http://localhost:8080/api/saludo

```

Flujo:

```text

Browser

   ↓

localhost:8080

   ↓

Frontend / Nginx

   ↓

backend:5000

   ↓

Flask

   ↓

database:5432

   ↓

PostgreSQL

```

---

# 27. Seleccionar el ambiente

Desarrollo:

```bash

docker compose --env-file .env.dev up -d

```

Producción:

```bash

docker compose --env-file .env.prod up -d

```

Validar antes de levantar:

```bash

docker compose --env-file .env.dev config

```

```bash

docker compose --env-file .env.prod config

```

Modelo:

```text

                    compose.yml

                         |

              ┌──────────┴──────────┐

              ↓                     ↓

          .env.dev              .env.prod

              ↓                     ↓

        DEVELOPMENT           PRODUCTION

```

---

# 28. Comparar configuraciones

Ejecutar:

```bash

docker compose --env-file .env.dev config

```

Observar:

```text

FRONTEND_PORT=8080

APP_ENV=development

```

Después:

```bash

docker compose --env-file .env.prod config

```

Observar:

```text

FRONTEND_PORT=80

APP_ENV=production

```

### Preguntas

- ¿Qué valores cambian?

- ¿Qué valores permanecen iguales?

- ¿Por qué no necesitamos modificar `app.py` para cambiar de ambiente?

- ¿Por qué no necesitamos modificar `nginx.conf.template`?

---

# 29. `.env` no es un mecanismo de secretos

`.env` permite separar configuración del código, pero no debe confundirse con un sistema de gestión de secretos.

Para este laboratorio utilizamos `.env` para demostrar configuración por ambiente.

En un entorno real, las credenciales sensibles deben administrarse mediante una solución apropiada de secretos.

---

# 30. Persistencia de PostgreSQL

Declarar:

```yaml

volumes:

  postgres_data:

```

Agregar al servicio:

```yaml

database:

  image: saludos-db:2.0

  environment:

    POSTGRES_DB: ${POSTGRES_DB}

    POSTGRES_USER: ${POSTGRES_USER}

    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

  volumes:

    - postgres_data:/var/lib/postgresql/data

```

Verificar:

```bash

docker volume ls

```

Concepto:

```text

Container lifecycle

        ≠

Data lifecycle

```

---

# 31. Named Volume vs Bind Mount

## Named Volume

Para datos PostgreSQL:

```yaml

- postgres_data:/var/lib/postgresql/data

```

## Bind Mount

Para compartir archivos del repositorio:

```yaml

- ./frontend/index.html:/usr/share/nginx/html/index.html:ro

```

Diferencia:

```text

Named Volume

     ↓

Datos persistentes

     ↓

Administrados por Docker

```

```text

Bind Mount

     ↓

Archivos del repositorio

     ↓

Compartidos entre host y container

```

---

# 32. Compartir contenido del Frontend

Agregar:

```yaml

frontend:

  image: saludos-frontend:2.0

  ports:

    - "${FRONTEND_PORT}:80"

  environment:

    BACKEND_HOST: ${BACKEND_HOST}

    BACKEND_PORT: ${BACKEND_PORT}

  volumes:

    - ./frontend/index.html:/usr/share/nginx/html/index.html:ro

```

---

# 33. Compartir la plantilla de Nginx

También podemos montar:

```yaml

- ./frontend/nginx.conf.template:/etc/nginx/templates/default.conf.template:ro

```

El servicio queda:

```yaml

frontend:

  image: saludos-frontend:2.0

  ports:

    - "${FRONTEND_PORT}:80"

  environment:

    BACKEND_HOST: ${BACKEND_HOST}

    BACKEND_PORT: ${BACKEND_PORT}

  volumes:

    - ./frontend/index.html:/usr/share/nginx/html/index.html:ro

    - ./frontend/nginx.conf.template:/etc/nginx/templates/default.conf.template:ro

```

---

# 34. Database: `init.sql` ya está dentro de la imagen

No necesitamos montar `init.sql` como bind mount porque el Dockerfile de Database ya realiza:

```dockerfile

COPY init.sql /docker-entrypoint-initdb.d/

```

El flujo es:

```text

db/init.sql

       ↓

docker build

       ↓

saludos-db:2.0

       ↓

/docker-entrypoint-initdb.d/init.sql

```

El servicio solamente necesita el named volume:

```yaml

database:

  image: saludos-db:2.0

  environment:

    POSTGRES_DB: ${POSTGRES_DB}

    POSTGRES_USER: ${POSTGRES_USER}

    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

  volumes:

    - postgres_data:/var/lib/postgresql/data

```

No debemos hacer:

```yaml

- ./db:/var/lib/postgresql/data

```

ni:

```yaml

- ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro

```

porque `init.sql` ya está dentro de la imagen.

Tenemos dos responsabilidades:

```text

init.sql

   ↓

Inicialización

postgres_data

   ↓

Datos persistentes

```

---

# 35. Backend y Bind Mount

Antes de montar la carpeta completa del backend debemos inspeccionar la imagen:

```bash

docker image inspect saludos-backend:2.0

```

Buscar:

```text

WorkingDir

Entrypoint

Cmd

```

No asumir que el código está en:

```text

/app

```

si la imagen no lo especifica.

Primero inspeccionamos y después decidimos si necesitamos un bind mount.

---

# 36. Probar persistencia

Entrar a PostgreSQL:

```bash

docker compose exec database psql -U saludos_user -d saludos_db

```

Consultar:

```sql

dt

```

Salir:

```sql

q

```

Eliminar los recursos de ejecución:

```bash

docker compose down

```

Volver a levantar:

```bash

docker compose up -d

```

Consultar nuevamente los datos.

Resultado esperado:

```text

Container eliminado

        ↓

       Sí

Container recreado

        ↓

       Sí

Volume eliminado

        ↓

       No

Datos

        ↓

   Permanecen

```

---

# 37. `docker compose down` vs `down -v`

Comparar:

```bash

docker compose down

```

con:

```bash

docker compose down -v

```

`down` elimina los recursos de ejecución.

`down -v` también elimina los volúmenes asociados.

### Advertencia

No ejecutar:

```bash

docker compose down -v

```

si necesitamos conservar los datos.

---

# 38. Healthcheck de PostgreSQL

El `healthcheck` debe agregarse **dentro del servicio `database`** en `compose.yml`.

El servicio queda así:

```yaml
database:
  image: saludos-db:2.0

  environment:
    POSTGRES_DB: ${POSTGRES_DB}
    POSTGRES_USER: ${POSTGRES_USER}
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

  volumes:
    - postgres_data:/var/lib/postgresql/data

  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
    interval: 5s
    timeout: 5s
    retries: 5
    start_period: 10s
```

Aplicar:

```bash
docker compose --env-file .env.dev up -d
```

Verificar:

```bash
docker compose --env-file .env.dev ps
```

PostgreSQL debe llegar a:

```text
healthy
```

También podemos validar directamente el estado del healthcheck:

```bash
docker inspect --format='{{.State.Health.Status}}' $(docker compose --env-file .env.dev ps -q database)
```

Resultado esperado:

```text
healthy
```

Un contenedor `running` no necesariamente significa que el servicio esté `ready`.

---

# 39. Dependencia entre Backend y Database

Agregar:

```yaml

backend:

  image: saludos-backend:2.0

  environment:

    DB_HOST: ${DB_HOST}

    DB_PORT: ${DB_PORT}

    DB_NAME: ${POSTGRES_DB}

    DB_USER: ${POSTGRES_USER}

    DB_PASSWORD: ${POSTGRES_PASSWORD}

  depends_on:

    database:

      condition: service_healthy

```

Modelo:

```text

Database starts

      ↓

Healthcheck

      ↓

Database healthy

      ↓

Backend starts

```

---

# 40. Troubleshooting controlado

En `.env.dev` cambiar:

```env

DB_HOST=database

```

por:

```env

DB_HOST=database-error

```

Levantar:

```bash

docker compose --env-file .env.dev up -d

```

No corregir inmediatamente.

Primero diagnosticar.

---

# 41. Diagnóstico — Estado

```bash

docker compose ps

```

Pregunta:

```text

¿Qué servicio presenta el problema?

```

---

# 42. Diagnóstico — Logs

```bash

docker compose logs backend

```

O:

```bash

docker compose logs -f backend

```

Pregunta:

```text

¿Qué está reportando la aplicación?

```

---

# 43. Diagnóstico — Variables

```bash

docker compose exec backend env | grep DB_

```

Esperamos encontrar:

```text

DB_HOST=database-error

```

Tenemos evidencia de que la configuración incorrecta llegó al contenedor.

---

# 44. Diagnóstico — DNS

Probar:

```bash

docker compose exec backend getent hosts database

```

Y:

```bash

docker compose exec backend getent hosts database-error

```

Esperamos:

```text

database

   ↓

Resuelve

database-error

   ↓

No resuelve

```

---

# 45. Corregir el problema

Volver a:

```env

DB_HOST=database

```

Aplicar:

```bash

docker compose --env-file .env.dev up -d

```

Verificar:

```bash

docker compose ps

docker compose logs backend

```

Finalmente:

```text

http://localhost:8080

```

---

# 46. Metodología de Troubleshooting

```text

Síntoma

   ↓

Hipótesis

   ↓

Evidencia

   ↓

Corrección

   ↓

Verificación

```

No trabajar así:

```text

Error

   ↓

Cambiar cosas al azar

   ↓

Reiniciar todo

   ↓

Esperar que funcione

```

---

# 47. Inspección de recursos

## Contenedores

```bash

docker ps

```

## Inspección

```bash

docker inspect <CONTAINER_ID>

```

## Redes

```bash

docker network ls

```

```bash

docker network inspect <NETWORK_NAME>

```

## Volúmenes

```bash

docker volume ls

```

```bash

docker volume inspect <VOLUME_NAME>

```

### Pregunta

¿Por qué seguimos utilizando comandos `docker` si estamos utilizando Compose?

### Respuesta esperada

Porque Compose define y administra la aplicación, mientras que los recursos finales continúan siendo recursos Docker.

---

# 48. Validación final

Arquitectura:

```text

                         HOST

                           |

                    localhost:8080

                           |

                           ↓

                      FRONTEND

                        Nginx

                           |

                     Docker Network

                           |

                           ↓

                       BACKEND

                        Flask

                           |

                     Docker Network

                           |

                           ↓

                       DATABASE

                      PostgreSQL

                           |

                           ↓

                     postgres_data

                           |

                           ↓

                    Persistent Data

```

Validar:

```bash

docker compose ps

docker compose config

docker volume ls

docker network ls

```

Probar:

```text

http://localhost:8080

```

Y:

```text

http://localhost:8080/api/saludo

```

---

# 49. Reto 1 — Ambientes

Levantar:

```bash

docker compose --env-file .env.dev up -d

```

Validar producción:

```bash

docker compose --env-file .env.prod config

```

Identificar:

- ¿Qué valores cambian?

- ¿Qué valores permanecen iguales?

- ¿Qué parte del código no fue necesario modificar?

---

# 50. Reto 2 — Persistencia

Demostrar:

```text

Crear dato

   ↓

docker compose down

   ↓

docker compose up -d

   ↓

Consultar dato

   ↓

El dato permanece

```

Explicar por qué el dato sobrevivió.

---

# 51. Reto 3 — Troubleshooting

Provocar un error de configuración.

Documentar:

```text

Síntoma

   ↓

Hipótesis

   ↓

Evidencia

   ↓

Corrección

   ↓

Verificación

```

Utilizar como mínimo:

```bash

docker compose ps

docker compose logs

docker compose exec

docker inspect

```

---

# 52. Reto 4 — Cambio sin reconstruir

Modificar:

```text

frontend/index.html

```

y verificar el cambio desde el navegador.

No ejecutar:

```bash

docker build

```

La modificación debe aprovechar el bind mount.

### Pregunta

¿Por qué este cambio no requiere reconstruir la imagen?

---

# 53. Reto 5 — Configuración sin reconstruir

Cambiar un valor de:

```text

.env.dev

```

sin modificar:

```text

app.py

nginx.conf.template

```

Validar:

```bash

docker compose --env-file .env.dev config

```

Y volver a levantar:

```bash

docker compose --env-file .env.dev up -d

```

### Objetivo

Demostrar la diferencia entre:

```text

Código de la aplicación

```

y:

```text

Configuración del ambiente

```

---

# 54. Checklist final

- [ ] Se reutilizaron las imágenes existentes como punto de partida.

- [ ] Se definieron los tres servicios en `compose.yml`.

- [ ] Compose administra la red.

- [ ] Frontend tiene el puerto publicado.

- [ ] Backend y Database no necesitan publicar sus puertos al host.

- [ ] Backend utiliza `DB_HOST` mediante variable de entorno.

- [ ] Backend utiliza `DB_PORT` mediante variable de entorno.

- [ ] Backend utiliza `DB_NAME` mediante variable de entorno.

- [ ] Backend utiliza `DB_USER` mediante variable de entorno.

- [ ] Backend utiliza `DB_PASSWORD` mediante variable de entorno.

- [ ] Nginx utiliza `BACKEND_HOST`.

- [ ] Nginx utiliza `BACKEND_PORT`.

- [ ] Se creó `nginx.conf.template`.

- [ ] Se actualizó el Dockerfile del frontend.

- [ ] Se construyó `saludos-frontend:2.0`.

- [ ] Se construyó `saludos-backend:2.0`.

- [ ] Se actualizó el Dockerfile de Database para externalizar su configuración.

- [ ] Se construyó `saludos-db:2.0`.

- [ ] `init.sql` permanece dentro de la imagen de Database.

- [ ] Existen `.env.dev` y `.env.prod`.

- [ ] Se puede seleccionar el ambiente mediante `--env-file`.

- [ ] Se diferenció configuración de secretos.

- [ ] PostgreSQL utiliza un named volume.

- [ ] Se diferenciaron named volumes y bind mounts.

- [ ] Se compartieron archivos seleccionados del repositorio.

- [ ] Los datos sobreviven a `docker compose down`.

- [ ] PostgreSQL tiene healthcheck.

- [ ] Backend depende de Database saludable.

- [ ] Se realizó troubleshooting.

- [ ] Se utilizaron `ps`, `logs`, `exec` e `inspect`.

- [ ] La aplicación funciona desde el navegador.

---

# 55. Resultado esperado

Al finalizar, la aplicación que en Docker Básico requería administrar varios contenedores individualmente podrá ser definida como una aplicación multicontenedor mediante Docker Compose.



```text

Dockerfile

    ↓

Cómo se construye una imagen

Image

    ↓

Artefacto de la aplicación

Container

    ↓

Instancia ejecutable

Compose

    ↓

Definición y administración

de la aplicación multicontenedor

Network

    ↓

Comunicación entre servicios

Service Discovery

    ↓

Comunicación mediante nombres

Environment Variables

    ↓

Configuración externa

.env.dev / .env.prod

    ↓

Configuración por ambiente

Bind Mount

    ↓

Compartir archivos del host

Named Volume

    ↓

Persistencia administrada por Docker

Healthcheck

    ↓

Verificación de disponibilidad

depends_on

    ↓

Dependencias entre servicios

Logs / exec / inspect

    ↓

Diagnóstico

```

La meta no es memorizar un `compose.yml` terminado.

La meta es aprender a construirlo a partir de las necesidades reales de una aplicación.

---

## 56. CI/CD — ¿Qué sigue después de Docker Compose?

Durante esta clase transformamos una aplicación compuesta por contenedores individuales en una aplicación **reproducible y gestionable con Docker Compose**.

Ahora podemos definir en código:

- Los servicios de la aplicación.
- La comunicación entre contenedores.
- Las variables de configuración.
- La persistencia de los datos.
- Las condiciones de salud de los servicios.
- La forma de levantar y validar toda la aplicación.

Pero queda una pregunta:

> **Si un desarrollador modifica `app.py`, hace `git push` y necesitamos llevar ese cambio a otro ambiente, ¿tendríamos que ejecutar todos estos pasos manualmente?**

### De un proceso manual a un proceso automatizado

Hasta ahora el flujo ha sido principalmente manual:

```text
Modificar código
      ↓
Construir imagen
      ↓
Validar
      ↓
Levantar aplicación
      ↓
Verificar
```

En un entorno profesional queremos que parte de este proceso pueda ejecutarse automáticamente cada vez que se produce un cambio en el código.

```text
Código
   ↓
Git Push
   ↓
Validaciones automáticas
   ↓
Build de la imagen
   ↓
Pruebas
   ↓
Entrega / despliegue
```

Aquí aparece **CI/CD** como el siguiente paso natural del proceso.

### ¿Qué relación tiene con lo aprendido?

```text
Dockerfile
    ↓
Construye la imagen

Docker Compose
    ↓
Define y ejecuta la aplicación

CI/CD
    ↓
Automatiza el proceso de validar,
construir y entregar los cambios
```

La idea no es estudiar CI/CD en esta clase, sino identificar el problema que resuelve:

> **¿Cómo hacemos para que el proceso que acabamos de ejecutar manualmente pueda repetirse de forma automática, confiable y trazable?**

### Pregunta de cierre

**Si mañana hacemos un cambio en `app.py`, ¿qué pasos de este laboratorio podríamos automatizar para que el cambio llegue de forma segura al siguiente ambiente?**

> **La siguiente clase: CI/CD.**


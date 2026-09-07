# Laboratorio: Docker básico

## Objetivo

En este laboratorio construiremos la misma arquitectura de tres capas implementada anteriormente con Vagrant, pero utilizando **contenedores Docker**.

La aplicación estará compuesta por:

- Un **Frontend** con Nginx.
- Un **Backend** desarrollado con Python y Flask.
- Una **Base de datos PostgreSQL**.

El objetivo no es únicamente crear contenedores. Durante el laboratorio analizaremos cómo una aplicación puede empaquetarse mediante imágenes, ejecutarse mediante contenedores y comunicarse utilizando redes de Docker.

También compararemos continuamente las decisiones tomadas durante el laboratorio de virtualización con su equivalente utilizando contenedores.

Al finalizar tendremos una arquitectura como esta:

```text
                         Usuario
                            │
                            │ HTTP
                            ▼
                ┌───────────────────────┐
                │  FRONTEND Container   │
                │         :80           │
                │                       │
                │     Nginx + HTML      │
                └───────────┬───────────┘
                            │
                            │ backend:5000
                            ▼
                ┌───────────────────────┐
                │   BACKEND Container   │
                │         :5000         │
                │                       │
                │    Python + Flask     │
                └───────────┬───────────┘
                            │
                            │ database:5432
                            ▼
                ┌───────────────────────┐
                │  DATABASE Container   │
                │         :5432         │
                │                       │
                │      PostgreSQL       │
                └───────────────────────┘

                     saludos-network
```

---

# Arquitectura de la aplicación

La aplicación mantiene el mismo comportamiento utilizado durante el laboratorio de virtualización.

El usuario presiona un botón para solicitar un saludo aleatorio.

```text
Usuario
   │
   │ Presiona botón
   ▼
Frontend
   │
   │ HTTP
   ▼
Backend
   │
   │ SQL
   ▼
Base de datos
   │
   │ Saludo aleatorio
   ▼
Backend
   │
   │ JSON
   ▼
Frontend
   │
   ▼
Usuario
```

La arquitectura funcional no cambiará.

Lo que cambiará será **la forma en que empaquetamos, ejecutamos y comunicamos cada componente**.

---

# Componentes del laboratorio

| Componente | Tecnología | Carpeta |
| --- | --- | --- |
| Frontend | HTML + JavaScript + Nginx | `frontend` |
| Backend | Python + Flask | `backend` |
| Base de datos | PostgreSQL | `db` |
| Infraestructura | Docker | Host |

---

# Requisitos

Antes de iniciar verificar que se encuentran instalados:

- Docker
- Git

Verificar la versión:

```bash
docker --version
```

Verificar que Docker se encuentre funcionando:

```bash
docker ps
```

Si Docker requiere permisos de `sudo`, agregar el usuario actual al grupo Docker:

```bash
sudo usermod -aG docker $USER
```

Cerrar y volver a iniciar la sesión para aplicar el cambio.

---

# Estructura del proyecto

```text
docker-basico/
│
├── db/
│   ├── Dockerfile
│   └── init.sql
│
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── index.html
│
└── backend/
    ├── Dockerfile
    ├── requirements.txt
    └── app.py
```

---

# Paso 1: Clonar el repositorio

Clonar el repositorio:

```bash
git clone <URL_DEL_REPOSITORIO>
```

Ingresar al directorio:

```bash
cd virtualizacion-contenerizacion/docker-basico
```

---

# Paso 2: Analizar las dependencias de la aplicación

Antes de construir las imágenes, revisar los archivos utilizados durante el laboratorio anterior:

```text
virtualizacion/scripts/
```

Identificar qué necesitaba cada máquina para ejecutar su componente.

## Backend

Durante el laboratorio de virtualización fue necesario:

```text
Ubuntu
   ↓
Python
   ↓
Dependencias de requirements.txt
   ↓
app.py
   ↓
python app.py
```

## Frontend

```text
Ubuntu
   ↓
Nginx
   ↓
index.html
   ↓
Configuración nginx
```

## Database

```text
Ubuntu
   ↓
PostgreSQL
   ↓
Base de datos
   ↓
Usuario
   ↓
Tabla + información inicial
```

Ahora tendremos que representar estas dependencias mediante **imágenes**.

---

# Paso 3: Construir los Dockerfiles

Ingresar a cada carpeta, teniendo en cuenta las dependencias de cada servicio y traduciendo los comandos de la configuración de cada una.

---

# Paso 4: Adaptar el Backend al entorno de contenedores

Durante el laboratorio de virtualización, el backend conocía la dirección IP de PostgreSQL:

```text
192.168.56.13
```

Dentro de una red Docker evitaremos depender directamente de la dirección IP del contenedor.

En `app.py`, cambiar:

```python
host="192.168.56.13"
```

por:

```python
host="database"
```

Más adelante veremos cómo Docker permite resolver este nombre dentro de una red.

---

# Paso 5: Adaptar Nginx al entorno de contenedores

Durante el laboratorio de virtualización, Nginx enviaba las solicitudes hacia:

```nginx
proxy_pass http://192.168.56.12:5000/;
```

Ahora el backend será un contenedor dentro de una red Docker.

Cambiar por:

```nginx
proxy_pass http://backend:5000/;
```

La configuración deberá contener:

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

        proxy_pass http://backend:5000/;

        proxy_set_header Host $host;

        proxy_set_header X-Real-IP $remote_addr;

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    }

}
```

Observar dos cambios respecto a la VM:

```text
VIRTUALIZACIÓN                  CONTENEDORES

/var/www/html            →      /usr/share/nginx/html

192.168.56.12:5000       →      backend:5000
```

---

# Paso 6: Crear las imágenes

Desde `docker-basico` construir las tres imágenes.

## Backend

```bash
docker build -t saludos-backend:1.0 ./backend
```

## Frontend

```bash
docker build -t saludos-frontend:1.0 ./frontend
```

## Database

```bash
docker build -t saludos-db:1.0 ./db
```

---

# Paso 7: Verificar las imágenes

Ejecutar:

```bash
docker image ls
```

Deberán aparecer:

```text
saludos-frontend   1.0
saludos-backend    1.0
saludos-db         1.0
```

Inspeccionar alguna de las imágenes:

```bash
docker inspect saludos-backend:1.0
```

Revisar sus capas:

```bash
docker history saludos-backend:1.0
```

Analizar:

- ¿Qué instrucciones del Dockerfile generaron capas?
- ¿Cuánto ocupa la imagen?
- ¿Qué imagen base utiliza?
- ¿Qué ocurre si volvemos a ejecutar `docker build` sin realizar cambios?

---

# Paso 8: Crear los contenedores

Antes de crear los contenedores, intentar responder:

> ¿Podemos simplemente crear los tres contenedores y esperar que se encuentren entre ellos?

Primero necesitaremos proporcionar un mecanismo de comunicación.

---

# Paso 9: Crear una red Docker

Crear una red:

```bash
docker network create saludos-network
```

Verificar:

```bash
docker network ls
```

Inspeccionar:

```bash
docker network inspect saludos-network
```

Esta red permitirá que nuestros contenedores se comuniquen utilizando nombres en lugar de depender directamente de direcciones IP.

---

# Paso 10: Crear el contenedor de PostgreSQL

Ejecutar:

```bash
docker run -d --name database --network saludos-network -e POSTGRES_DB=saludos_db -e POSTGRES_USER=saludos_user -e POSTGRES_PASSWORD=saludos_password saludos-db:1.0
```

Verificar:

```bash
docker ps
```

Revisar los logs:

```bash
docker logs database
```

Ingresar a PostgreSQL:

```bash
docker exec -it database psql -U saludos_user -d saludos_db
```

Consultar:

```sql
SELECT * FROM saludos;
```

Salir:

```text
\q
```

---

# Paso 13: Crear el contenedor Backend

Ejecutar:

```bash
docker run -d --name backend --network saludos-network saludos-backend:1.0
```

Verificar:

```bash
docker ps
```

Consultar sus logs:

```bash
docker logs backend
```

Probar el endpoint desde dentro del contenedor:

```bash
docker exec backend python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:5000/health').read().decode())"
```

Resultado esperado:

```json
{"status":"OK"}
```

---

# Paso 14: Crear el contenedor Frontend

Ejecutar:

```bash
docker run -d --name frontend --network saludos-network -p 8080:80 saludos-frontend:1.0
```

Verificar:

```bash
docker ps
```

Observar la columna `PORTS`.

Analizar:

```text
8080:80
 │   │
 │   └── Puerto dentro del contenedor
 │
 └────── Puerto publicado en el host Docker
```

---

# Paso 15: Validar la red

Inspeccionar nuevamente:

```bash
docker network inspect saludos-network
```

Identificar:

- `frontend`
- `backend`
- `database`

Observar las direcciones IP asignadas.

Ahora comprobar desde el frontend que el nombre `backend` puede resolverse:

```bash
docker exec frontend getent hosts backend
```

Y desde el backend:

```bash
docker exec backend getent hosts database
```

Analizar:

> Si Docker asignó direcciones IP a los contenedores, ¿por qué configuramos nuestra aplicación utilizando `backend` y `database` en lugar de esas direcciones?

---

# Paso 16: Probar la aplicación

Si Docker se encuentra ejecutándose directamente en la máquina local, abrir:

```text
http://localhost:8080
```

Si Docker está ejecutándose dentro de una máquina virtual, utilizar la dirección IP de esa máquina:

```text
http://<IP_DE_LA_VM>:8080
```

Debe aparecer la aplicación.

Presionar:

```text
Obtener saludo
```

Cada vez que se presiona el botón, la aplicación debe obtener un saludo aleatorio almacenado en PostgreSQL.

---

# Paso 17: Analizar el flujo de la aplicación

Al presionar el botón ocurre:

```text
1. Usuario presiona el botón
        ↓
2. Navegador solicita /api/saludo
        ↓
3. Nginx recibe la solicitud
        ↓
4. Nginx resuelve "backend"
        ↓
5. Nginx envía la solicitud a backend:5000
        ↓
6. Flask recibe la solicitud
        ↓
7. Backend resuelve "database"
        ↓
8. Backend se conecta a database:5432
        ↓
9. PostgreSQL selecciona un saludo
        ↓
10. Backend devuelve JSON
        ↓
11. Frontend muestra el saludo
```

---

# Paso 18: Explorar los contenedores

Listar contenedores:

```bash
docker ps
```

Ingresar al backend:

```bash
docker exec -it backend sh
```

Observar procesos:

```bash
ps
```

Salir:

```bash
exit
```

Revisar información detallada:

```bash
docker inspect backend
```

Revisar consumo de recursos:

```bash
docker stats
```

---

# Paso 19: Pruebas de fallos

## Fallo de Base de Datos

Detener:

```bash
docker stop database
```

Volver a solicitar un saludo.

Revisar:

```bash
docker logs backend
```

Iniciar nuevamente:

```bash
docker start database
```

## Fallo del Backend

Detener:

```bash
docker stop backend
```

Volver a probar la aplicación.

Revisar:

```bash
docker logs frontend
```

Iniciar nuevamente:

```bash
docker start backend
```

## Fallo del Frontend

Detener:

```bash
docker stop frontend
```

Intentar acceder nuevamente a la aplicación.

Iniciar:

```bash
docker start frontend
```

---

# Paso 20: ¿Qué ocurre con los cambios dentro de un contenedor?

Ingresar al backend:

```bash
docker exec -it backend sh
```

Crear un archivo:

```bash
echo "creado dentro del contenedor" > /tmp/prueba.txt
```

Comprobar:

```bash
cat /tmp/prueba.txt
```

Salir:

```bash
exit
```

Eliminar el contenedor:

```bash
docker rm -f backend
```

Crearlo nuevamente:

```bash
docker run -d --name backend --network saludos-network saludos-backend:1.0
```

Buscar:

```bash
docker exec backend cat /tmp/prueba.txt
```

Analizar:

> ¿Por qué desapareció el archivo?

> ¿Modificamos la imagen original cuando creamos el archivo?

Relacionar el resultado con:

```text
Imagen
│
├── Layers READ ONLY
│
└── utilizada para crear
        ↓
    Contenedor
        │
        └── Writable Layer
```
---

# Comparación con el laboratorio de virtualización

| Virtualización | Docker |
| --- | --- |
| Vagrantfile | Dockerfile |
| Box / SO base | Imagen base |
| Máquina Virtual | Contenedor |
| `vagrant up` | `docker run` |
| `vagrant status` | `docker ps` |
| `vagrant ssh` | `docker exec` |
| `vagrant halt` | `docker stop` |
| `vagrant destroy` | `docker rm` |
| IP privada | Docker Network + DNS |
| Instalar dependencias en VM | Construirlas dentro de la imagen |
| Disco de la VM | Writable layer / Volume |
| Servicio systemd | Proceso principal del contenedor |

---
# Preguntas para discusión

Al finalizar el laboratorio discutir en grupo:

1. ¿Qué diferencias existen entre el ambiente virtualizado y el ambiente contenerizado?
2. ¿Qué problemas resolvió Docker durante el laboratorio?
3. ¿Qué diferencia existe entre una imagen y un contenedor?
4. ¿Por qué los contenedores se comunican mediante nombres y no mediante IPs configuradas manualmente?
5. ¿Qué ocurre con los cambios realizados dentro de la writable layer cuando eliminamos un contenedor?
6. ¿Cómo podríamos persistir los datos de PostgreSQL?
7. ¿Cómo compartiríamos nuestras imágenes con otro desarrollador?
8. ¿Qué etapas del ciclo DevOps estamos cubriendo con esta práctica?

---

# Conclusión

Durante este laboratorio implementamos la misma aplicación distribuida construida anteriormente con máquinas virtuales, utilizando ahora **tres contenedores independientes**:

```text
Frontend Container
       │
       ▼
Backend Container
       │
       ▼
Database Container
```

Cada componente fue empaquetado mediante una imagen y ejecutado posteriormente como un contenedor.

Las imágenes permitieron definir las dependencias necesarias para ejecutar cada componente:

```text
Dockerfile
    ↓
docker build
    ↓
Imagen
    ↓
docker run
    ↓
Contenedor
```

También creamos una red Docker que permitió que los componentes se comunicaran utilizando nombres:

```text
frontend
   │
   │ backend:5000
   ▼
backend
   │
   │ database:5432
   ▼
database
```

A diferencia del laboratorio de virtualización, no fue necesario crear un sistema operativo completo para cada componente ni configurar manualmente direcciones IP privadas entre ellos.

Sin embargo, todavía estamos administrando manualmente:

- Tres imágenes.
- Tres contenedores.
- Una red.
- Variables de configuración.
- Puertos.
- Persistencia.

> Si nuestra aplicación necesita varios contenedores, redes, volúmenes y configuraciones, ¿cómo podríamos describir toda la aplicación como código y levantarla de manera reproducible mediante una sola definición?
````
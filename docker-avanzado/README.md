# Laboratorio — Docker Avanzado

## De contenedores individuales a una aplicación reproducible con Docker Compose

En la sesión anterior construimos y ejecutamos una aplicación compuesta por tres contenedores:

```text
Frontend
   ↓
Backend
   ↓
PostgreSQL
```

En esta sesión **no vamos a reconstruir la aplicación**. Vamos a reutilizar las imágenes:

```text
saludos-frontend:1.0
saludos-backend:1.0
saludos-db:1.0
```

El objetivo es evolucionar la administración manual de estos contenedores hacia una aplicación definida y administrada mediante Docker Compose.

> **Docker Básico:** construir y ejecutar contenedores.  
> **Docker Avanzado:** componer, configurar, persistir, verificar y diagnosticar una aplicación multicontenedor.

---

# 1. Prerrequisitos

Verificar Docker y Compose:

```bash
docker version
docker compose version
```

Verificar las imágenes de la sesión anterior:

```bash
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

La aplicación anterior está organizada como:

```text
docker-basico/
├── backend/
├── frontend/
└── db/
```

| Componente | Imagen | Responsabilidad |
|---|---|---|
| Frontend | `saludos-frontend:1.0` | Interfaz web / Nginx |
| Backend | `saludos-backend:1.0` | API Flask |
| Database | `saludos-db:1.0` | PostgreSQL |

Antes los administrábamos individualmente. Ahora vamos a construir una definición única:

```text
docker-avanzado/
├── compose.yml
├── .env.dev
├── .env.prod
└── README.md
```

---

# 3. Reconocer el estado actual

```bash
docker ps -a
docker network ls
docker volume ls
```

Identifica qué elementos necesitábamos configurar manualmente en Docker Básico:

- imágenes;
- nombres;
- puertos;
- red;
- variables;
- almacenamiento;
- dependencias.

**Pregunta:** ¿cuáles de estos elementos deberían formar parte de la definición de la aplicación?

---

# 4. Crear el Compose desde cero

El archivo `compose.yml` se encuentra intencionalmente vacío.

Durante el laboratorio lo construiremos progresivamente.

No se entrega una solución final para copiar.

La metodología será:

```text
Concepto
   ↓
Agregar configuración
   ↓
Validar
   ↓
Ejecutar
   ↓
Observar
```

---

# 5. Primera pieza: servicios

Comenzar:

```yaml
services:
```

Agregar los tres servicios:

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

**Pregunta:** ¿qué información del laboratorio anterior todavía no está representada?

---

# 6. Frontend: publicar el servicio

El frontend necesita ser accesible desde el host.

Agregar:

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

Verificar:

```text
http://localhost:8080
```

`ports` publica un puerto del contenedor hacia el host. No significa que todos los servicios deban publicar sus puertos.

---

# 7. Networking administrado por Compose

Compose crea y administra una red para los servicios del proyecto.

Verificar:

```bash
docker network ls
```

Inspeccionar la red:

```bash
docker network inspect <NOMBRE_DE_LA_RED>
```

La arquitectura:

```text
Frontend
   |
   | Docker Network
   v
Backend
   |
   | Docker Network
   v
Database
```

El objetivo es dejar de depender de la creación manual de `saludos-network`.

---

# 8. Service Discovery

El backend debe encontrar PostgreSQL utilizando el nombre lógico del servicio:

```text
database
```

Por tanto:

```text
DB_HOST=database
```

Verificar desde el backend:

```bash
docker compose exec backend getent hosts database
```

Si la imagen no dispone de `getent`, utilizar una herramienta equivalente disponible dentro del contenedor.

La aplicación conoce el nombre del servicio y Docker resuelve su dirección interna.

---

# 9. Environment Variables

Mover la configuración del backend y PostgreSQL a variables:

```yaml
database:
  image: saludos-db:1.0
  environment:
    POSTGRES_DB: ${POSTGRES_DB}
    POSTGRES_USER: ${POSTGRES_USER}
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

backend:
  image: saludos-backend:1.0
  environment:
    DB_HOST: ${DB_HOST}
    DB_PORT: ${DB_PORT}
    DB_NAME: ${POSTGRES_DB}
    DB_USER: ${POSTGRES_USER}
    DB_PASSWORD: ${POSTGRES_PASSWORD}
```

Ajustar nombres si la aplicación utiliza otros nombres.

Validar:

```bash
docker compose config
```

Comprobar:

```bash
docker compose exec backend env | grep DB_
```

---

# 10. Configuración por ambiente

Una misma imagen puede ejecutarse con configuraciones diferentes.

Crearemos:

```text
.env.dev
.env.prod
```

## `.env.dev`

```env
POSTGRES_DB=saludos_db
POSTGRES_USER=saludos_user
POSTGRES_PASSWORD=saludos_dev_password

DB_HOST=database
DB_PORT=5432

FRONTEND_PORT=8080
APP_ENV=development
```

## `.env.prod`

```env
POSTGRES_DB=saludos_db
POSTGRES_USER=saludos_user
POSTGRES_PASSWORD=saludos_prod_password

DB_HOST=database
DB_PORT=5432

FRONTEND_PORT=80
APP_ENV=production
```

> Los valores son solamente para laboratorio. En un ambiente real, las credenciales sensibles deben gestionarse mediante una solución de secretos.

---

# 11. Seleccionar el ambiente

Para desarrollo:

```bash
docker compose --env-file .env.dev up -d
```

Para producción:

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
          ↓                     ↓
      .env.dev              .env.prod
          ↓                     ↓
   DEVELOPMENT             PRODUCTION
```

El Compose describe la aplicación. El archivo de ambiente aporta valores específicos del entorno.

`.env` no debe confundirse con un mecanismo de secret management.

---

# 12. Docker Volume: persistencia

Los datos de PostgreSQL no deben depender del ciclo de vida del contenedor.

Declarar:

```yaml
volumes:
  postgres_data:
```

Montar:

```yaml
database:
  image: saludos-db:1.0
  volumes:
    - postgres_data:/var/lib/postgresql/data
```

Verificar:

```bash
docker volume ls
```

Modelo:

```text
Database Container
       |
       | mount
       v
postgres_data
       |
       v
Persistent Data
```

---

# 13. Named Volume vs Bind Mount

En este laboratorio diferenciaremos dos mecanismos.

### Named Volume

Para los datos de PostgreSQL:

```yaml
- postgres_data:/var/lib/postgresql/data
```

Docker administra el almacenamiento.

### Bind Mount

Para compartir archivos del repositorio:

```yaml
- ./frontend/index.html:/usr/share/nginx/html/index.html:ro
```

El bind mount conecta una ruta del host con una ruta del contenedor.

---

# 14. Compartir contenido del repositorio

La estructura del repositorio anterior es:

```text
docker-basico/
│
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   └── nginx.conf
│
├── backend/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
│
└── db/
    ├── Dockerfile
    └── init.sql
```

## Frontend

Podemos compartir:

```yaml
frontend:
  volumes:
    - ./frontend/index.html:/usr/share/nginx/html/index.html:ro
    - ./frontend/nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

## Database

El script de inicialización puede compartirse:

```yaml
database:
  volumes:
    - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    - postgres_data:/var/lib/postgresql/data
```

No debemos montar `./db` sobre `/var/lib/postgresql/data`: `init.sql` es un archivo de inicialización; el named volume contiene los datos de PostgreSQL.

## Backend

Antes de montar la carpeta completa del backend, inspeccionar la imagen y determinar su directorio de trabajo:

```bash
docker image inspect saludos-backend:1.0
```

No asumir `/app` sin comprobarlo.

### Concepto

```text
REPOSITORIO                    CONTENEDOR

./frontend/index.html  ─────→  archivo de Nginx
./frontend/nginx.conf  ─────→  configuración Nginx
./db/init.sql          ─────→  script de inicialización

Docker Volume
postgres_data          ─────→  datos PostgreSQL
```

---

# 15. Probar persistencia

Entrar a PostgreSQL:

```bash
docker compose exec database psql -U saludos_user -d saludos_db
```

Consultar:

```sql
\dt
```

Salir:

```sql
\q
```

Eliminar contenedores:

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
Container eliminado    → Sí
Container recreado     → Sí
Volume eliminado       → No
Datos                  → Permanecen
```

---

# 16. `down` vs `down -v`

Comparar:

```bash
docker compose down
```

con:

```bash
docker compose down -v
```

`down` elimina los recursos de ejecución del proyecto.

`down -v` también elimina los volúmenes asociados.

> **Advertencia:** no ejecutar `down -v` si necesitamos conservar los datos.

---

# 17. Healthcheck

Un contenedor `running` no necesariamente significa que la aplicación esté lista.

Agregar a PostgreSQL:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
  interval: 5s
  timeout: 5s
  retries: 5
  start_period: 10s
```

Aplicar:

```bash
docker compose up -d
```

Verificar:

```bash
docker compose ps
```

El servicio de database debe llegar a:

```text
healthy
```

---

# 18. Dependencia entre servicios

El backend depende de PostgreSQL.

Agregar:

```yaml
backend:
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

La dependencia se expresa sobre la disponibilidad saludable del servicio y no únicamente sobre la existencia del contenedor.

---

# 19. Troubleshooting controlado

Provocar un problema intencional.

En el archivo de ambiente utilizado cambiar:

```env
DB_HOST=database
```

por:

```env
DB_HOST=database-error
```

Aplicar:

```bash
docker compose --env-file .env.dev up -d
```

## 19.1 Estado

```bash
docker compose ps
```

## 19.2 Logs

```bash
docker compose logs backend
```

Para seguirlos:

```bash
docker compose logs -f backend
```

## 19.3 Variables

```bash
docker compose exec backend env | grep DB_
```

## 19.4 DNS

```bash
docker compose exec backend getent hosts database
```

```bash
docker compose exec backend getent hosts database-error
```

## 19.5 Corregir

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

---

# 20. Inspección

Compose administra la aplicación, pero Docker continúa administrando los recursos.

Contenedores:

```bash
docker ps
```

Inspección:

```bash
docker inspect <CONTAINER_ID>
```

Red:

```bash
docker network ls
docker network inspect <NETWORK_NAME>
```

Volúmenes:

```bash
docker volume ls
docker volume inspect <VOLUME_NAME>
```

**Pregunta:** ¿por qué seguimos utilizando comandos `docker` si estamos utilizando Compose?

Porque Compose define y administra la aplicación, mientras que los recursos finales continúan siendo recursos Docker.

---

# 21. Validación final

Arquitectura esperada:

```text
                         HOST
                          |
                    FRONTEND :8080
                          |
                          v
                     Frontend
                          |
                    Docker Network
                          |
                          v
                       Backend
                          |
                    Docker Network
                          |
                          v
                      Database
                          |
                          v
                    postgres_data
                          |
                          v
                   Persistent Data
```

Validar:

```bash
docker compose ps
```

```bash
docker compose config
```

```bash
docker volume ls
```

```bash
docker network ls
```

Abrir:

```text
http://localhost:8080
```

Presionar el botón de saludo y comprobar que la aplicación continúa funcionando.

---

# 22. Checklist final

- [ ] Se reutilizaron las tres imágenes existentes.
- [ ] No se reconstruyeron las imágenes innecesariamente.
- [ ] Los tres servicios están definidos en `compose.yml`.
- [ ] Compose administra la red.
- [ ] Frontend llega a backend.
- [ ] Backend encuentra database mediante el nombre del servicio.
- [ ] La configuración utiliza variables de entorno.
- [ ] Existen `.env.dev` y `.env.prod`.
- [ ] Se puede seleccionar el ambiente mediante `--env-file`.
- [ ] `.env` no se utiliza como mecanismo de secretos.
- [ ] PostgreSQL utiliza un named volume.
- [ ] Se diferenciaron named volumes y bind mounts.
- [ ] Se compartieron archivos seleccionados del repositorio mediante bind mounts.
- [ ] Los datos sobreviven a `docker compose down`.
- [ ] PostgreSQL tiene healthcheck.
- [ ] Backend depende de database saludable.
- [ ] Se realizó troubleshooting con `ps`, `logs`, `exec` e `inspect`.
- [ ] La aplicación funciona desde el navegador.

---

# 23. Reto final

## Reto 1 — Ambientes

Levantar la aplicación utilizando `.env.dev` y `.env.prod`.

Identificar qué valores cambian y cuáles permanecen iguales.

## Reto 2 — Persistencia

Demostrar:

```text
Crear dato
   ↓
docker compose down
   ↓
docker compose up -d
   ↓
El dato permanece
```

## Reto 3 — Troubleshooting

Provocar un error de configuración y documentar:

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

## Reto 4 — Cambio sin reconstruir

Modificar un archivo del frontend compartido mediante bind mount y verificar el efecto sin reconstruir la imagen.

---

# Resultado esperado

Al finalizar, la aplicación que en Docker Básico requería administrar varios contenedores de forma individual podrá ser definida como una aplicación multicontenedor mediante Docker Compose.

El estudiante deberá poder explicar:

- Dockerfile → cómo se construye una imagen.
- Image → artefacto de la aplicación.
- Container → instancia ejecutable.
- Compose → definición y administración de la aplicación multicontenedor.
- Network → comunicación entre servicios.
- Service Discovery → comunicación mediante nombres.
- Environment Variables → configuración externa.
- `.env.dev` / `.env.prod` → configuración por ambiente.
- Bind Mount → compartir rutas/archivos del host.
- Named Volume → persistencia administrada por Docker.
- Healthcheck → verificar disponibilidad real.
- `depends_on` → expresar dependencias.
- Logs / exec / inspect → diagnóstico.

La meta no es memorizar un `compose.yml` terminado, sino aprender a construirlo a partir de las necesidades reales de una aplicación.

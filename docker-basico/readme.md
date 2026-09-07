# Laboratorio: Docker básico

## Objetivo

En este laboratorio construiremos la misma arquitectura que en vagrant pero utilizando 3 contenedores. 

El objetivo es identificar las ventjas y desventajas de una arquitectura basada en contenedores y la previamente construida con VMs-

Al finalizar, tendremos una arquitectura como esta:

```text
                         Usuario
                            │
                            │ HTTP :80
                            ▼
                ┌───────────────────────┐
                │   FRONTEND Container  │
                │         :80           │
                │                       │
                │     Nginx + HTML      │
                └───────────┬───────────┘
                            │
                            │ HTTP :5000
                            ▼
                ┌───────────────────────┐
                │   BACKEND Container   │
                │         :5000         │
                │                       │
                │    Python + Flask     │
                └───────────┬───────────┘
                            │
                            │ PostgreSQL:5432
                            ▼
                ┌───────────────────────┐
                │   DATABASE Container  │
                │         :5432         │
                │                       │
                │      PostgreSQL       │
                └───────────────────────┘
```

# Componentes del laboratorio

| Componente | Tecnología | Carpeta |
|---|---|---|
| Frontend | HTML + JavaScript + Nginx | `frontend` |
| Backend | Python + Flask | `backend` |
| Base de datos | PostgreSQL | `db` |
| Infraestructura | Docker | Contenedor |

---

# Requisitos

Antes de iniciar, verificar que se encuentran instalados:

- Docker
- Git

Verificar las versión:

```bash
docker --version
```

Verificar que puedas correr comandos sin sudo:

```bash
docker ps
```

Sino corre este comando:

```bash
sudo usermod -aG docker $USER
```

---

# Estructura del proyecto

El repositorio tiene la siguiente estructura:

```text
docker-basico/
│
├── db/
│   ├── Dockerfile
│   └── init.sql
│
├── frontend/
│   ├── Dockerfile 
    ├── nginx.conf 
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
cd docker-basico
```

---

# Paso 2: Construir Dockerfiles

Teniendo en cuenta las dependencias de ./virtualizacion/scripts

```text
Dockerfile
```

Identificar los siguientes elementos:

- FROM
- RUN
- COPY
- CMD

---

# Paso 3: Crear las imágenes 

Desde la ubicación de cada Dockerfile:

```bash
docker build -t $IMAGE_NAME:$IMAGE_TAG .
```

Este comando creará cada imagen con una capa por comando/instrucción del Dockerfile

---

# Paso 4: Verificar el estado de las imágenes

Ejecutar:

```bash
docker image ls
```

El resultado esperado debe mostrar:

```text
REPOSITORY   TAG           IMAGE ID       CREATED             SIZE
frontend     latest        03a847616af6   About an hour ago   69MB
backend      latest        03a847616af6   About an hour ago   69MB
db           latest        03a847616af6   About an hour ago   69MB
```

---

# Paso 5: Crear contenedores

Ejecutar por imagen:

```bash
docker run -d -n $CONTAINER_NAME $IMAGE_NAME:$IMAGE_TAG 
```

---

# Paso 6: Verificar el estado de los contenedores

Ejecutar:

```bash
docker ps
```

El resultado esperado debe mostrar:

```text
REPOSITORY   TAG           IMAGE ID       CREATED             SIZE
```

---

# Paso 8: Crear red entre los contenedores

Ejecutar

```bash
vagrant ssh backend
```

Correr de nuevo los contenedores 
---

# Paso 9: Probar la aplicación

Desde el computador host abrir:

```text
http://localhost
```

Debe aparecer la aplicación.

Presionar el botón:

```text
Obtener saludo
```

Cada vez que se presiona el botón, el sistema debe obtener un saludo aleatorio desde PostgreSQL.

---

# Paso 16: Analizar el flujo de la aplicación

Al presionar el botón ocurre lo siguiente:

```text
1. Usuario presiona el botón

        ↓

2. Frontend realiza solicitud HTTP

        ↓

3. Nginx recibe la solicitud

        ↓

4. Nginx redirige /api al Backend

        ↓

5. Backend recibe la solicitud

        ↓

6. Backend consulta PostgreSQL

        ↓

7. PostgreSQL selecciona un saludo aleatorio

        ↓

8. Backend devuelve JSON

        ↓

9. Frontend muestra el saludo
```

---

# Analisis

> ¿Qué diferencias existen entre el ambiente virtualizado y este contenerizado?

---

# Preguntas para discusión

Al finalizar el laboratorio, discutir en grupo:

1. ¿Qué problemas resolvió Docker durante el laboratorio?
2. ¿Qué configuración sigue siendo manual?
3. ¿Podríamos reconstruir todo el ambiente fácilmente?
4. ¿Qué ocurriría si otro desarrollador necesitara exactamente el mismo ambiente?
5. ¿Cómo logramos que la aplicación se conecte entre si?
6. ¿Que pasaría si queremos persistencia de los datos cuando se desplieguen más versiones de la aplicación?
7. ¿Cambiaría la arquitectura si aumenta la demanda de la aplicación?
8. ¿Qué etapas del ciclo de DevOps estamos cubriendo con esta práctica?

---

# Conclusión

Durante este laboratorio se construyó una aplicación distribuida utilizando tres máquinas virtuales independientes.

Cada máquina tuvo una responsabilidad específica:

```text
Frontend VM
     │
     ▼
Backend VM
     │
     ▼
Database VM
```

La infraestructura fue creada de manera declarativa mediante Vagrant y parte de la configuración inicial fue automatizada mediante scripts de provisioning.

> Si una aplicación y su infraestructura pueden describirse mediante configuración y código, ¿por qué continuar realizando manualmente las mismas tareas una y otra vez?

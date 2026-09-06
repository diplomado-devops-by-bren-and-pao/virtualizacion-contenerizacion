# Laboratorio: Arquitectura de Tres Capas con Vagrant

## Objetivo

En este laboratorio construiremos una arquitectura distribuida básica utilizando **tres máquinas virtuales** creadas y administradas mediante Vagrant.

La aplicación estará compuesta por:

- Un **Frontend**.
- Un **Backend**.
- Una **Base de datos PostgreSQL**.

El objetivo no es únicamente crear máquinas virtuales. Durante el laboratorio se analizará cómo diferentes componentes de una aplicación pueden ejecutarse en máquinas independientes y comunicarse a través de una red privada.

Al finalizar, tendremos una arquitectura como esta:

```text
                         Usuario
                            │
                            │ HTTP :80
                            ▼
                ┌───────────────────────┐
                │      FRONTEND VM      │
                │    192.168.56.11      │
                │                       │
                │     Nginx + HTML      │
                └───────────┬───────────┘
                            │
                            │ HTTP :5000
                            ▼
                ┌───────────────────────┐
                │      BACKEND VM       │
                │    192.168.56.12      │
                │                       │
                │    Python + Flask     │
                └───────────┬───────────┘
                            │
                            │ PostgreSQL :5432
                            ▼
                ┌───────────────────────┐
                │     DATABASE VM       │
                │    192.168.56.13      │
                │                       │
                │      PostgreSQL       │
                └───────────────────────┘
```

---

# Arquitectura de la aplicación

La aplicación permite al usuario presionar un botón para obtener un saludo aleatorio.

El flujo será el siguiente:

```text
Usuario
   │
   │ Presiona un botón
   ▼
Frontend
   │
   │ Solicitud HTTP
   ▼
Backend
   │
   │ Consulta SQL
   ▼
Base de datos
   │
   │ Saludo aleatorio
   ▼
Backend
   │
   │ Respuesta JSON
   ▼
Frontend
   │
   ▼
Usuario
```

Cada vez que el usuario presiona el botón, el backend consulta un saludo diferente almacenado en PostgreSQL.

---

# Componentes del laboratorio

| Componente | Tecnología | Máquina |
|---|---|---|
| Frontend | HTML + JavaScript + Nginx | `frontend` |
| Backend | Python + Flask | `backend` |
| Base de datos | PostgreSQL | `database` |
| Infraestructura | Vagrant + VirtualBox | Host |

---

# Requisitos

Antes de iniciar, verificar que se encuentran instalados:

- VirtualBox
- Vagrant
- Git

Verificar las versiones:

```bash
vagrant --version
```

```bash
VBoxManage --version
```

---

# Estructura del proyecto

El repositorio tiene la siguiente estructura:

```text
vagrant-three-tier/
│
├── Vagrantfile
│
├── scripts/
│   ├── frontend.sh
│   ├── backend.sh
│   └── database.sh
│
├── frontend/
│   └── index.html
│
└── backend/
    ├── app.py
    └── requirements.txt
```

---

# Paso 1: Clonar el repositorio

Clonar el repositorio:

```bash
git clone <URL_DEL_REPOSITORIO>
```

Ingresar al directorio:

```bash
cd vagrant-three-tier
```

---

# Paso 2: Revisar el Vagrantfile

Antes de crear las máquinas virtuales, abrir el archivo:

```text
Vagrantfile
```

Identificar los siguientes elementos:

- Número de máquinas virtuales.
- Nombre de cada máquina.
- Dirección IP asignada.
- Memoria.
- CPU.
- Red privada.
- Scripts de provisioning.

Las máquinas que se crearán son:

| Máquina | IP |
|---|---|
| Frontend | `192.168.56.11` |
| Backend | `192.168.56.12` |
| Database | `192.168.56.13` |

---

# Paso 3: Crear las máquinas virtuales

Desde la carpeta del proyecto ejecutar:

```bash
vagrant up
```

Este comando realizará las siguientes acciones:

```text
Vagrant
   │
   ├── Crea Frontend VM
   │
   ├── Crea Backend VM
   │
   └── Crea Database VM
```

Durante el proceso, Vagrant también ejecutará los scripts de provisioning definidos en el `Vagrantfile`.

---

# Paso 4: Verificar el estado de las máquinas

Ejecutar:

```bash
vagrant status
```

El resultado esperado debe mostrar:

```text
frontend    running
backend     running
database    running
```

---

# Paso 5: Explorar las máquinas virtuales

Ingresar a la máquina frontend:

```bash
vagrant ssh frontend
```

Salir:

```bash
exit
```

Ingresar al backend:

```bash
vagrant ssh backend
```

Salir:

```bash
exit
```

Ingresar a la base de datos:

```bash
vagrant ssh database
```

Salir:

```bash
exit
```

---

# Paso 6: Validar conectividad entre las máquinas

Ingresar a la máquina frontend:

```bash
vagrant ssh frontend
```

Probar conectividad con el backend:

```bash
ping -c 3 192.168.56.12
```

Probar conectividad con la base de datos:

```bash
ping -c 3 192.168.56.13
```

Salir:

```bash
exit
```

Ahora ingresar al backend:

```bash
vagrant ssh backend
```

Probar conectividad con la base de datos:

```bash
ping -c 3 192.168.56.13
```

Salir:

```bash
exit
```

---

# Paso 7: Verificar PostgreSQL

La base de datos fue instalada y configurada automáticamente mediante el script:

```text
scripts/database.sh
```

Ingresar a la máquina:

```bash
vagrant ssh database
```

Verificar el servicio:

```bash
sudo systemctl status postgresql
```

Salir de la máquina:

```bash
exit
```

---

# Paso 8: Verificar conexión desde Backend hacia Database

Ingresar al backend:

```bash
vagrant ssh backend
```

Conectarse a PostgreSQL:

```bash
psql \
  -h 192.168.56.13 \
  -U saludos_user \
  -d saludos_db
```

Cuando se solicite la contraseña utilizar:

```text
saludos_password
```

Consultar los saludos:

```sql
SELECT * FROM saludos;
```

Salir de PostgreSQL:

```sql
\q
```

Salir de la máquina:

```bash
exit
```

---

# Paso 9: Desplegar el Backend

Ingresar a la máquina backend:

```bash
vagrant ssh backend
```

Verificar los archivos disponibles:

```bash
ls /vagrant/backend
```

Crear el directorio de la aplicación:

```bash
sudo mkdir -p /opt/saludos-backend
```

Copiar los archivos:

```bash
sudo cp /vagrant/backend/* /opt/saludos-backend/
```

Asignar permisos:

```bash
sudo chown -R vagrant:vagrant /opt/saludos-backend
```

Ingresar al directorio:

```bash
cd /opt/saludos-backend
```

---

# Paso 10: Crear el entorno Python

Crear un entorno virtual:

```bash
python3 -m venv venv
```

Activarlo:

```bash
source venv/bin/activate
```

Instalar las dependencias:

```bash
pip install -r requirements.txt
```

---

# Paso 11: Ejecutar el Backend

Ejecutar:

```bash
python app.py
```

El backend debería iniciar en:

```text
http://0.0.0.0:5000
```

En otra terminal, probar el endpoint:

```bash
curl http://192.168.56.12:5000/health
```

Resultado esperado:

```json
{
    "status": "OK"
}
```

Probar el endpoint de saludo:

```bash
curl http://192.168.56.12:5000/saludo
```

Cada ejecución debería devolver un saludo aleatorio:

```json
{
    "mensaje": "¡Saludos desde PostgreSQL!"
}
```

Detener la aplicación utilizando:

```text
CTRL + C
```

---

# Paso 12: Ejecutar el Backend como servicio

Crear el servicio:

```bash
sudo vim /etc/systemd/system/saludos-backend.service
```

Agregar:

```ini
[Unit]
Description=Saludos Backend
After=network.target

[Service]
User=vagrant
WorkingDirectory=/opt/saludos-backend
ExecStart=/opt/saludos-backend/venv/bin/python /opt/saludos-backend/app.py
Restart=always

[Install]
WantedBy=multi-user.target
```

Guardar el archivo y recargar la configuración:

```bash
sudo systemctl daemon-reload
```

Habilitar el servicio:

```bash
sudo systemctl enable saludos-backend
```

Iniciar:

```bash
sudo systemctl start saludos-backend
```

Verificar:

```bash
sudo systemctl status saludos-backend
```

---

# Paso 13: Desplegar el Frontend

Ingresar a la máquina:

```bash
vagrant ssh frontend
```

Verificar los archivos:

```bash
ls /vagrant/frontend
```

Copiar la aplicación:

```bash
sudo cp /vagrant/frontend/index.html /var/www/html/index.html
```

---

# Paso 14: Configurar Nginx

Editar la configuración:

```bash
sudo nano /etc/nginx/sites-available/default
```

Utilizar la siguiente configuración:

```nginx
server {

    listen 80 default_server;

    listen [::]:80 default_server;

    root /var/www/html;

    index index.html;

    location / {

        try_files $uri $uri/ =404;

    }

    location /api/ {

        proxy_pass http://192.168.56.12:5000/;

        proxy_set_header Host $host;

        proxy_set_header X-Real-IP $remote_addr;

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    }

}
```

Validar la configuración:

```bash
sudo nginx -t
```

Reiniciar Nginx:

```bash
sudo systemctl restart nginx
```

---

# Paso 15: Probar la aplicación

Desde el computador host abrir:

```text
http://192.168.56.11
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

# Paso 17: Prueba de fallos

## Fallo de Base de Datos

Ingresar a la máquina database:

```bash
vagrant ssh database
```

Detener PostgreSQL:

```bash
sudo systemctl stop postgresql
```

Volver al navegador y presionar el botón.

Reiniciar PostgreSQL:

```bash
sudo systemctl start postgresql
```

---

## Fallo del Backend

Ingresar al backend:

```bash
vagrant ssh backend
```

Detener el servicio:

```bash
sudo systemctl stop saludos-backend
```

Volver a probar la aplicación.

Reiniciar:

```bash
sudo systemctl start saludos-backend
```

---

## Fallo del Frontend

Ingresar:

```bash
vagrant ssh frontend
```

Detener Nginx:

```bash
sudo systemctl stop nginx
```

Intentar acceder nuevamente a:

```text
http://192.168.56.11
```

Reiniciar:

```bash
sudo systemctl start nginx
```

---

# Paso 18: Experimentar con los saludos

Ingresar a PostgreSQL:

```bash
vagrant ssh database
```

Ingresar a la base de datos:

```bash
sudo -u postgres psql -d saludos_db
```

Consultar los registros:

```sql
SELECT * FROM saludos;
```

Agregar un nuevo saludo:

```sql
INSERT INTO saludos (mensaje)
VALUES ('¡Nuevo saludo agregado durante el laboratorio!');
```

Salir:

```sql
\q
```

Volver a presionar el botón varias veces hasta obtener el nuevo saludo.

---

# Paso 19: Administrar las máquinas con Vagrant

Detener todas las máquinas:

```bash
vagrant halt
```

Iniciarlas nuevamente:

```bash
vagrant up
```

Verificar el estado:

```bash
vagrant status
```

Destruir una máquina específica:

```bash
vagrant destroy backend
```

Destruir todo el ambiente:

```bash
vagrant destroy -f
```

---

# Analisis

> ¿Qué actividades realizadas durante el laboratorio deberían continuar siendo manuales y cuáles deberían automatizarse?

---

# Preguntas para discusión

Al finalizar el laboratorio, discutir en grupo:

1. ¿Qué problemas resolvió Vagrant durante el laboratorio?
2. ¿Qué configuración sigue siendo manual?
3. ¿Podríamos reconstruir todo el ambiente fácilmente?
4. ¿Qué ocurriría si otro desarrollador necesitara exactamente el mismo ambiente?
5. ¿Qué tareas podrían convertirse en scripts?
6. ¿En qué momento sería útil utilizar una herramienta de Configuration Management?
7. ¿Qué partes podrían ejecutarse posteriormente dentro de contenedores?
8. ¿Cambiaría la arquitectura si pasáramos de 3 máquinas virtuales a decenas de aplicaciones?

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

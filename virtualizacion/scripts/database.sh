#!/usr/bin/env bash

set -e

echo "======================================"
echo "Configurando PostgreSQL"
echo "======================================"

apt-get update

apt-get install -y \
    postgresql \
    postgresql-contrib


systemctl enable postgresql

systemctl start postgresql


echo "Configurando PostgreSQL..."

POSTGRES_VERSION=$(ls /etc/postgresql | head -n 1)

POSTGRES_CONF="/etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf"

PG_HBA_CONF="/etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf"


sed -i \
    "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" \
    "$POSTGRES_CONF"


echo "host    saludos_db    saludos_user    192.168.56.0/24    scram-sha-256" \
    >> "$PG_HBA_CONF"


echo "Creando usuario..."

sudo -u postgres psql <<EOF
CREATE USER saludos_user
WITH PASSWORD 'saludos_password';
EOF


echo "Creando base de datos..."

sudo -u postgres psql <<EOF
CREATE DATABASE saludos_db
OWNER saludos_user;
EOF


echo "Creando tabla y saludos..."

sudo -u postgres psql -d saludos_db <<EOF

CREATE TABLE saludos (
    id SERIAL PRIMARY KEY,
    mensaje VARCHAR(255) NOT NULL
);

INSERT INTO saludos (mensaje) VALUES
('¡Hola! Espero que tengas un excelente día.'),
('¡Hola desde la arquitectura de tres capas!'),
('¡Saludos desde PostgreSQL!'),
('¡Bienvenido al laboratorio de virtualización!'),
('¡Tu solicitud viajó por varias máquinas virtuales!'),
('¡Todo funciona correctamente!'),
('¡Saludos desde el backend!'),
('¡La base de datos respondió correctamente!'),
('¡Excelente! Acabas de consultar una aplicación distribuida.'),
('¡Bienvenido a la infraestructura virtualizada!');

EOF


echo "Reiniciando PostgreSQL..."

systemctl restart postgresql


echo "======================================"
echo "PostgreSQL configurado correctamente"
echo "======================================"
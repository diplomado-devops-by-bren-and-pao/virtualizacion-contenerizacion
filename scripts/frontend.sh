#!/usr/bin/env bash

set -e

echo "======================================"
echo "Configurando Frontend"
echo "======================================"

apt-get update

apt-get install -y nginx

systemctl enable nginx

systemctl start nginx

echo "Frontend preparado correctamente"
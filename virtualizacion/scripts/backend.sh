#!/usr/bin/env bash

set -e

echo "======================================"
echo "Configurando Backend"
echo "======================================"

apt-get update

apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    postgresql-client

echo "Backend preparado correctamente"
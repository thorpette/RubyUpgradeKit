#!/bin/bash
set -e

# Configurar puerto desde variable de entorno
export PORT=${PORT:-5000}
export HOST=${HOST:-0.0.0.0}

echo "Iniciando Ruby Migrator en puerto $PORT..."

# Verificar si es la aplicación web o CLI
if [[ "$1" == "ruby" && "$2" == "app.rb" ]]; then
    echo "Modo Web App - Puerto: $PORT"
    exec ruby app.rb
elif [[ "$1" == "ruby" && "$2" == "migrator.rb" ]]; then
    echo "Modo CLI Migrator"
    exec "$@"
else
    # Ejecutar comando personalizado
    exec "$@"
fi
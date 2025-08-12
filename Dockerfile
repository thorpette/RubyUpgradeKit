# Dockerfile para Ruby Migrator Tool
FROM ruby:3.3.8-slim

# Instalar dependencias del sistema básicas
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configurar directorio de trabajo
WORKDIR /app

# Copiar Gemfile primero para aprovechar cache de Docker
COPY Gemfile* /app/

# Instalar gemas
RUN bundle install

# Copiar resto de archivos de la aplicación  
COPY . /app/

# Crear directorios necesarios
RUN mkdir -p /app/backups /app/reports /app/uploads

# Exponer puerto (será configurable)
EXPOSE 5000

# Variables de entorno por defecto
ENV RACK_ENV=production
ENV PORT=5000
ENV HOST=0.0.0.0

# Script de inicio
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Comando por defecto
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["ruby", "app.rb"]
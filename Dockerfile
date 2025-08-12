# Dockerfile para Ruby Migrator Tool
FROM ruby:3.3.8-alpine

# Instalar dependencias del sistema
RUN apk add --no-cache \
    build-base \
    git \
    bash \
    curl \
    wkhtmltopdf \
    xvfb \
    ttf-dejavu

# Configurar directorio de trabajo
WORKDIR /app

# Copiar archivos de la aplicación
COPY . /app/

# Instalar gemas Ruby (si hay Gemfile)
RUN if [ -f Gemfile ]; then bundle install; fi

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
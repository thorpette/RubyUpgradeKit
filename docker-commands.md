# Comandos Docker para Ruby Migrator en Windows 11

## Configuración Inicial

### 1. Verificar Docker
```bash
docker --version
docker-compose --version
```

### 2. Construir imagen
```bash
docker build -t ruby-migrator:latest .
```

## Ejecutar Instancias Múltiples

### Opción 1: Usar Docker Compose (Recomendado)
```bash
# Ejecutar todas las instancias (puertos 7000-7002)
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Detener todas las instancias
docker-compose down
```

### Opción 2: Ejecutar manualmente
```bash
# Instancia 1 - Puerto 7000
docker run -d \
  --name ruby-migrator-7000 \
  -p 7000:5000 \
  -v ${PWD}/projects:/app/projects \
  -v ${PWD}/backups:/app/backups \
  -e PORT=5000 \
  ruby-migrator:latest

# Instancia 2 - Puerto 7001
docker run -d \
  --name ruby-migrator-7001 \
  -p 7001:5000 \
  -v ${PWD}/projects:/app/projects \
  -v ${PWD}/backups:/app/backups \
  -e PORT=5000 \
  ruby-migrator:latest

# Instancia 3 - Puerto 7002
docker run -d \
  --name ruby-migrator-7002 \
  -p 7002:5000 \
  -v ${PWD}/projects:/app/projects \
  -v ${PWD}/backups:/app/backups \
  -e PORT=5000 \
  ruby-migrator:latest
```

## Usar CLI en Docker

### Análisis de proyecto
```bash
# Modo interactivo
docker run -it --rm \
  -v ${PWD}/projects:/app/projects \
  -v ${PWD}/backups:/app/backups \
  ruby-migrator:latest ruby migrator.rb -p /app/projects/mi_proyecto

# Solo reporte
docker run --rm \
  -v ${PWD}/projects:/app/projects \
  ruby-migrator:latest ruby migrator.rb -p /app/projects/mi_proyecto -r -f json
```

## Gestión de Contenedores

### Ver contenedores activos
```bash
docker ps
```

### Ver logs de una instancia específica
```bash
docker logs ruby-migrator-7000
```

### Detener una instancia específica
```bash
docker stop ruby-migrator-7000
docker rm ruby-migrator-7000
```

### Detener todas las instancias Ruby Migrator
```bash
docker stop $(docker ps -q --filter "name=ruby-migrator")
docker rm $(docker ps -aq --filter "name=ruby-migrator")
```

## Acceso a las Aplicaciones

Una vez ejecutando:
- **Instancia 1**: http://localhost:7000
- **Instancia 2**: http://localhost:7001  
- **Instancia 3**: http://localhost:7002

## Volúmenes y Persistencia

Los siguientes directorios son compartidos entre el host y los contenedores:
- `./projects` → `/app/projects` (Código a analizar)
- `./backups` → `/app/backups` (Respaldos automáticos)
- `./reports` → `/app/reports` (Reportes generados)

## Escalado Dinámico

### Agregar más instancias
```bash
# Puerto 7003
docker run -d \
  --name ruby-migrator-7003 \
  -p 7003:5000 \
  -v ${PWD}/projects:/app/projects \
  ruby-migrator:latest

# Puerto 7004
docker run -d \
  --name ruby-migrator-7004 \
  -p 7004:5000 \
  -v ${PWD}/projects:/app/projects \
  ruby-migrator:latest
```

## Troubleshooting

### Ver logs detallados
```bash
docker logs --tail 50 ruby-migrator-7000
```

### Acceder al contenedor
```bash
docker exec -it ruby-migrator-7000 /bin/bash
```

### Reiniciar una instancia
```bash
docker restart ruby-migrator-7000
```

### Limpiar todo
```bash
docker-compose down --volumes --rmi all
docker system prune -f
```
# 🐳 Ruby Migrator - Configuración Docker para Windows 11

## 📋 Requisitos Previos

### 1. Instalar Docker Desktop para Windows 11
```powershell
# Descargar desde: https://docs.docker.com/desktop/install/windows-install/
# O usar Chocolatey:
choco install docker-desktop
```

### 2. Verificar Instalación
```powershell
docker --version
docker-compose --version
```

## 🚀 Configuración Rápida

### Opción 1: Script Automático (Recomendado)
```batch
# Ejecutar el script de Windows
docker-run-windows.bat
```

### Opción 2: Docker Compose
```powershell
# Construir imagen
docker build -t ruby-migrator:latest .

# Ejecutar todas las instancias (puertos 7000-7002)
docker-compose up -d

# Verificar estado
docker-compose ps
```

## 🌐 Acceso a las Aplicaciones

Una vez ejecutando los contenedores:

| Instancia | URL | Puerto Host | Puerto Contenedor |
|-----------|-----|-------------|-------------------|
| Ruby Migrator 1 | http://localhost:7000 | 7000 | 5000 |
| Ruby Migrator 2 | http://localhost:7001 | 7001 | 5000 |
| Ruby Migrator 3 | http://localhost:7002 | 7002 | 5000 |

## 📁 Estructura de Directorios

```
proyecto/
├── docker-compose.yml       # Configuración múltiples instancias
├── Dockerfile              # Imagen Ruby Migrator
├── docker-entrypoint.sh    # Script de inicio
├── docker-run-windows.bat  # Script automático Windows
├── projects/               # Proyectos a analizar (compartido)
├── backups/                # Respaldos automáticos (compartido)
└── reports/                # Reportes generados (compartido)
```

## ⚙️ Comandos Específicos Windows 11

### Gestión de Instancias

```powershell
# Ver contenedores activos
docker ps

# Logs de una instancia específica
docker logs ruby-migrator-7000

# Logs en tiempo real
docker logs -f ruby-migrator-7001

# Detener una instancia
docker stop ruby-migrator-7000

# Reiniciar una instancia
docker restart ruby-migrator-7001
```

### Escalado Manual

```powershell
# Agregar instancia en puerto 7003
docker run -d `
  --name ruby-migrator-7003 `
  -p 7003:5000 `
  -v ${PWD}/projects:/app/projects `
  -v ${PWD}/backups:/app/backups `
  -v ${PWD}/reports:/app/reports `
  -e PORT=5000 `
  -e HOST=0.0.0.0 `
  -e INSTANCE_NAME="Ruby Migrator 4" `
  ruby-migrator:latest

# Agregar instancia en puerto 7004
docker run -d `
  --name ruby-migrator-7004 `
  -p 7004:5000 `
  -v ${PWD}/projects:/app/projects `
  -v ${PWD}/backups:/app/backups `
  -e INSTANCE_NAME="Ruby Migrator 5" `
  ruby-migrator:latest
```

### Usar CLI en Windows

```powershell
# Análisis interactivo
docker run -it --rm `
  -v ${PWD}/projects:/app/projects `
  -v ${PWD}/backups:/app/backups `
  ruby-migrator:latest ruby migrator.rb -p /app/projects/mi_proyecto

# Solo reporte JSON
docker run --rm `
  -v ${PWD}/projects:/app/projects `
  ruby-migrator:latest ruby migrator.rb -p /app/projects/mi_proyecto -r -f json > reporte.json
```

## 🔧 Configuración Avanzada

### Variables de Entorno Personalizadas

```powershell
# Ejecutar con configuración específica
docker run -d `
  --name ruby-migrator-custom `
  -p 8000:5000 `
  -e PORT=5000 `
  -e HOST=0.0.0.0 `
  -e INSTANCE_NAME="Migrator Personalizado" `
  -e RACK_ENV=production `
  ruby-migrator:latest
```

### Volúmenes Personalizados

```powershell
# Usar directorio específico para proyectos
docker run -d `
  --name ruby-migrator-dev `
  -p 7000:5000 `
  -v C:/Users/usuario/proyectos-ruby:/app/projects `
  -v ${PWD}/backups:/app/backups `
  ruby-migrator:latest
```

## 🐞 Solución de Problemas Windows 11

### Error: "Docker daemon is not running"
```powershell
# Iniciar Docker Desktop manualmente
# O reiniciar el servicio
Restart-Service docker
```

### Error: "Port already in use"
```powershell
# Verificar qué proceso usa el puerto
netstat -ano | findstr :7000

# Cambiar a puerto disponible
docker run -d --name ruby-migrator-alt -p 7010:5000 ruby-migrator:latest
```

### Error de permisos en volúmenes
```powershell
# Verificar que Docker tenga acceso a las carpetas
# En Docker Desktop: Settings > Resources > File Sharing
# Agregar la ruta del proyecto
```

### Limpiar contenedores problemáticos
```powershell
# Detener todos los contenedores Ruby Migrator
docker stop $(docker ps -q --filter "name=ruby-migrator")

# Eliminar todos los contenedores Ruby Migrator
docker rm $(docker ps -aq --filter "name=ruby-migrator")

# Limpiar imágenes no usadas
docker image prune -f
```

## 📊 Monitoreo y Rendimiento

### Ver uso de recursos
```powershell
# Estadísticas en tiempo real
docker stats

# Uso específico de una instancia
docker stats ruby-migrator-7000
```

### Logs estructurados
```powershell
# Logs de todas las instancias
docker-compose logs

# Logs con filtro de tiempo
docker logs --since="1h" ruby-migrator-7000

# Logs con límite de líneas
docker logs --tail=100 ruby-migrator-7001
```

## 🔄 Actualizaciones y Mantenimiento

### Reconstruir imagen
```powershell
# Reconstruir con cambios
docker build --no-cache -t ruby-migrator:latest .

# Recrear contenedores con nueva imagen
docker-compose down
docker-compose up -d
```

### Backup de datos
```powershell
# Crear backup de reportes y respaldos
docker run --rm `
  -v ${PWD}/backups:/source `
  -v ${PWD}/backup-$(Get-Date -Format "yyyyMMdd"):/destination `
  alpine cp -r /source /destination
```

## 🎯 Casos de Uso Típicos

### Desarrollo Local
```powershell
# Una instancia para desarrollo
docker run -d --name ruby-migrator-dev -p 7000:5000 ruby-migrator:latest
```

### Equipo Múltiple
```powershell
# Múltiples instancias para equipo
docker-compose up -d
# Cada desarrollador usa un puerto diferente (7000, 7001, 7002)
```

### Análisis Batch
```powershell
# Procesar múltiples proyectos
foreach ($proyecto in Get-ChildItem -Directory ./projects) {
    docker run --rm `
      -v ${PWD}/projects:/app/projects `
      ruby-migrator:latest ruby migrator.rb -p /app/projects/$($proyecto.Name) -r -f json > "./reports/$($proyecto.Name)-report.json"
}
```

## 📞 Soporte

- **Logs detallados**: `docker logs --details ruby-migrator-7000`
- **Acceso al contenedor**: `docker exec -it ruby-migrator-7000 /bin/bash`
- **Estado de la red**: `docker network ls`
- **Información de imagen**: `docker image inspect ruby-migrator:latest`

---

**Configuración Docker optimizada para Windows 11 - Ruby Migrator Tool v1.0.0**
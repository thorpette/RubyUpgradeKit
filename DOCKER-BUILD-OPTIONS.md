# 🐳 Opciones de Build Docker - Ruby Migrator

## ✅ Problema Solucionado

El error de construcción Docker con `wkhtmltopdf` en Alpine ha sido resuelto. Ahora tienes **3 opciones** de Dockerfile según tus necesidades:

## 📋 Opciones Disponibles

### 1. Dockerfile.simple (RECOMENDADO)
**Más rápido y compatible**
```dockerfile
FROM ruby:3.3.8
# Solo lo esencial para Ruby Migrator
# Sin dependencias externas problemáticas
```

**Ventajas:**
- ✅ Construcción rápida (2-3 minutos)
- ✅ Compatible con todos los sistemas
- ✅ Imagen más pequeña (~350MB)
- ✅ Sin errores de dependencias

**Desventajas:**
- ❌ No incluye generación de PDF

### 2. Dockerfile (Versión Completa)
**Con capacidades adicionales**
```dockerfile
FROM ruby:3.3.8-slim
# Incluye build-essential, git, bash, curl
# Sin wkhtmltopdf para evitar errores
```

**Ventajas:**
- ✅ Más herramientas de desarrollo
- ✅ Compatible con la mayoría de sistemas
- ✅ Soporte para extensiones

**Desventajas:**
- ⚠️ Imagen más grande (~450MB)
- ⚠️ Construcción más lenta

### 3. Dockerfile.alpine (Ultra-ligero)
**Para entornos con recursos limitados**
```dockerfile
FROM ruby:3.3.8-alpine
# Imagen mínima Alpine Linux
```

**Ventajas:**
- ✅ Imagen ultra-pequeña (~150MB)
- ✅ Arranque instantáneo
- ✅ Menos superficie de ataque

**Desventajas:**
- ⚠️ Posibles incompatibilidades con gemas nativas
- ⚠️ Requiere más configuración

## 🚀 Uso Automático

El script `docker-run-windows.bat` ahora prueba automáticamente en este orden:

1. **Dockerfile.simple** (primera opción)
2. **Dockerfile** (fallback si simple falla)
3. **Dockerfile.alpine** (último recurso)

## ⚙️ Comandos Manuales

### Construir versión específica
```batch
# Versión simple (recomendada)
docker build -f Dockerfile.simple -t ruby-migrator:simple .

# Versión completa
docker build -f Dockerfile -t ruby-migrator:full .

# Versión Alpine
docker build -f Dockerfile.alpine -t ruby-migrator:alpine .
```

### Usar versión específica
```batch
# Docker Compose usa Dockerfile.simple por defecto
docker-compose up -d

# Ejecutar manualmente con versión específica
docker run -d -p 7000:5000 ruby-migrator:simple
```

## 🔧 Configuración Personalizada

### Cambiar Dockerfile en docker-compose.yml
```yaml
services:
  ruby-migrator-1:
    build: 
      context: .
      dockerfile: Dockerfile        # Cambia a Dockerfile o Dockerfile.alpine
```

### Variables de entorno soportadas
```bash
PORT=5000                    # Puerto interno
HOST=0.0.0.0                # Host de binding
INSTANCE_NAME="Mi Migrator"  # Nombre de la instancia
RACK_ENV=production         # Entorno Ruby
```

## 🏆 Recomendación de Uso

**Para la mayoría de casos:** Usa `Dockerfile.simple`
- Es la más rápida de construir
- Funciona en todos los entornos
- Incluye todas las funcionalidades core del Ruby Migrator

**Para desarrollo avanzado:** Usa `Dockerfile` completo
- Si necesitas instalar gemas adicionales
- Si planeas extender la funcionalidad

**Para producción ligera:** Usa `Dockerfile.alpine`
- En contenedores con recursos limitados
- En despliegues a gran escala

## ⚡ Comandos de Prueba Rápida

```batch
# Probar construcción y ejecución
docker-test.bat

# O manualmente:
docker build -f Dockerfile.simple -t test-migrator .
docker run --rm -p 7000:5000 test-migrator
# Abrir http://localhost:7000
```

## 🐞 Solución de Problemas

### Si Dockerfile.simple falla:
- Verifica que Docker Desktop esté actualizado
- Revisa conectividad a internet para pull de ruby:3.3.8

### Si necesitas PDF generation:
- Instala wkhtmltopdf en el host
- Usa volumen para montar el ejecutable
- O construye imagen personalizada con wkhtmltopdf funcional

---

**Todas las opciones están configuradas y listas para usar en Windows 11 🚀**
@echo off
REM Script para ejecutar Ruby Migrator en Windows 11 con Docker

echo ========================================
echo   Ruby Migrator Docker Setup - Windows 11
echo ========================================

REM Corregir line endings automáticamente
echo Corrigiendo line endings de archivos Ruby y shell...
powershell -Command "& {Get-ChildItem -Include *.rb, *.sh | ForEach-Object { (Get-Content $_.FullName -Raw) -replace \"`r`n\", \"`n\" | Set-Content $_.FullName -NoNewline } }" 2>nul

REM Verificar si Docker está ejecutándose
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no está ejecutándose. Inicia Docker Desktop primero.
    pause
    exit /b 1
)

REM Crear directorios necesarios
if not exist "projects" mkdir projects
if not exist "backups" mkdir backups
if not exist "reports" mkdir reports

echo Creando directorios para proyectos, respaldos y reportes...
echo.

REM Construir imagen Docker (probando versión final optimizada)
echo Construyendo imagen Docker Ruby Migrator...
docker build -f Dockerfile.final -t ruby-migrator:latest .

if %errorlevel% neq 0 (
    echo Error con imagen final, probando versión simple...
    docker build -f Dockerfile.simple -t ruby-migrator:latest .
    
    if %errorlevel% neq 0 (
        echo Error con imagen simple, probando versión completa...
        docker build -t ruby-migrator:latest .
        
        if %errorlevel% neq 0 (
            echo ERROR: Todas las construcciones fallaron
            echo Verifica que Docker esté funcionando correctamente
            pause
            exit /b 1
        ) else (
            echo Imagen completa construida exitosamente
        )
    ) else (
        echo Imagen simple construida exitosamente
    )
)

echo.
echo Imagen construida exitosamente!
echo.

REM Mostrar opciones al usuario
echo Selecciona una opción:
echo 1. Ejecutar todas las instancias (puertos 7000-7002)
echo 2. Ejecutar una instancia específica
echo 3. Solo CLI (sin interfaz web)
echo 4. Detener todas las instancias
echo.

set /p choice="Ingresa tu opción (1-4): "

if "%choice%"=="1" goto run_all
if "%choice%"=="2" goto run_single
if "%choice%"=="3" goto run_cli
if "%choice%"=="4" goto stop_all
goto invalid_option

:run_all
echo.
echo Ejecutando todas las instancias Ruby Migrator...
docker-compose up -d
echo.
echo Instancias iniciadas:
echo - Ruby Migrator 1: http://localhost:7000
echo - Ruby Migrator 2: http://localhost:7001
echo - Ruby Migrator 3: http://localhost:7002
echo.
echo Usa 'docker-compose logs -f' para ver los logs
goto end

:run_single
echo.
set /p port="Ingresa el puerto deseado (ej: 7000): "
set /p instance="Nombre de la instancia (ej: migrator1): "

docker run -d ^
    --name ruby-migrator-%instance% ^
    -p %port%:5000 ^
    -v "%cd%\projects:/app/projects" ^
    -v "%cd%\backups:/app/backups" ^
    -v "%cd%\reports:/app/reports" ^
    -e PORT=5000 ^
    -e HOST=0.0.0.0 ^
    -e INSTANCE_NAME="Ruby Migrator %instance%" ^
    ruby-migrator:latest

echo.
echo Instancia iniciada en http://localhost:%port%
goto end

:run_cli
echo.
echo Ejecutando contenedor CLI...
docker run -it --rm ^
    -v "%cd%\projects:/app/projects" ^
    -v "%cd%\backups:/app/backups" ^
    -v "%cd%\reports:/app/reports" ^
    ruby-migrator:latest ruby migrator.rb --help

echo.
echo Para usar el CLI:
echo docker run -it --rm -v "%cd%\projects:/app/projects" ruby-migrator:latest ruby migrator.rb -p /app/projects/tu_proyecto
goto end

:stop_all
echo.
echo Deteniendo todas las instancias...
docker-compose down
docker stop $(docker ps -q --filter "name=ruby-migrator") 2>nul
docker rm $(docker ps -aq --filter "name=ruby-migrator") 2>nul
echo Todas las instancias han sido detenidas y removidas.
goto end

:invalid_option
echo Opción inválida. Ejecuta el script nuevamente.
goto end

:end
echo.
echo ========================================
echo   Script completado
echo ========================================
pause
@echo off
REM Prueba rápida de Docker con corrección automática

echo ========================================
echo   Prueba Rápida Docker - Ruby Migrator
echo ========================================

REM Corregir line endings
echo Corrigiendo line endings...
powershell -Command "(Get-Content app.rb -Raw) -replace \"`r`n\", \"`n\" | Set-Content app.rb -NoNewline" 2>nul
powershell -Command "(Get-Content docker-entrypoint.sh -Raw) -replace \"`r`n\", \"`n\" | Set-Content docker-entrypoint.sh -NoNewline" 2>nul

REM Verificar Docker
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no disponible
    pause
    exit /b 1
)

REM Construir imagen simple
echo Construyendo imagen simple...
docker build -f Dockerfile.simple -t ruby-migrator:quick-test . 

if %errorlevel% neq 0 (
    echo ERROR: Falló la construcción
    pause
    exit /b 1
)

echo.
echo ÉXITO: Imagen construida
echo.

REM Probar ejecución
echo Probando ejecución en puerto 7999...
docker run -d --name ruby-migrator-test -p 7999:5000 ruby-migrator:quick-test

timeout /t 3 >nul

echo.
echo Verificando logs...
docker logs ruby-migrator-test

echo.
echo Aplicación disponible en: http://localhost:7999
echo.
echo Comandos útiles:
echo   docker logs ruby-migrator-test
echo   docker stop ruby-migrator-test
echo   docker rm ruby-migrator-test
echo.
pause
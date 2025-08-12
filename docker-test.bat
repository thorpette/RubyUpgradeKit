@echo off
REM Script para probar la construcción de Docker

echo ========================================
echo   Probando construcción Docker
echo ========================================

REM Probar construcción con imagen slim
echo Probando construcción con Ruby slim...
docker build -t ruby-migrator:slim .

if %errorlevel% neq 0 (
    echo.
    echo Error con imagen slim, probando Alpine...
    docker build -f Dockerfile.alpine -t ruby-migrator:alpine .
    
    if %errorlevel% neq 0 (
        echo.
        echo ERROR: Ambas construcciones fallaron
        pause
        exit /b 1
    ) else (
        echo.
        echo Construcción Alpine exitosa!
        set IMAGE_TAG=alpine
    )
) else (
    echo.
    echo Construcción Slim exitosa!
    set IMAGE_TAG=slim
)

echo.
echo Probando ejecución del contenedor...
docker run --rm -p 7000:5000 -e PORT=5000 ruby-migrator:%IMAGE_TAG% &

timeout /t 5 >nul

echo.
echo Probando conectividad...
curl -s http://localhost:7000 >nul

if %errorlevel% equ 0 (
    echo Contenedor funcionando correctamente en puerto 7000
) else (
    echo Contenedor iniciado, verifica manualmente en http://localhost:7000
)

echo.
echo Para detener el contenedor:
echo docker stop $(docker ps -q --filter "ancestor=ruby-migrator:%IMAGE_TAG%")
echo.
pause
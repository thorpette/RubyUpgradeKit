@echo off
REM Script para corregir line endings de Windows en archivos Ruby

echo Corrigiendo line endings de Windows a Unix...

REM Usar PowerShell para convertir line endings
powershell -Command "& {Get-ChildItem -Recurse -Include *.rb, *.sh | ForEach-Object { (Get-Content $_.FullName -Raw) -replace \"`r`n\", \"`n\" | Set-Content $_.FullName -NoNewline } }"

echo Conversión completada.

REM Hacer ejecutable el script de entrada
if exist docker-entrypoint.sh (
    echo Convirtiendo docker-entrypoint.sh...
    powershell -Command "(Get-Content docker-entrypoint.sh -Raw) -replace \"`r`n\", \"`n\" | Set-Content docker-entrypoint.sh -NoNewline"
)

echo Todos los archivos han sido corregidos.
pause
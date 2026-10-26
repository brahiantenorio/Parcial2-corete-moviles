@echo off
title Frontend Flutter - Sistema de Gestion de Inventario
echo ===================================================================
echo     SISTEMA DE GESTION DE INVENTARIO - FRONTEND FLUTTER
echo     Segundo Parcial Practico - Electiva Profesional I
echo     Estudiante: Brahian Andres Tenorio
echo ===================================================================
echo.
cd /d "%~dp0frontend"
echo [1/2] Obteniendo paquetes de Flutter...
call flutter pub get
echo.
echo [2/2] Seleccione el dispositivo de ejecucion:
echo   1. Google Chrome (Navegador Web)
echo   2. Windows Desktop (Aplicacion Nativa)
echo   3. Emulador Android
echo   4. Deteccion automatica por defecto (flutter run)
echo.
set /p choice="Ingrese opcion [1-4] (Por defecto 1): "

if "%choice%"=="2" (
    echo Iniciando en Windows Desktop...
    call flutter run -d windows
) else if "%choice%"=="3" (
    echo Iniciando en Emulador Android...
    call flutter run -d emulator
) else if "%choice%"=="4" (
    echo Iniciando por defecto...
    call flutter run
) else (
    echo Iniciando en Google Chrome Web...
    call flutter run -d chrome
)
pause

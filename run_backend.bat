@echo off
title Backend FastAPI - Sistema de Gestion de Inventario
echo ===================================================================
echo     SISTEMA DE GESTION DE INVENTARIO - BACKEND FASTAPI
echo     Segundo Parcial Practico - Electiva Profesional I
echo     Estudiante: Brahian Andres Tenorio
echo ===================================================================
echo.
cd /d "%~dp0backend"
echo [1/2] Verificando dependencias...
python -m pip install -r requirements.txt
echo.
echo [2/2] Iniciando servidor FastAPI con Uvicorn en http://127.0.0.1:8000 ...
echo [INFO] Documentacion interactiva Swagger en: http://127.0.0.1:8000/docs
echo.
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause

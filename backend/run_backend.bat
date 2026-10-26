@echo off
echo ==========================================================
echo   SISTEMA DE GESTION DE INVENTARIO - BACKEND FASTAPI
echo   Segundo Parcial Practico - Electiva Profesional I
echo ==========================================================
echo.
echo Iniciando servidor Uvicorn en http://127.0.0.1:8000
echo Documentacion Swagger interactiva en: http://127.0.0.1:8000/docs
echo.
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause

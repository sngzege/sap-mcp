@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0"

if not exist .env (
    call setup.bat
    exit /b
)
if not exist venv\Scripts\python.exe (
    call setup.bat
    exit /b
)

venv\Scripts\python.exe app.py
if %errorlevel% neq 0 (
    echo.
    echo  HATA: Uygulama calisamadi
    echo.
)
pause

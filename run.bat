@echo off
cd /d "%~dp0"

REM .env veya venv yoksa kurulum
if not exist .env (
    echo  Ilk kurulum gerekli. setup.bat aciliyor...
    call setup.bat
    exit /b
)
if not exist venv\Scripts\python.exe (
    echo  venv bulunamadi. setup.bat aciliyor...
    call setup.bat
    exit /b
)

venv\Scripts\python.exe app.py
if %errorlevel% neq 0 (
    echo.
    echo  HATA: Uygulama calisamadi (kod: %errorlevel%)
    echo.
)
pause

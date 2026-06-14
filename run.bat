@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0"

REM .env yoksa kurulum
if not exist .env (
    echo  Ilk kurulum gerekli. setup.bat calistiriliyor...
    call setup.bat
    exit /b
)

REM venv yoksa kurulum
if not exist venv\Scripts\activate.bat (
    echo  venv bulunamadi. setup.bat calistiriliyor...
    call setup.bat
    exit /b
)

call venv\Scripts\activate.bat
python app.py

if %errorlevel% neq 0 (
    echo.
    echo  HATA: Uygulama calisamadi (kod: %errorlevel%)
    echo.
)
pause

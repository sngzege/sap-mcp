@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0"

REM Virtualenv varsa baslat, yoksa setup calistir
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
    python app.py
    if %errorlevel% neq 0 (
        echo.
        echo  HATA: Uygulama calisamadi (kod: %errorlevel%)
        echo.
        pause
    )
) else (
    call setup.bat
)

echo.
pause

@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0"

set VENV_PYTHON=%~dp0venv\Scripts\python.exe

if not exist "%~dp0.env" (
    echo  Ilk kurulum gerekli.
    call setup.bat
    exit /b
)

if not exist "%VENV_PYTHON%" (
    echo  venv bulunamadi. setup.bat calistiriliyor...
    call setup.bat
    exit /b
)

"%VENV_PYTHON%" "%~dp0app.py"

if errorlevel 1 (
    echo.
    echo  HATA: Uygulama calisamadi.
    echo  Hata detaylari yukarida.
    echo.
)
pause

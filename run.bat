@echo off
cd /d "%~dp0"

set "PYTHON=%~dp0python3\python.exe"
set "PATH=%~dp0python3;%~dp0python3\DLLs;%~dp0python3\Scripts;%PATH%"

if not exist "%~dp0.env" (
    echo  Ilk kurulum gerekli
    call setup.bat
    exit /b
)

if not exist "%PYTHON%" (
    echo  Python bulunamadi, setup.bat calistiriliyor...
    call setup.bat
    exit /b
)

"%PYTHON%" "%~dp0app.py"

if errorlevel 1 (
    echo.
    echo  HATA: Uygulama calisamadi
    echo.
)
pause

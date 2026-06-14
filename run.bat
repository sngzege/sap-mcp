@echo off
REM SAP Is Karti Indirici — Windows Baslatma
cd /d "%~dp0"

REM Virtualenv kontrol
if not exist venv (
    echo Virtualenv olusturuluyor...
    python -m venv venv
    call venv\Scripts\activate.bat
    pip install -q fastmcp openpyxl python-dotenv requests
) else (
    call venv\Scripts\activate.bat
)

python app.py
pause

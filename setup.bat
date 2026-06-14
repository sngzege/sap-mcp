@echo off
chcp 65001 >nul 2>&1
title SAP Is Karti Indirici — Kurulum
cd /d "%~dp0"

echo.
echo  ======================================
echo   SAP Is Karti Indirici — Kurulum
echo  ======================================
echo.

REM ════════════════════════════════════════════
REM  Adim 1: Python kontrol / indir
REM ════════════════════════════════════════════
echo  [1/5] Python kontrol ediliyor...

set PYTHON_CMD=

REM Sistemde python var mi?
python --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=python
    goto :python_found
)

REM python3 var mi?
python3 --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=python3
    goto :python_found
)

REM py launcher var mi?
py --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=py
    goto :python_found
)

REM ════════════════════════════════════════════
REM  Python yok — portatif Python indir
REM ════════════════════════════════════════════
echo  Python bulunamadi. Portatif Python indiriliyor...
echo  (Bu bir kerelik islem, ~15MB)
echo.

if not exist python (
    mkdir python
)

set PYTHON_VER=3.11.9
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VER%/python-%PYTHON_VER%-embed-amd64.zip
set PYTHON_ZIP=python\python.zip

echo  Indiriliyor: %PYTHON_URL%
echo  Lutfen bekleyin...

REM curl ile indir (Windows 10+ varsayim)
curl -L -o %PYTHON_ZIP% %PYTHON_URL% 2>nul
if %errorlevel% neq 0 (
    REM cert hatasi icin --insecure dene
    curl -L -k -o %PYTHON_ZIP% %PYTHON_URL% 2>nul
)

if not exist %PYTHON_ZIP% (
    echo.
    echo  HATA: Python indirilemedi!
    echo  Internet baglantinizi kontrol edin.
    echo  Veya python.org'dan Python indirip kurun:
    echo  https://www.python.org/downloads/
    echo  (kurulum sirasinda "Add Python to PATH" isaretleyin)
    echo.
    pause
    exit /b 1
)

echo  Aciliyor...
powershell -command "Expand-Archive -Path '%PYTHON_ZIP%' -DestinationPath 'python' -Force"
del %PYTHON_ZIP% >nul 2>&1

REM pip icin site-packages klasoru ayarla
echo import site > python\sitecustomize.py
echo site.ENABLE_USER_SITE = True >> python\sitecustomize.py

REM python path ayari — path'e ekle
set PYTHON_CMD=%~dp0python\python.exe

REM python._pth dosyasini duzenle (site-packages ac)
powershell -command "(Get-Content 'python\python._pth') -replace '#import site', 'import site' | Set-Content 'python\python._pth'"

echo  Portatif Python hazir.

:python_found
echo  Using: %PYTHON_CMD%
%PYTHON_CMD% --version

REM ════════════════════════════════════════════
REM  Adim 2: pip kontrol
REM ════════════════════════════════════════════
echo.
echo  [2/5] pip kontrol...
%PYTHON_CMD% -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  pip yukleniyor...
    %PYTHON_CMD% -m ensurepip --upgrade >nul 2>&1
    %PYTHON_CMD% -m pip install --upgrade pip -q
)

REM ════════════════════════════════════════════
REM  Adim 3: Virtualenv olustur
REM ════════════════════════════════════════════
echo.
echo  [3/5] Virtual environment...
if not exist venv (
    %PYTHON_CMD% -m venv venv
    echo  venv olusturuldu.
) else (
    echo  venv zaten mevcut.
)

call venv\Scripts\activate.bat

REM ════════════════════════════════════════════
REM  Adim 4: Bagimliliklari yukle
REM ════════════════════════════════════════════
echo.
echo  [4/5] Bagimliliklar yukleniyor...
pip install --upgrade pip -q 2>&1
pip install -r requirements.txt -q 2>&1
if %errorlevel% neq 0 (
    echo  HATA: Bagimliliklar yuklenemedi!
    pause
    exit /b 1
)

REM ════════════════════════════════════════════
REM  Adim 5: Ayarlar arayuzu
REM ════════════════════════════════════════════
echo.
echo  [5/5] Ayarlar aciliyor...
echo.
python setup_gui.py

echo.
echo  Kurulum tamamlandi!
echo  Simdi run.bat ile baslatin.
echo.
pause

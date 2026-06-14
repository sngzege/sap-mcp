@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title SAP Is Karti -- Kurulum
cd /d "%~dp0"

echo.
echo  =======================================
echo   SAP Is Karti Indirici -- Kurulum
echo  =======================================
echo.

REM -----------------------------------------------------------
REM  Step 0: Internet check
REM -----------------------------------------------------------
echo  [!] Internet kontrol...
ping -n 2 github.com >nul 2>&1
if errorlevel 1 (
    echo  HATA: Internet baglantisi yok
    pause
    exit /b 1
)
echo  Internet OK.

REM -----------------------------------------------------------
REM  Step 1: Download uv
REM -----------------------------------------------------------
echo.
echo  [1/5] uv indiriliyor...

set "TOOLS_DIR=%~dp0tools"
set "UV_EXE=%TOOLS_DIR%\uv.exe"

if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"

if not exist "%UV_EXE%" (
    echo  Indiriliyor: uv.exe (yaklasik 15 MB)

    curl -L --progress-bar -o "%UV_EXE%" "https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.exe" 2>nul
    if not exist "%UV_EXE%" (
        echo  curl basarisiz, PowerShell deneniyor...
        powershell -Command "$p='%UV_EXE%'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.exe' -OutFile $p" 2>nul
    )

    if not exist "%UV_EXE%" (
        echo.
        echo  HATA: uv.exe indirilemedi
        echo.
        echo  Elle indirmek icin:
        echo    https://github.com/astral-sh/uv/releases/latest
        echo    Dosya: uv-x86_64-pc-windows-msvc.exe
        echo    Kaydet: %TOOLS_DIR%\uv.exe
        echo    Sonra setup.bat i tekrar calistir
        echo.
        pause
        exit /b 1
    )
    echo  uv.exe indirildi
) else (
    echo  uv.exe zaten mevcut
)

REM -----------------------------------------------------------
REM  Step 2: Install Python via uv
REM -----------------------------------------------------------
echo.
echo  [2/5] Python yukleniyor...

"%UV_EXE%" python install 3.12 2>&1
if errorlevel 1 (
    REM Fallback: 3.11
    echo  3.12 basarisiz, 3.11 deneniyor...
    "%UV_EXE%" python install 3.11 2>&1
    if errorlevel 1 (
        REM Fallback: 3.10
        echo  3.11 basarisiz, 3.10 deneniyor...
        "%UV_EXE%" python install 3.10 2>&1
    )
)

REM Determine installed Python version
for /f "usebackq tokens=*" %%a in (`"%UV_EXE%" python find 3.12 2^>nul`) do set "PYTHON_EXE=%%a"
if "%PYTHON_EXE%"=="" (
    for /f "usebackq tokens=*" %%a in (`"%UV_EXE%" python find 3.11 2^>nul`) do set "PYTHON_EXE=%%a"
)
if "%PYTHON_EXE%"=="" (
    for /f "usebackq tokens=*" %%a in (`"%UV_EXE%" python find 3.10 2^>nul`) do set "PYTHON_EXE=%%a"
)
if "%PYTHON_EXE%"=="" (
    echo  HATA: Python yuklenemedi
    pause
    exit /b 1
)
echo  Python: %PYTHON_EXE%
"%PYTHON_EXE%" --version 2>nul

REM -----------------------------------------------------------
REM  Step 3: Create venv
REM -----------------------------------------------------------
echo.
echo  [3/5] Virtual environment olusturuluyor...

set "VENV_DIR=%~dp0venv"
set "VENV_PYTHON=%VENV_DIR%\Scripts\python.exe"

if not exist "%VENV_PYTHON%" (
    "%PYTHON_EXE%" -m venv "%VENV_DIR%" 2>&1
    if errorlevel 1 (
        echo  HATA: venv olusturulamadi
        pause
        exit /b 1
    )
    echo  venv olusturuldu
) else (
    echo  venv zaten mevcut
)

REM -----------------------------------------------------------
REM  Step 4: Install requirements
REM -----------------------------------------------------------
echo.
echo  [4/5] Gereklilikler yukleniyor...

set "VENV_PIP=%VENV_DIR%\Scripts\pip.exe"

"%VENV_PYTHON%" -m pip install --upgrade pip --quiet 2>&1
"%VENV_PIP%" install -r "%~dp0requirements.txt" 2>&1
if errorlevel 1 (
    echo  HATA: Gereklilikler yuklenemedi
    pause
    exit /b 1
)
echo  Gereklilikler yuklendi

REM -----------------------------------------------------------
REM  Verify imports
REM -----------------------------------------------------------
echo  Test: import kontrol...
"%VENV_PYTHON%" -c "import fastmcp, openpyxl, dotenv; print('OK')" 2>&1
if errorlevel 1 (
    echo  HATA: Gereklilikler calismiyor
    pause
    exit /b 1
)

REM -----------------------------------------------------------
REM  Step 5: Open settings GUI
REM -----------------------------------------------------------
echo.
echo  [5/5] SAP ayarlari aciliyor...
echo.
echo  Acilan pencerede SAP bilgilerini doldurun.
echo  Her alanin altinda nereden bakacaginiz yazar.
echo.

set "SETUP_GUI=%~dp0setup_gui.py"

if not exist "%SETUP_GUI%" (
    echo  HATA: setup_gui.py bulunamadi
    pause
    exit /b 1
)

"%VENV_PYTHON%" "%SETUP_GUI%"

if errorlevel 1 (
    echo  GUI acilamadi. .env manuel olusturuluyor...
    if not exist "%~dp0.env" (
        (
            echo # SAP Baglanti Ayarlari
            echo SAP_HOST=https://your-sap-server.company.com
            echo SAP_CLIENT=100
            echo SAP_ODATA_SERVICE=ZPRODORD_SRV
            echo SAP_SSO2_COOKIE=your_sapsso2_cookie_value_here
        ) > "%~dp0.env"
    )
    echo  .env dosyasi olusturuldu. Metin editor ile duzenleyin.
)

echo.
echo  =======================================
echo   KURULUM TAMAMLANDI
echo  =======================================
echo.
echo  .env dosyasini doldurduktan sonra:
echo    run.bat
echo.
pause

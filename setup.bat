@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title SAP Is Karti — Kurulum
cd /d "%~dp0"

echo.
echo  ═══════════════════════════════════════════════
echo   SAP Is Karti Indirici — Tek Seferlik Kurulum
echo  ═══════════════════════════════════════════════
echo.

REM ═══════════════════════════════════════════════════════════
REM  Adim 0: Internet test
REM ═══════════════════════════════════════════════════════════
echo  [!] Internet kontrol...
ping -n 2 github.com >nul 2>&1
if errorlevel 1 (
    echo  HATA: Internet baglantisi yok!
    echo  VPN veya proxy gerekiyorsa baglanip tekrar deneyin.
    pause
    exit /b 1
)
echo  Internet OK.

REM ═══════════════════════════════════════════════════════════
REM  Adim 1: uv indir (tek .exe, hicbir sey kurmaz)
REM ═══════════════════════════════════════════════════════════
echo.
echo  [1/5] uv indiriliyor...

set TOOLS_DIR=%~dp0tools
set UV_EXE=%TOOLS_DIR%\uv.exe

if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"

if not exist "%UV_EXE%" (
    echo  Indiriliyor: uv.exe (~15 MB, bekle...)

    REM Once curl dene
    curl -L --progress-bar -o "%UV_EXE%" "https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.exe" 2>nul
    if not exist "%UV_EXE%" (
        REM curl basarisizsa PowerShell ile dene
        echo  curl basarisiz, PowerShell ile deneniyor...
        powershell -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.exe' -OutFile '%UV_EXE%'" 2>nul
    )

    if not exist "%UV_EXE%" (
        echo.
        echo  HATA: uv.exe indirilemedi!
        echo.
        echo  Elle indirmek icin:
        echo  1. https://github.com/astral-sh/uv/releases/latest
        echo  2. uv-x86_64-pc-windows-msvc.exe yi indir
        echo  3. tools\uv.exe olarak buraya koyun:
        echo     %TOOLS_DIR%
        echo  4. setup.bat'i tekrar calistirin.
        echo.
        pause
        exit /b 1
    )
    echo  uv.exe indirildi.
) else (
    echo  uv.exe zaten mevcut.
)

REM ═══════════════════════════════════════════════════════════
REM  Adim 2: Python kur (uv yonetir, bilgisayara dokunmaz)
REM ═══════════════════════════════════════════════════════════
echo.
echo  [2/5] Python 3.11 yukleniyor (sadece bu proje icin)...

"%UV_EXE%" python install 3.11 2>&1
if errorlevel 1 (
    echo  Python indirilip kuruluyor... ilk sefer ~20 MB...
    "%UV_EXE%" python install 3.11 2>&1
    if errorlevel 1 (
        echo  HATA: Python 3.11 yuklenemedi!
        echo  Hata ciktisi yukarida.
        pause
        exit /b 1
    )
)
echo  Python 3.11 yuklendi.

REM Python path'i al
for /f "usebackq tokens=*" %%a in (`"%UV_EXE%" python find 3.11 2^>nul`) do set PYTHON311=%%a
if "%PYTHON311%"=="" (
    echo  HATA: Python path alinamadi!
    pause
    exit /b 1
)
echo  Python: %PYTHON311%
"%PYTHON311%" --version

REM ═══════════════════════════════════════════════════════════
REM  Adim 3: venv olustur
REM ═══════════════════════════════════════════════════════════
echo.
echo  [3/5] Virtual environment olusturuluyor...

set VENV_DIR=%~dp0venv
set VENV_PYTHON=%VENV_DIR%\Scripts\python.exe

if not exist "%VENV_PYTHON%" (
    "%UV_EXE%" venv "%VENV_DIR%" --python 3.11 2>&1
    if errorlevel 1 (
        REM Alternatif: dogrudan Python ile dene
        "%PYTHON311%" -m venv "%VENV_DIR%" 2>&1
    )
    if not exist "%VENV_PYTHON%" (
        echo  HATA: venv olusturulamadi!
        pause
        exit /b 1
    )
    echo  venv olusturuldu.
) else (
    echo  venv zaten mevcut.
)

REM ═══════════════════════════════════════════════════════════
REM  Adim 4: Gereklilikleri yukle
REM ═══════════════════════════════════════════════════════════
echo.
echo  [4/5] Gereklilikler yukleniyor...

set VENV_PIP=%VENV_DIR%\Scripts\pip.exe

REM once pip'i guncelle
"%VENV_PYTHON%" -m pip install --upgrade pip --quiet 2>&1 | findstr /V /C:"Requirement already"

REM requirements.txt yukle
"%VENV_PIP%" install -r "%~dp0requirements.txt" --quiet 2>&1
if errorlevel 1 (
    REM Hata detayini goster
    "%VENV_PIP%" install -r "%~dp0requirements.txt" 2>&1
    echo  HATA: Gereklilikler yuklenemedi!
    pause
    exit /b 1
)
echo  Gereklilikler yuklendi.

REM Test: fastmcp import
echo  Test: import kontrol...
"%VENV_PYTHON%" -c "import fastmcp, openpyxl, dotenv; print('  Import OK')" 2>&1
if errorlevel 1 (
    "%VENV_PYTHON%" -c "import fastmcp, openpyxl, dotenv" 2>&1
    echo  HATA: Gereklilikler calismiyor!
    pause
    exit /b 1
)

REM ═══════════════════════════════════════════════════════════
REM  Adim 5: .env ayarlari
REM ═══════════════════════════════════════════════════════════
echo.
echo  [5/5] SAP ayarlari aciliyor...
echo.
echo  Lutfen acilan pencerede SAP bilgilerini eksiksiz doldurun.
echo  Her alanin altinda "NEREDEN BAKACAGINIZ" yazar.
echo.

set SETUP_GUI=%~dp0setup_gui.py

if not exist "%SETUP_GUI%" (
    echo  HATA: setup_gui.py bulunamadi!
    pause
    exit /b 1
)

"%VENV_PYTHON%" "%SETUP_GUI%"

if errorlevel 1 (
    REM GUI acilamadi — .env manuel olustur
    echo  GUI acilamadi. Manuel .env olusturuluyor...
    "%VENV_PYTHON%" "%SETUP_GUI%" 2>&1
    if errorlevel 1 (
        echo  Tkinter hatasi olabilir. .env manuel olusturuldu.
        if not exist "%~dp0.env" (
            (
                echo # SAP Baglanti Ayarlari - manuel duzenleyin
                echo SAP_HOST=https://your-sap-server.company.com
                echo SAP_CLIENT=100
                echo SAP_ODATA_SERVICE=ZPRODORD_SRV
                echo SAP_SSO2_COOKIE=your_sapsso2_cookie_value_here
            ) > "%~dp0.env"
        )
        echo  %~dp0.env dosyasini metin editor ile duzenleyin.
    )
)

REM ═══════════════════════════════════════════════════════════
REM  Sonuc
REM ═══════════════════════════════════════════════════════════
echo.
echo  ═══════════════════════════════════════════════
echo   KURULUM TAMAMLANDI
echo  ═══════════════════════════════════════════════
echo.
echo  Kullanim:
echo    .env yi doldurduktan sonra run.bat ile baslatin.
echo.
echo    C:\...\sap-mcp^> run.bat
echo.
pause

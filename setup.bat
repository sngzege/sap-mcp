@echo off
chcp 65001 >nul 2>&1
title SAP Is Karti Indirici — Kurulum

echo.
echo  ════════════════════════════════════════════════
echo   SAP Is Karti Indirici — Kurulum
echo  ════════════════════════════════════════════════
echo.

REM ── Adim 1: Python kontrol ──
echo  [1/4] Python kontrol ediliyor...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  HATA: Python bulunamadi!
    echo.
    echo  Indir: https://www.python.org/downloads/
    echo  Kurulum sirasinda "Add Python to PATH" isaretli olsun.
    echo.
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYVER=%%i
echo  Python %PYVER% bulundu.

REM ── Adim 2: pip kontrol ──
echo  [2/4] pip kontrol ediliyor...
python -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  pip yukleniyor...
    python -m ensurepip --upgrade >nul 2>&1
)

REM ── Adim 3: Virtualenv olustur ──
echo  [3/4] Virtual environment olusturuluyor...
if not exist venv (
    python -m venv venv
    echo  venv olusturuldu.
) else (
    echo  venv zaten mevcut.
)

REM ── Adim 4: Bagimliliklari yukle ──
echo  [4/4] Bagimliliklar yukleniyor...
call venv\Scripts\activate.bat
pip install --upgrade pip -q 2>&1
if %errorlevel% neq 0 (
    echo  HATA: pip yuklenemedi!
    pause
    exit /b 1
)
pip install -r requirements.txt -q 2>&1
if %errorlevel% neq 0 (
    echo  HATA: Bagimliliklar yuklenemedi!
    echo  pip ciktisini yukarida kontrol edin.
    pause
    exit /b 1
)

echo.
echo  ════════════════════════════════════════════════
echo   Kurulum tamamlandi!
echo  ════════════════════════════════════════════════
echo.

REM ── .env kontrol ──
if not exist .env (
    echo  .env dosyasi bulunamadi! Ornek olusturuluyor...
    (
        echo # SAP Baglanti Ayarlari
        echo SAP_HOST=https://your-sap-server.company.com
        echo SAP_CLIENT=100
        echo SAP_ODATA_SERVICE=ZPRODORD_SRV
        echo SAP_SSO2_COOKIE=your_sapsso2_cookie_value_here
    ) > .env
    echo  .env olusturuldu — duzenlemek icin ac: notepad .env
    echo.
)

REM ── Baslat ──
echo  Uygulama baslatiliyor...
echo.
python app.py
if %errorlevel% neq 0 (
    echo.
    echo  HATA: Uygulama calisamadi (kod: %errorlevel%)
    echo  Hata ayrintilari yukarida.
    echo.
)
pause

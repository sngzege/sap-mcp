@echo off
chcp 65001 >nul 2>&1
title SAP Is Karti — Kurulum
cd /d "%~dp0"

echo.
echo  ======================================
echo   SAP Is Karti Indirici - Kurulum
echo  ======================================
echo.

REM ════════════════════════════════════════════
REM  Adim 1: uv indir (tek dosya, Python yoneticisi)
REM ════════════════════════════════════════════
set UV=%~dp0tools\uv.exe
if not exist tools mkdir tools

if not exist "%UV%" (
    echo  [1/5] uv indiriliyor...
    curl -L -o "%UV%" "https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.exe" 2>nul
    if not exist "%UV%" (
        echo  HATA: uv indirilemedi! Internet baglantinizi kontrol edin.
        pause
        exit /b 1
    )
    echo  uv indirildi.
) else (
    echo  [1/5] uv zaten mevcut.
)

REM ════════════════════════════════════════════
REM  Adim 2: Python kur (sadece bu proje icin)
REM ════════════════════════════════════════════
echo.
echo  [2/5] Python 3.11 kuruluyor (proje ici)...
"%UV%" python install 3.11 --quiet 2>&1
if %errorlevel% neq 0 (
    echo  HATA: Python kurulamadi!
    pause
    exit /b 1
)

REM ════════════════════════════════════════════
REM  Adim 3: venv olustur
REM ════════════════════════════════════════════
echo.
echo  [3/5] Virtual environment olusturuluyor...
if not exist venv\Scripts\python.exe (
    "%UV%" venv venv --python 3.11 --quiet 2>&1
    if %errorlevel% neq 0 (
        echo  HATA: venv olusturulamadi!
        pause
        exit /b 1
    )
    echo  venv olusturuldu.
) else (
    echo  venv zaten mevcut.
)

REM ════════════════════════════════════════════
REM  Adim 4: Bagimliliklari yukle
REM ════════════════════════════════════════════
echo.
echo  [4/5] Bagimliliklar yukleniyor...
"%UV%" pip install -r requirements.txt --python venv --quiet 2>&1
if %errorlevel% neq 0 (
    echo  HATA: Bagimliliklar yuklenemedi!
    pause
    exit /b 1
)
echo  Bagimliliklar yuklendi.

REM ════════════════════════════════════════════
REM  Adim 5: Ayarlar arayuzu
REM ════════════════════════════════════════════
echo.
echo  [5/5] Ayarlar aciliyor...
echo.
venv\Scripts\python.exe setup_gui.py

echo.
echo  ======================================
echo   Kurulum tamamlandi!
echo   Artik run.bat ile baslatabilirsiniz.
echo  ======================================
echo.
pause

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
REM  Python: repodaki portatif Python'u kullan
REM ════════════════════════════════════════════
set PYEXE=%~dp0python\python.exe

if not exist "%PYEXE%" (
    echo  HATA: python\python.exe bulunamadi!
    echo  Repoyu dogru kladonladiginizdan emin olun.
    echo.
    pause
    exit /b 1
)

echo  [1/5] Portatif Python kullaniliyor...
"%PYEXE%" --version

REM ════════════════════════════════════════════
REM  pip: yoksa yukle
REM ════════════════════════════════════════════
echo.
echo  [2/5] pip kontrol...
"%PYEXE%" -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  pip yukleniyor...
    "%PYEXE%" get-pip.py -q 2>&1
    if %errorlevel% neq 0 (
        echo  HATA: pip yuklenemedi!
        pause
        exit /b 1
    )
    echo  pip yuklendi.
) else (
    echo  pip zaten mevcut.
)

REM ════════════════════════════════════════════
REM  Virtualenv olustur
REM ════════════════════════════════════════════
echo.
echo  [3/5] Virtual environment...
if not exist venv (
    "%PYEXE%" -m venv venv
    echo  venv olusturuldu.
) else (
    echo  venv zaten mevcut.
)

call venv\Scripts\activate.bat

REM ════════════════════════════════════════════
REM  Bagimliliklari yukle
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
REM  Ayarlar arayuzu
REM ════════════════════════════════════════════
echo.
echo  [5/5] Ayarlar aciliyor...
echo.
python setup_gui.py

echo.
echo  ======================================
echo   Kurulum tamamlandi!
echo   run.bat ile baslatin.
echo  ======================================
echo.
pause

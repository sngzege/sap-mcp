# SAP Is Karti -- Kurulum (PowerShell + NuGet Python)
# SIFIR admin yetkisi - .nupkg = .zip, extract eder
# tkinter, pip ve tum kutuphaneler dahil

$ErrorActionPreference = "Continue"
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  ======================================="
Write-Host "   SAP Is Karti Indirici -- Kurulum"
Write-Host "  ======================================="
Write-Host ""

# ── 0. Architecture ──
$is64 = [Environment]::Is64BitOperatingSystem
if ($is64) {
    $ARCH = "amd64"
    $NUGET_PKG = "python"
} else {
    $ARCH = "x86"
    $NUGET_PKG = "pythonx86"
}
Write-Host "  Sistem: $(if($is64){'64-bit'}else{'32-bit'})"

# ── 1. Download NuGet Python package ──
Write-Host ""
Write-Host "  [1/5] Python indiriliyor (admin yetkisi gerekmez)..."

$PY_DIR = Join-Path $ROOT "python3"
$PYTHON = Join-Path $PY_DIR "python.exe"
$VER = "3.10.11"

if (Test-Path $PYTHON) {
    Write-Host "  Python zaten mevcut."
    & $PYTHON --version
} else {
    $pkgUrl = "https://www.nuget.org/api/v2/package/$NUGET_PKG/$VER"
    $zipFile = Join-Path $env:TEMP "python-pkg.zip"

    Write-Host "  Indiriliyor..."
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $pkgUrl -OutFile $zipFile -ErrorAction Stop
        Write-Host "  Indirildi."
    } catch {
        Write-Host "  HATA: Python indirilemedi!" -ForegroundColor Red
        Write-Host "  Internet baglantinizi kontrol edin."
        Read-Host "  Enter'a basin"
        exit 1
    }

    # Extract (nupkg is just a zip)
    Write-Host "  Cikartiliyor..."
    $tmpDir = Join-Path $env:TEMP "python-extract"
    if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
    Expand-Archive -Path $zipFile -DestinationPath $tmpDir -Force
    Remove-Item $zipFile -Force

    # NuGet yapisi: tools/ icinde python var
    $toolsDir = Join-Path $tmpDir "tools"
    if (-not (Test-Path $toolsDir)) {
        Write-Host "  HATA: NuGet paket yapisi beklenmedik!" -ForegroundColor Red
        Read-Host "  Enter'a basin"
        exit 1
    }

    # Tasi
    if (Test-Path $PY_DIR) { Remove-Item -Recurse -Force $PY_DIR }
    Move-Item -Path $toolsDir -Destination $PY_DIR -Force
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue

    if (-not (Test-Path $PYTHON)) {
        Write-Host "  HATA: python.exe bulunamadi!" -ForegroundColor Red
        Write-Host "  $PY_DIR icerigi:"
        Get-ChildItem $PY_DIR | Select-Object Name
        Read-Host "  Enter'a basin"
        exit 1
    }

    Write-Host "  Python hazir."
    & $PYTHON --version
}

# ── 2. Configure PATH so it finds its own DLLs ──
Write-Host ""
Write-Host "  [2/5] Python yapilandiriliyor..."

# Python'un kendi DLLs klasorunu PATH'e ekle
$dllsDir = Join-Path $PY_DIR "DLLs"
if (Test-Path $dllsDir) {
    $env:PATH = "$PY_DIR;$dllsDir;$PY_DIR\Scripts;" + $env:PATH
}

# pip varsa yukselt
& $PYTHON -m pip --version 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    # ensurepip
    & $PYTHON -m ensurepip --upgrade 2>&1
}
& $PYTHON -m pip install --upgrade pip --quiet 2>&1
Write-Host "  pip hazir."

# ── 3. Install requirements ──
Write-Host ""
Write-Host "  [3/5] Gereklilikler yukleniyor..."

$reqFile = Join-Path $ROOT "requirements.txt"
if (-not (Test-Path $reqFile)) {
    Write-Host "  HATA: requirements.txt bulunamadi!" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}

& $PYTHON -m pip install -r $reqFile 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "  HATA: Gereklilikler yuklenemedi!" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}
Write-Host "  Gereklilikler yuklendi."

# ── 4. Verify ──
Write-Host ""
Write-Host "  [4/5] Kontroller..."

$tkResult = & $PYTHON -c "import tkinter; print('tkinter OK')" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  UYARI: tkinter: $tkResult" -ForegroundColor Yellow
} else {
    Write-Host "  tkinter: OK"
}

$impResult = & $PYTHON -c "import fastmcp, openpyxl, dotenv, requests; print('import OK')" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  HATA: $impResult" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}
Write-Host "  fastmcp, openpyxl, dotenv, requests: OK"

# ── 5. Setup GUI ──
Write-Host ""
Write-Host "  [5/5] SAP ayarlari aciliyor..."
Write-Host ""

$setupGui = Join-Path $ROOT "setup_gui.py"
if (Test-Path $setupGui) {
    Write-Host "  Her alanin altinda nereden bakacaginiz yazar."
    Write-Host ""
    & $PYTHON $setupGui

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  GUI acilamadi. .env manuel olusturuluyor..."
        $envFile = Join-Path $ROOT ".env"
        if (-not (Test-Path $envFile)) {
            @"
# SAP Baglanti Ayarlari
SAP_HOST=https://your-sap-server.company.com
SAP_CLIENT=100
SAP_ODATA_SERVICE=ZPRODORD_SRV
SAP_SSO2_COOKIE=your_sapsso2_cookie_value_here
"@ | Set-Content -Path $envFile -Encoding UTF8
        }
        Write-Host "  .env olusturuldu. Elle duzenleyin."
    }
} else {
    Write-Host "  HATA: setup_gui.py bulunamadi!" -ForegroundColor Red
}

Write-Host ""
Write-Host "  ======================================="
Write-Host "   KURULUM TAMAMLANDI"
Write-Host "  ======================================="
Write-Host ""
Write-Host "  .env doldur -> run.bat"
Write-Host ""
Read-Host "  Enter'a basin"

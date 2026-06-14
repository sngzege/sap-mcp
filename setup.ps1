# SAP Is Karti — Tam Kurulum (PowerShell)
# Bu script her seyi yapar: pip kurar, venv olusturur, bagimliliklari yukler, ayarlar acar.

$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$PY = Join-Path $ROOT "python\python.exe"

Write-Host ""
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host "   SAP Is Karti — Kurulum" -ForegroundColor Cyan
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Python kontrol ──
Write-Host "  [1/5] Python kontrol..." -ForegroundColor Yellow
if (-not (Test-Path $PY)) {
    Write-Host "  HATA: python\python.exe bulunamadi!" -ForegroundColor Red
    Write-Host "  Repoyu dogru klasore klonladiginizdan emin olun."
    Read-Host "  Enter'a basin"
    exit 1
}
& $PY --version
Write-Host ""

# ── 2. pip kur ──
Write-Host "  [2/5] pip kuruluyor..." -ForegroundColor Yellow
$pipCheck = & $PY -m pip --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  pip yukleniyor (get-pip.py)..."
    $getpip = Join-Path $ROOT "python\get-pip.py"
    & $PY $getpip --no-warn-script-location 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  HATA: pip kurulamadi!" -ForegroundColor Red
        Read-Host "  Enter'a basin"
        exit 1
    }
    Write-Host "  pip kuruldu." -ForegroundColor Green
} else {
    Write-Host "  pip zaten var." -ForegroundColor Green
}
Write-Host ""

# ── 3. venv olustur ──
Write-Host "  [3/5] Virtual environment..." -ForegroundColor Yellow
$venv = Join-Path $ROOT "venv"
$venvPy = Join-Path $venv "Scripts\python.exe"
if (-not (Test-Path $venvPy)) {
    & $PY -m venv $venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  HATA: venv olusturulamadi!" -ForegroundColor Red
        Read-Host "  Enter'a basin"
        exit 1
    }
    Write-Host "  venv olusturuldu." -ForegroundColor Green
} else {
    Write-Host "  venv zaten var." -ForegroundColor Green
}
Write-Host ""

# ── 4. Bagimliliklari yukle ──
Write-Host "  [4/5] Bagimliliklar yukleniyor..." -ForegroundColor Yellow
$pipExe = Join-Path $venv "Scripts\pip.exe"
& $pipExe install --upgrade pip --quiet 2>&1 | Out-Null
& $pipExe install -r (Join-Path $ROOT "requirements.txt") --quiet 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  HATA: Bagimliliklar yuklenemedi!" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}
Write-Host "  Bagimliliklar yuklendi." -ForegroundColor Green
Write-Host ""

# ── 5. .env ayarlari ──
Write-Host "  [5/5] Ayarlar aciliyor..." -ForegroundColor Yellow
$envFile = Join-Path $ROOT ".env"
if (-not (Test-Path $envFile)) {
    Set-Content -Path $envFile -Value @(
        "# SAP Baglanti Ayarlari"
        "SAP_HOST=https://your-sap-server.company.com"
        "SAP_CLIENT=100"
        "SAP_ODATA_SERVICE=ZPRODORD_SRV"
        "SAP_SSO2_COOKIE=your_sapsso2_cookie_value_here"
    ) -Encoding UTF8
}

$guiPy = Join-Path $venv "Scripts\python.exe"
& $guiPy (Join-Path $ROOT "setup_gui.py")

Write-Host ""
Write-Host "  ======================================" -ForegroundColor Green
Write-Host "   Kurulum tamamlandi!" -ForegroundColor Green
Write-Host "   run.bat ile baslatin." -ForegroundColor Green
Write-Host "  ======================================" -ForegroundColor Green
Write-Host ""
Read-Host "  Enter'a basin"

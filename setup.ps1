# SAP Is Karti -- Tam Kurulum (PowerShell + Embedded Python)
# Windows 7/8/10/11 uyumlu, 32-bit ve 64-bit

$ErrorActionPreference = "Continue"
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  ======================================="
Write-Host "   SAP Is Karti Indirici -- Kurulum"
Write-Host "  ======================================="
Write-Host ""

# ── 0. Architecture detect ──
$is64 = [Environment]::Is64BitOperatingSystem
if ($is64) {
    $ARCH = "amd64"
    Write-Host "  Sistem: 64-bit"
} else {
    $ARCH = "win32"
    Write-Host "  Sistem: 32-bit"
}

# ── 1. Download embedded Python ──
Write-Host ""
Write-Host "  [1/5] Python indiriliyor..."

$PY_DIR = Join-Path $ROOT "python3"
$PY_ZIP = Join-Path $ROOT "python.zip"
$PYTHON = Join-Path $PY_DIR "python.exe"

if (Test-Path $PYTHON) {
    Write-Host "  Python zaten mevcut: $PYTHON"
} else {
    $ver = "3.10.11"
    $url = "https://www.python.org/ftp/python/$ver/python-$ver-embed-$ARCH.zip"

    Write-Host "  Indirme: $url"
    
    # Download
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $PY_ZIP -ErrorAction Stop
        Write-Host "  Indirildi."
    } catch {
        Write-Host "  HATA: Python indirilemedi: $_" -ForegroundColor Red
        Write-Host "  Elle indir: $url"
        Write-Host "  Cikart: $PY_DIR"
        Read-Host "  Enter'a basin"
        exit 1
    }

    # Extract
    if (Test-Path $PY_DIR) { Remove-Item -Recurse -Force $PY_DIR }
    Expand-Archive -Path $PY_ZIP -DestinationPath $PY_DIR -Force
    Remove-Item $PY_ZIP -Force

    Write-Host "  Python cikartildi: $PY_DIR"
}

# ── 2. Configure embedded Python for pip ──
Write-Host ""
Write-Host "  [2/5] Python yapilandiriliyor..."

# Find ._pth file
$pthFile = Get-ChildItem -Path $PY_DIR -Filter "python*._pth" | Select-Object -First 1
if (-not $pthFile) {
    Write-Host "  HATA: ._pth dosyasi bulunamadi!" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}

# Edit ._pth: uncomment import site, add Lib/site-packages
$pthContent = Get-Content $pthFile.FullName -Raw
$pthContent = $pthContent -replace "#import site", "import site"
if ($pthContent -notmatch "Lib/site-packages") {
    $pthContent = $pthContent -replace "(\r?\n\.\r?\n)", "`$1Lib/site-packages`r`n"
}
Set-Content -Path $pthFile.FullName -Value $pthContent -NoNewline
Write-Host "  ._pth yapilandirildi."

# Create Lib/site-packages
$sitePackages = Join-Path $PY_DIR "Lib\site-packages"
if (-not (Test-Path $sitePackages)) {
    New-Item -ItemType Directory -Path $sitePackages -Force | Out-Null
}

# ── 3. Install pip ──
Write-Host ""
Write-Host "  [3/5] pip yukleniyor..."

# Check if pip already exists
$pipCheck = & $PYTHON -m pip --version 2>&1
if ($LASTEXITCODE -ne 0) {
    # Download get-pip.py
    $getpip = Join-Path $ROOT "get-pip.py"
    try {
        Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile $getpip -ErrorAction Stop
    } catch {
        Write-Host "  HATA: get-pip.py indirilemedi" -ForegroundColor Red
        Read-Host "  Enter'a basin"
        exit 1
    }

    & $PYTHON $getpip --no-warn-script-location 2>&1
    Remove-Item $getpip -Force

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  HATA: pip yuklenemedi!" -ForegroundColor Red
        Write-Host "  Yukaridaki hata ciktisini okuyun."
        Read-Host "  Enter'a basin"
        exit 1
    }
    Write-Host "  pip yuklendi."
} else {
    Write-Host "  pip zaten mevcut."
}

# Verify pip works
& $PYTHON -m pip --version 2>&1

# ── 4. Install packages ──
Write-Host ""
Write-Host "  [4/5] Gereklilikler yukleniyor..."

$reqFile = Join-Path $ROOT "requirements.txt"
if (-not (Test-Path $reqFile)) {
    Write-Host "  HATA: requirements.txt bulunamadi!" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}

# Install directly to the embedded Python (no venv needed)
& $PYTHON -m pip install --upgrade pip --quiet 2>&1
& $PYTHON -m pip install -r $reqFile 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "  HATA: Gereklilikler yuklenemedi!" -ForegroundColor Red
    Write-Host "  Yukaridaki hata ciktisini okuyun."
    Read-Host "  Enter'a basin"
    exit 1
}
Write-Host "  Gereklilikler yuklendi."

# Verify
Write-Host "  Test: import kontrol..."
$testResult = & $PYTHON -c "import fastmcp; import openpyxl; import dotenv; print('OK')" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  HATA: Import basarisiz!" -ForegroundColor Red
    Write-Host "  $testResult"
    Read-Host "  Enter'a basin"
    exit 1
}
Write-Host "  Import OK: fastmcp, openpyxl, dotenv"

# ── 5. Setup GUI ──
Write-Host ""
Write-Host "  [5/5] SAP ayarlari aciliyor..."
Write-Host ""
Write-Host "  Acilan pencerede SAP bilgilerini doldurun."
Write-Host "  Her alanin altinda nereden bakacaginiz yazar."
Write-Host ""

$setupGui = Join-Path $ROOT "setup_gui.py"
if (-not (Test-Path $setupGui)) {
    Write-Host "  HATA: setup_gui.py bulunamadi!" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}

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
    Write-Host "  .env olusturuldu. Metin editor ile duzenleyin."
}

Write-Host ""
Write-Host "  ======================================="
Write-Host "   KURULUM TAMAMLANDI"
Write-Host "  ======================================="
Write-Host ""
Write-Host "  .env dosyasini doldurduktan sonra:"
Write-Host "    run.bat"
Write-Host ""
Read-Host "  Enter'a basin"

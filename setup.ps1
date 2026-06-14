# SAP Is Karti -- Kurulum (PowerShell + Tam Python)
# Windows 7/8/10/11, 32/64 bit, admin yetkisi gerektirmez
# tkinter dahil tam kurulum

$ErrorActionPreference = "Continue"
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  ======================================="
Write-Host "   SAP Is Karti Indirici -- Kurulum"
Write-Host "  ======================================="
Write-Host ""

# ── 0. Architecture ──
$is64 = [Environment]::Is64BitOperatingSystem
if ($is64) { $ARCH = "amd64" } else { $ARCH = "win32" }
Write-Host "  Sistem: $(if($is64){'64-bit'}else{'32-bit'})"

# ── 1. Download Python installer ──
Write-Host ""
Write-Host "  [1/5] Python indiriliyor..."

$PY_DIR = Join-Path $ROOT "python3"
$PYTHON = Join-Path $PY_DIR "python.exe"
$VER = "3.10.11"

if (Test-Path $PYTHON) {
    Write-Host "  Python zaten mevcut."
    & $PYTHON --version
} else {
    $installer = Join-Path $env:TEMP "python-installer.exe"
    $url = "https://www.python.org/ftp/python/$VER/python-$VER-$ARCH.exe"

    Write-Host "  Indiriliyor ($url)..."
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $installer -ErrorAction Stop
        Write-Host "  Indirildi."
    } catch {
        Write-Host "  HATA: Python indirilemedi!" -ForegroundColor Red
        Write-Host "  URL: $url"
        Write-Host "  Elle indirip calistirin, TargetDir olarak $PY_DIR secin."
        Read-Host "  Enter'a basin"
        exit 1
    }

    # Silent install to local folder
    Write-Host "  Kuruluyor (yönetici yetkisi gerekmez)..."
    $args = "/quiet InstallAllUsers=0 PrependPath=0 Include_test=0 TargetDir=""$PY_DIR"""
    $proc = Start-Process -FilePath $installer -ArgumentList $args -Wait -PassThru -NoNewWindow

    Remove-Item $installer -Force -ErrorAction SilentlyContinue

    if (-not (Test-Path $PYTHON)) {
        Write-Host "  HATA: Python kurulamadi!" -ForegroundColor Red
        Write-Host "  Elle kur: $url -> TargetDir = $PY_DIR"
        Read-Host "  Enter'a basin"
        exit 1
    }
    Write-Host "  Python kuruldu."
    & $PYTHON --version
}

# ── 2. Upgrade pip ──
Write-Host ""
Write-Host "  [2/5] pip guncelleniyor..."
& $PYTHON -m pip install --upgrade pip --quiet
Write-Host "  pip guncel."

# ── 3. Install requirements ──
Write-Host ""
Write-Host "  [3/5] Gereklilikler yukleniyor..."

$reqFile = Join-Path $ROOT "requirements.txt"
if (-not (Test-Path $reqFile)) {
    Write-Host "  HATA: requirements.txt bulunamadi!" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}

& $PYTHON -m pip install -r $reqFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "  HATA: Gereklilikler yuklenemedi!" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}
Write-Host "  Gereklilikler yuklendi."

# ── 4. Verify ──
Write-Host ""
Write-Host "  [4/5] Kontroller yapiliyor..."

# Check tkinter
$tkResult = & $PYTHON -c "import tkinter; print('tkinter OK')" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  UYARI: tkinter calismiyor olabilir: $tkResult" -ForegroundColor Yellow
} else {
    Write-Host "  tkinter: OK"
}

# Check other imports
$impResult = & $PYTHON -c "import fastmcp, openpyxl, dotenv, requests; print('import OK')" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  HATA: Import basarisiz: $impResult" -ForegroundColor Red
    Read-Host "  Enter'a basin"
    exit 1
}
Write-Host "  fastmcp, openpyxl, dotenv: OK"

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
    Write-Host "  .env elle olusturuluyor..."
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
}

Write-Host ""
Write-Host "  ======================================="
Write-Host "   KURULUM TAMAMLANDI"
Write-Host "  ======================================="
Write-Host ""
Write-Host "  .env doldurduktan sonra: run.bat"
Write-Host ""
Read-Host "  Enter'a basin"

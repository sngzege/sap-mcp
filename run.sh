#!/bin/bash
# SAP Is Karti Indirici — Linux/Mac
set -e
cd "$(dirname "$0")"

# Python kontrol
if ! command -v python3 &>/dev/null; then
    echo "HATA: Python3 bulunamadi."
    echo "  Ubuntu/Debian: sudo apt install python3 python3-venv"
    echo "  Mac: brew install python3"
    exit 1
fi

# Virtualenv
if [ ! -d venv ]; then
    echo "[1/3] Virtual environment olusturuluyor..."
    python3 -m venv venv
fi

source venv/bin/activate

# Bagimliliklar
if [ ! -f venv/.installed ]; then
    echo "[2/3] Bagimliliklar yukleniyor..."
    pip install -q --upgrade pip
    pip install -q -r requirements.txt
    touch venv/.installed
else
    echo "[2/3] Bagimliliklar yuklu."
fi

# .env kontrol
if [ ! -f .env ]; then
    cat > .env << 'EOF'
SAP_HOST=https://your-sap-server.company.com
SAP_CLIENT=100
SAP_ODATA_SERVICE=ZPRODORD_SRV
SAP_SSO2_COOKIE=your_sapsso2_cookie_value_here
EOF
    echo ".env olusturuldu — duzenle: nano .env"
fi

# Baslat
echo "[3/3] Uygulama baslatiliyor..."
python3 app.py

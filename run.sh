#!/bin/bash
# SAP Is Karti Indirici — Linux/Mac Baslatma
set -e
cd "$(dirname "$0")"

if [ ! -d venv ]; then
    echo "Virtualenv olusturuluyor..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -q fastmcp openpyxl python-dotenv requests
else
    source venv/bin/activate
fi

python3 app.py

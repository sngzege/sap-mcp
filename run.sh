#!/bin/bash
set -e
cd "$(dirname "$0")"

if [ ! -f .env ]; then
    echo "Once setup gerekli."
    echo "  Windows: setup.bat"
    echo "  Linux:   python3 setup_gui.py"
    exit 1
fi

if [ ! -f venv/bin/python3 ]; then
    if command -v uv &>/dev/null; then
        uv venv venv --python 3.11
        uv pip install -r requirements.txt --python venv
    else
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
    fi
fi

source venv/bin/activate 2>/dev/null || true
python3 app.py

# SAP Is Karti Indirici

Excel C sutunundaki siparis numaralarini SAP'de aratir, is karti PDF'lerini toplu olarak indirir.

## Kurulum

### Windows

```cmd
git clone https://github.com/sngzege/sap-mcp-tools.git
cd sap-mcp-tools
double-click run.bat
```

Ilk calistirmada otomatik olarak venv olusturur ve bagimliliklari yukler.

Veya PowerShell/ CMD:
```cmd
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

### Linux / Mac

```bash
git clone https://github.com/snggege/sap-mcp-tools.git
cd sap-mcp-tools
chmod +x run.sh
./run.sh
```

## .env Ayarlari

`.env` dosyasinda su degerleri doldurun:

| Alan | Aciklama | Ornek |
|------|----------|-------|
| `SAP_HOST` | SAP sunucu URL | `https://sap.company.com` |
| `SAP_CLIENT` | SAP client | `100` |
| `SAP_TOKEN` | Bearer token | `eyJhbGciOi...` |
| `SAP_ODATA_SERVICE` | OData servis adi | `ZPRODORD_SRV` |
| `SAP_SMARTFORM` | Is karti formu | `Z_IS_KARTI` |
| `SAP_DOC_TYPE` | Dokuman tipi | `ZJC` |

## Token Nereden Alinir?

1. SAP Web GUI'ye giris yapin
2. Browser DevTools → Network
3. Herhangi bir istekte `Authorization: Bearer ***` header'ini kopyalayin

veya

1. SAP BTP Cockpit → API Access
2. Token olusturun

## Kullanim

1. Excel sec → C sutunundaki degerler listelenir
2. Kaydet klasoru sec
3. INDIR'e basin
4. Her siparis icin SAP'den is karti PDF indirilir

## Dosya Yapisi

```
sap-mcp-tools/
├── app.py           # GUI (main)
├── sap_server.py    # SAP MCP Server (FastMCP)
├── .env             # SAP ayarlari (token dahil)
├── run.bat          # Windows baslatma
├── run.sh           # Linux/Mac baslatma
├── requirements.txt
├── README.md
└── downloads/       # Varsayilan indirme klasoru
```

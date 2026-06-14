# SAP Is Karti Indirici

Excel C sutunundaki siparis numaralarini SAP'de aratir, is karti PDF'lerini toplu indirir.

## Windows Kurulumu

```cmd
git clone https://github.com/sngzege/sap-mcp.git
cd sap-mcp
setup.bat
```

Setup otomatik yapar:
1. `uv` indirir (tek dosya, Python yoneticisi, ~15MB)
2. Python 3.11 kurar (sadece bu proje, bilgisayara kurulmaz)
3. venv olusturur
4. Bagimliliklari yukler
5. Ayarlar arayuzunu acar (SAP bilgileri girilir)

Sonrasinda: `run.bat`

## Ayarlar

| Parametre | Nereden bakilir |
|-----------|-----------------|
| SAP Host URL | Tarayicida SAP'ye gir, adres cubugunu kopyala |
| SAP Client | SAP login ekraninda client numarasi |
| OData Servis | SAP IT'ye sor |
| SAPSSO2 Cookie | F12 → Application → Cookies → SAPSSO2 |

## Dosyalar

```
sap-mcp/
├── setup.bat         ← Kurulum (tek tikla)
├── run.bat           ← Uygulama baslat
├── setup_gui.py      ← Ayarlar arayuzu
├── app.py            ← Ana uygulama
├── sap_server.py     ← SAP MCP Server
├── requirements.txt
└── README.md
```

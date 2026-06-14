# SAP Is Karti Indirici

Excel C sutunundaki siparis numaralarini SAP'de aratir, is karti PDF'lerini toplu olarak indirir.

## Windows Kurulumu (Sirket PC)

```cmd
git clone https://github.com/sngzege/sap-mcp.git
cd sap-mcp
setup.bat
```

Tek tikla kurulum:
1. Portatif Python 3.11 (repo icinde, kurulum gerektirmez)
2. pip + bagimliliklar
3. Ayarlar arayuzu acilir (SAP bilgileri girilir)

Sonrasinda: `run.bat` ile baslatin.

## Ayarlar

| Parametre | Nereden bakilir |
|-----------|-----------------|
| SAP Host URL | Tarayicida SAP'ye gir, adres cubugunu kopyala |
| SAP Client | SAP login ekraninda client numarasi (100, 200 vb.) |
| OData Servis | SAP IT'ye sor: "Production order OData service name?" |
| SAPSSO2 Cookie | F12 → Application → Cookies → SAPSSO2 degeri |

## Dosyalar

```
sap-mcp/
├── python/         ← Portatif Python 3.11 (repo icinde)
├── setup.bat       ← Kurulum (calistir)
├── setup.ps1       ← Kurulum scripti
├── run.bat         ← Uygulamayi baslat
├── setup_gui.py    ← Ayarlar arayuzu
├── app.py          ← Ana uygulama
├── sap_server.py   ← SAP MCP Server
├── requirements.txt
└── README.md
```

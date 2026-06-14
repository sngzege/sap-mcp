# SAP Is Karti Indirici

Excel C sutunundaki siparis numaralarini SAP'de aratir, is karti PDF'lerini toplu olarak indirir.

## Windows Kurulumu (Sirket PC)

```cmd
git clone https://github.com/sngzege/sap-mcp.git
cd sap-mcp
setup.bat
```

Setup otomatik olarak:
1. Python bulur veya portatif Python indirir (~15MB, bilgisayara kurulum yapmaz)
2. Virtual environment olusturur
3. Gereklilikleri yukler
4. Ayarlar arayuzunu acar

Ayarlar arayuzunde 4 parametre doldurulur:

| Parametre | Nereden bakilir |
|-----------|-----------------|
| SAP Host URL | Tarayicida SAP'ye gir, adres cubugunu kopyala |
| SAP Client | SAP login ekraninda gorunen client numarasi (100, 200 vb.) |
| OData Servis | SAP IT'ye sor: "Production order OData service name?" |
| SAPSSO2 Cookie | F12 → Application → Cookies → SAPSSO2 degeri |

Ayarlar tamam `run.bat` ile baslatin.

## Linux / Mac

```bash
git clone https://github.com/sngzege/sap-mcp.git
cd sap-mcp
chmod +x run.sh
./run.sh
```

## Dosya Yapisi

```
sap-mcp/
├── setup.bat       ← Ilk kurulum (calistir)
├── run.bat         ← Uygulamayi baslat
├── setup_gui.py    ← Ayarlar arayuzu
├── app.py          ← Ana uygulama (GUI)
├── sap_server.py   ← SAP MCP Server
├── .env            ← SAP ayarlari (setup_gui ile doldurulur)
├── requirements.txt
└── README.md
```

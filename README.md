# SAP Is Karti Indirici

Excel C sutunu → SAP siparis ara → Is karti PDF toplu indir.

## Kurulum (Sirket PC, bos bilgisayar)

```cmd
git clone https://github.com/sngzege/sap-mcp.git
cd sap-mcp
setup.bat
```

Setup adimlari:
```
[1/5] uv.exe indir           (tek exe, ~15 MB, GitHub'dan)
[2/5] Python 3.11 yukle      (uv yonetir, bilgisayara dokunmaz)
[3/5] venv olustur           (repo ici)
[4/5] pip install gereklilikler  (fastmcp, openpyxl, dotenv)
[5/5] Ayarlar penceresi acar (SAP bilgileri gir)
```

Sonra: `run.bat`

## Ayarlar (.env)

Arayuzde 4 alan doldurulur — her birinin altinda nereden bakacaginiz yazar:

| Parametre | Nasil bulunur |
|-----------|---------------|
| SAP Host URL | Tarayicida SAP Web GUI'ye gir, adres cubugunu tamamen kopyala |
| SAP Client | SAP login ekraninda gorunen 3 haneli numara |
| OData Servis | SAP IT'ye sor: "Uretim siparisleri OData service name?" |
| SAPSSO2 Cookie | F12 → Application → Solda Cookies → SAPSSO2 → Value |

## Dosyalar

```
sap-mcp/
├── setup.bat         ← BUNU CALISTIR (tek seferlik)
├── run.bat           ← Uygulamayi baslat
├── setup_gui.py      ← Ayarlar penceresi
├── app.py            ← Ana GUI uygulamasi
├── sap_server.py     ← SAP MCP Server
├── requirements.txt  ← Python bagimliliklari
├── .gitignore
└── README.md
```

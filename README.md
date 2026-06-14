# SAP Is Karti Indirici

Excel C sutunu -> SAP siparis ara -> Is karti PDF toplu indir.

## Windows Kurulumu (sirket PC, bos bilgisayar)

```cmd
git clone https://github.com/sngzege/sap-mcp.git
cd sap-mcp
setup.bat
```

Setup 5 adim:
1. Embedded Python 3.10 indir (sadece repo icine, kurulum yok)
2. ._pth yapilandir + site-packages aktif
3. pip yukle
4. fastmcp + openpyxl + dotenv kur
5. Ayarlar penceresi ac (SAP bilgileri gir)

Sonra: `run.bat`

## Windows 7/8/10/11, 32-bit/64-bit uyumlu

## Ayarlar (.env)

| Parametre | Nasil bulunur |
|-----------|---------------|
| SAP Host URL | Tarayicida SAP Web GUI'ye gir, adres cubugunu kopyala |
| SAP Client | SAP login ekranindaki 3 haneli numara |
| OData Servis | SAP IT'ye sor: "Uretim siparisleri OData service name?" |
| SAPSSO2 Cookie | F12 -> Application -> Solda Cookies -> SAPSSO2 -> Value |

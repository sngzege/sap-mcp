#!/usr/bin/env python3
"""
SAP Ayarlar — Ilk kurulum arayuzu.
.env dosyasini doldurmak icin basit pencere.
"""
import os
import sys
from pathlib import Path
from tkinter import (
    Tk, Frame, Label, Entry, StringVar, Text, Button,
    messagebox, END, NORMAL, DISABLED, W, E, X, BOTH, LEFT, RIGHT, TOP, N,
)

ENV_FILE = Path(__file__).parent / ".env"

FIELDS = [
    {
        "key": "SAP_HOST",
        "label": "SAP Host URL",
        "hint": "Tarayicida SAP'ye gir, adres cubugunu kopyala\nOrnek: https://sap.company.com",
        "example": "https://mycompany-sap.com",
    },
    {
        "key": "SAP_CLIENT",
        "label": "SAP Client",
        "hint": "SAP login ekraninda gorunen client numarasi\nGenelde 100, 200, 300 gibi",
        "example": "100",
    },
    {
        "key": "SAP_ODATA_SERVICE",
        "label": "OData Servis Adi",
        "hint": "SAP IT'ye sor: 'Production order OData service name?'\nVeya SAP GUI'de SEGW ac, Z* ile baslayan servisleri gor",
        "example": "ZPRODORD_SRV",
    },
    {
        "key": "SAP_SSO2_COOKIE",
        "label": "SAPSSO2 Cookie",
        "hint": (
            "1. Tarayicida SAP Web GUI'ye gir\n"
            "2. F12 → Application → Cookies\n"
            "3. SAPSSO2 satirindaki degeri kopyala"
        ),
        "example": "eyJhbGciOiJSUz...",
    },
]


class SetupGUI:
    def __init__(self):
        self.root = Tk()
        self.root.title("SAP Is Karti — Ayarlar")
        self.root.geometry("620x580")
        self.root.resizable(False, False)

        self.entries = {}
        self._build()
        self._load_existing()

    def _build(self):
        # Baslik
        top = Frame(self.root)
        top.pack(fill=X, padx=16, pady=(12, 4))
        Label(top, text="SAP Baglanti Ayarlari", font=("Segoe UI", 14, "bold")).pack(anchor=W)
        Label(top, text=".env dosyasini doldurun, TAMAM'a basin.",
              fg="#666", font=("Segoe UI", 9)).pack(anchor=W)

        # Ayirici
        Frame(self.root, height=1, bg="#ddd").pack(fill=X, padx=16, pady=8)

        # Alanlar
        for field in FIELDS:
            self._add_field(field)

        # Butonlar
        btn = Frame(self.root)
        btn.pack(fill=X, padx=16, pady=(12, 16))
        Button(btn, text="  TAMAM  ", font=("Segoe UI", 11, "bold"),
               bg="#1d4ed8", fg="white", command=self._save).pack(side=LEFT, padx=(0, 8))
        Button(btn, text="Vazgec", command=self.root.destroy).pack(side=LEFT)

    def _add_field(self, field):
        frame = Frame(self.root)
        frame.pack(fill=X, padx=16, pady=4)

        # Label + Entry
        row = Frame(frame)
        row.pack(fill=X)
        Label(row, text=field["label"] + ":", width=18, anchor=W,
              font=("Segoe UI", 10, "bold")).pack(side=LEFT)
        entry = Entry(row, font=("Consolas", 10), width=40)
        entry.pack(side=LEFT, fill=X, expand=True)
        self.entries[field["key"]] = entry

        # Hint
        Label(frame, text=field["hint"], fg="#888", font=("Segoe UI", 8),
              justify=LEFT, anchor=W).pack(fill=X, padx=(132, 0))

    def _load_existing(self):
        if not ENV_FILE.exists():
            return
        data = {}
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                data[k.strip()] = v.strip()
        for key, entry in self.entries.items():
            val = data.get(key, "")
            if val and not val.startswith("your_"):
                entry.delete(0, END)
                entry.insert(0, val)

    def _save(self):
        values = {}
        for key, entry in self.entries.items():
            v = entry.get().strip()
            if not v:
                messagebox.showwarning("Eksik", f"{key} bos birakilamaz.")
                return
            values[key] = v

        # .env yaz
        lines = [
            "# SAP Baglanti Ayarlari — otomatik olusturuldu",
            "",
        ]
        for field in FIELDS:
            lines.append(f"{field['key']}={values[field['key']]}")
            lines.append("")

        ENV_FILE.write_text("\n".join(lines), encoding="utf-8")
        messagebox.showinfo("Kaydedildi", f".env kaydedildi.\n\nArtik run.bat ile baslatabilirsiniz.")
        self.root.destroy()

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    SetupGUI().run()

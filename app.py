#!/usr/bin/env python3
"""
SAP Is Karti Indirici
─────────────────────
Excel'den C sutununu oku, SAP'de siparis ara, is karti PDF indir.

Arayuz:
  Satir 1 — Excel dosyasi sec
  Satir 2 — Indirme klasoru sec
  Buton   — INDIR
"""

import os
import sys
import json
import asyncio
import threading
import traceback
from pathlib import Path
from datetime import datetime
from tkinter import (
    Tk, Frame, Label, Button, Entry, StringVar, Text,
    filedialog, messagebox, Scrollbar, END, NORMAL, DISABLED,
    VERTICAL, BOTH, LEFT, RIGHT, X, W, E,
)
from tkinter import ttk

# ─── Bağımlılık kontrol ──────────────────────────────────────
for pkg, mod in [("openpyxl", "openpyxl"), ("fastmcp", "fastmcp"), ("python-dotenv", "dotenv")]:
    try:
        __import__(mod)
    except ImportError:
        sys.exit(f"Eksik: {pkg}\n  pip install {pkg}")

import openpyxl

# ═══════════════════════════════════════════════════════════════
#  Excel Okuyucu
# ═══════════════════════════════════════════════════════════════

def excel_column_c(filepath: str) -> dict:
    """Excel'den C sutunundaki unique degerleri dondur."""
    try:
        wb = openpyxl.load_workbook(filepath, read_only=True, data_only=True)
        ws = wb.active
        raw = []
        for row in ws.iter_rows(min_col=3, max_col=3, min_row=2, values_only=True):
            v = row[0]
            if v is not None:
                s = str(v).strip()
                if s:
                    raw.append(s)
        wb.close()

        seen = set()
        unique = []
        for v in raw:
            if v not in seen:
                seen.add(v)
                unique.append(v)

        return {"ok": True, "count": len(unique), "unique": unique, "sheet": ws.title}
    except Exception as e:
        return {"ok": False, "error": str(e)}


# ═══════════════════════════════════════════════════════════════
#  MCP Baglanti Yardimcisi
# ═══════════════════════════════════════════════════════════════

MCP_SERVER = str(Path(__file__).parent / "sap_server.py")


def mcp_call(tool: str, args: dict = None):
    """MCP server'a senkron olarak tool cagir."""
    from fastmcp import Client

    async def _call():
        client = Client([sys.executable, MCP_SERVER])
        async with client:
            # connect
            await client.call_tool("connect_sap", {})
            # calistir
            result = await client.call_tool(tool, args or {})
            # cikis
            await client.call_tool("disconnect_sap", {})
            return result

    return asyncio.run(_call())


def parse_mcp_result(result) -> dict:
    """MCP tool sonucunu dict'e cevir."""
    if isinstance(result, dict):
        return result
    if hasattr(result, "content"):
        txt = result.content[0].text if result.content else "{}"
        try:
            return json.loads(txt)
        except Exception:
            return {"ok": False, "msg": txt}
    return {"ok": False, "msg": str(result)}


# ═══════════════════════════════════════════════════════════════
#  GUI
# ═══════════════════════════════════════════════════════════════

class App:
    TITLE = "SAP Is Karti Indirici"

    def __init__(self):
        self.root = Tk()
        self.root.title(self.TITLE)
        self.root.geometry("780x560")
        self.root.minsize(650, 480)

        self.excel_path = StringVar()
        self.save_dir = StringVar(value=str(Path.home() / "sap-downloads"))
        self.orders: list[str] = []
        self.running = False

        self._ui()

    # ─── Arayuz ──────────────────────────────────────────────

    def _ui(self):
        # Baslik
        top = Frame(self.root)
        top.pack(fill=X, padx=14, pady=(10, 4))
        Label(top, text=self.TITLE, font=("Helvetica", 14, "bold")).pack(side=LEFT)
        Label(top, text="v1.0", fg="#888", font=("Helvetica", 9)).pack(side=LEFT, padx=(6, 0), pady=(3, 0))

        # ── Satir 1: Excel ──
        r1 = Frame(self.root)
        r1.pack(fill=X, padx=14, pady=4)
        Label(r1, text="Excel:", width=7, anchor=W, font=("Helvetica", 10, "bold")).pack(side=LEFT)
        e1 = Entry(r1, textvariable=self.excel_path, font=("Helvetica", 10))
        e1.pack(side=LEFT, fill=X, expand=True, padx=(0, 6))
        Button(r1, text="Sec…", width=7, command=self._pick_excel).pack(side=LEFT)

        # ── Satir 2: Klasor ──
        r2 = Frame(self.root)
        r2.pack(fill=X, padx=14, pady=4)
        Label(r2, text="Kaydet:", width=7, anchor=W, font=("Helvetica", 10, "bold")).pack(side=LEFT)
        e2 = Entry(r2, textvariable=self.save_dir, font=("Helvetica", 10))
        e2.pack(side=LEFT, fill=X, expand=True, padx=(0, 6))
        Button(r2, text="Sec…", width=7, command=self._pick_dir).pack(side=LEFT)

        # ── Butonlar ──
        r3 = Frame(self.root)
        r3.pack(fill=X, padx=14, pady=(8, 4))
        self.btn_go = Button(r3, text="   INDIR   ", font=("Helvetica", 11, "bold"),
                             bg="#1d4ed8", fg="white", activebackground="#1e40af",
                             command=self._start)
        self.btn_go.pack(side=LEFT, padx=(0, 8))
        self.btn_cancel = Button(r3, text="Iptal", command=self._cancel, state=DISABLED)
        self.btn_cancel.pack(side=LEFT)

        # ── Siparis onizleme ──
        pv = Frame(self.root)
        pv.pack(fill=X, padx=14, pady=(6, 2))
        Label(pv, text="Siparis listesi (C sutunu):", anchor=W,
              font=("Helvetica", 9, "bold")).pack(anchor=W)
        self.preview = Text(pv, height=5, font=("Courier", 10),
                            state=DISABLED, bg="#fafafa", relief="solid", bd=1)
        sb = Scrollbar(pv, orient=VERTICAL, command=self.preview.yview)
        self.preview.configure(yscrollcommand=sb.set)
        self.preview.pack(side=LEFT, fill=BOTH, expand=True)
        sb.pack(side=RIGHT, fill=Y)

        # ── Durum ──
        self.status = Label(self.root, text="Excel secin → INDIR'e basin",
                           anchor=W, font=("Helvetica", 9), fg="#555", padx=14)
        self.status.pack(fill=X)

        # ── Progress ──
        self.progress = ttk.Progressbar(self.root, mode="determinate")
        self.progress.pack(fill=X, padx=14, pady=(2, 2))

        # ── Log ──
        self.log = Text(self.root, height=9, font=("Consolas", 9),
                        state=DISABLED, bg="#1a1a2e", fg="#c8c8c8",
                        insertbackground="white", relief="solid", bd=1)
        self.log.pack(fill=BOTH, expand=True, padx=14, pady=(2, 12))

    # ─── Dosya secme ─────────────────────────────────────────

    def _pick_excel(self):
        p = filedialog.askopenfilename(
            title="Excel dosyasi sec",
            filetypes=[("Excel", "*.xlsx *.xls *.xlsm"), ("Tumu", "*.*")],
        )
        if not p:
            return
        self.excel_path.set(p)
        r = excel_column_c(p)
        if not r["ok"]:
            messagebox.showerror("Hata", f"Excel okunamadi:\n{r['error']}")
            return
        self.orders = r["unique"]
        self.preview.configure(state=NORMAL)
        self.preview.delete("1.0", END)
        for i, v in enumerate(self.orders, 1):
            self.preview.insert(END, f"  {i:3d}.  {v}\n")
        self.preview.configure(state=DISABLED)
        self.status.configure(text=f"  {r['count']} siparis  |  {Path(p).name}")
        self._log(f"{Path(p).name}  →  {r['count']} unique siparis")

    def _pick_dir(self):
        d = filedialog.askdirectory(title="Indirme klasoru", initialdir=self.save_dir.get())
        if d:
            self.save_dir.set(d)

    # ─── Indirme ─────────────────────────────────────────────

    def _start(self):
        if self.running:
            return
        if not self.orders:
            messagebox.showwarning("Uyari", "Once Excel dosyasi secin.")
            return

        self.running = True
        self.btn_go.configure(state=DISABLED)
        self.btn_cancel.configure(state=NORMAL)
        self.progress["value"] = 0
        self.progress["maximum"] = len(self.orders)

        self._log(f"Baslatiliyor — {len(self.orders)} siparis → {self.save_dir.get()}")
        threading.Thread(target=self._worker, daemon=True).start()

    def _cancel(self):
        self.running = False
        self.btn_go.configure(state=NORMAL)
        self.btn_cancel.configure(state=DISABLED)
        self._log("Iptal edildi")

    def _worker(self):
        """Arka plan is parcacigi — MCP server ile SAP iletisimi."""
        try:
            from fastmcp import Client

            async def run():
                client = Client([sys.executable, MCP_SERVER])
                async with client:
                    # SAP baglantisi
                    self.root.after(0, self._log, "SAP'a baglaniliyor (token)...")
                    r = await client.call_tool("connect_sap", {})
                    res = parse_mcp_result(r)
                    if not res.get("ok"):
                        msg = res.get("msg", "Bilinmeyen hata")
                        self.root.after(0, self._log, f"  HATA: {msg}")
                        self.root.after(0, self._log, "  .env dosyasinda SAP_TOKEN ve SAP_HOST kontrol edin")
                        self.root.after(0, self._done)
                        return

                    self.root.after(0, self._log, "  Baglandi")

                    # Toplu indirme
                    save = self.save_dir.get()
                    ok_n = fail_n = 0
                    total = len(self.orders)

                    for i, no in enumerate(self.orders, 1):
                        if not self.running:
                            break

                        self.root.after(0, self._prog, i, total, no)
                        self.root.after(0, self._log, f"[{i}/{total}] {no} indiriliyor...")

                        r = await client.call_tool("download_is_karti", {
                            "siparis_no": no,
                            "save_path": save,
                        })
                        res = parse_mcp_result(r)

                        if res.get("ok"):
                            ok_n += 1
                            sz = res.get("size", 0)
                            self.root.after(0, self._log, f"  ✓ {no}  ({sz:,} byte)")
                        else:
                            fail_n += 1
                            msg = res.get("msg", "?")[:80]
                            self.root.after(0, self._log, f"  ✗ {no}  {msg}")

                    self.root.after(0, self._log, "")
                    self.root.after(0, self._log, f"Bitti: {ok_n} basarili, {fail_n} basarisiz")
                    self.root.after(0, self._log, f"Klasor: {save}")

                    await client.call_tool("disconnect_sap", {})

            asyncio.run(run())

        except Exception as e:
            self.root.after(0, self._log, f"HATA: {e}")
            self.root.after(0, self._log, traceback.format_exc())

        self.root.after(0, self._done)

    # ─── Yardimcilar ─────────────────────────────────────────

    def _prog(self, cur, tot, label=""):
        self.progress["value"] = cur
        self.status.configure(text=f"  {cur}/{tot}  —  {label}")

    def _done(self):
        self.running = False
        self.btn_go.configure(state=NORMAL)
        self.btn_cancel.configure(state=DISABLED)

    def _log(self, msg: str):
        ts = datetime.now().strftime("%H:%M:%S")
        self.log.configure(state=NORMAL)
        self.log.insert(END, f"[{ts}] {msg}\n")
        self.log.see(END)
        self.log.configure(state=DISABLED)

    def run(self):
        self.root.mainloop()


# ═══════════════════════════════════════════════════════════════
if __name__ == "__main__":
    App().run()

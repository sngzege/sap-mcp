#!/usr/bin/env python3
"""
SAP MCP Server — FastMCP stdio sunucusu.
GUI veya CLI tarafindan otomatik baslatilir.

Baglanti: SAP OData + Bearer Token
"""
import os
import sys
import json
import base64
import logging
from pathlib import Path
from typing import Optional

from fastmcp import FastMCP
import requests

# ═══════════════════════════════════════════════════════════════
#  Config — .env dosyasindan yuklenir
# ═══════════════════════════════════════════════════════════════

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")


def env(key: str, default: str = "") -> str:
    return os.environ.get(key, default)


logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger("sap-mcp")

# ═══════════════════════════════════════════════════════════════
#  SAP Baglantisi — OData + Bearer Token
# ═══════════════════════════════════════════════════════════════

class SAPConnection:
    """SAP OData baglantisi, Bearer token ile yetkilendirme."""

    def __init__(self):
        self.session: Optional[requests.Session] = None
        self.base_url: str = ""
        self.service_url: str = ""

    def connect(self) -> dict:
        host = env("SAP_HOST", "").rstrip("/")
        client = env("SAP_CLIENT", "100")
        service = env("SAP_ODATA_SERVICE", "ZPRODORD_SRV")
        sso2 = env("SAP_SSO2_COOKIE", "")

        if not host:
            return {"ok": False, "msg": "SAP_HOST .env dosyasinda tanimli degil"}
        if not sso2 or sso2 == "your_sapsso2_cookie_value_here":
            return {"ok": False, "msg": "SAP_SSO2_COOKIE .env dosyasinda tanimli degil"}

        self.base_url = f"{host}/sap/opu/odata/sap/{service}"
        self.session = requests.Session()
        self.session.verify = False
        self.session.cookies.set("SAPSSO2", sso2, domain="")
        self.session.headers.update({
            "Accept": "application/json",
            "Content-Type": "application/json",
            "sap-client": client,
        })

        # Baglanti testi
        try:
            r = self.session.get(f"{self.base_url}/$metadata", timeout=15)
            if r.status_code == 200:
                return {"ok": True, "msg": f"SAP baglandi ({service})"}
            elif r.status_code == 401:
                return {"ok": False, "msg": "SAPSSO2 cookie gecersiz veya suresi dolmus (HTTP 401). Yeni cookie alin."}
            elif r.status_code == 403:
                return {"ok": False, "msg": "Yetkiniz yok (HTTP 403)"}
            else:
                return {"ok": False, "msg": f"HTTP {r.status_code}: {r.text[:200]}"}
        except requests.exceptions.ConnectionError:
            return {"ok": False, "msg": f"SAP sunucusuna baglanamiyor: {host}"}
        except requests.exceptions.Timeout:
            return {"ok": False, "msg": "Baglanti zaman asimi (15s)"}
        except Exception as e:
            return {"ok": False, "msg": str(e)}

    def get(self, path: str, params: dict = None) -> dict:
        if not self.session:
            return {"ok": False, "msg": "Baglanti yok"}
        try:
            url = f"{self.base_url}/{path}"
            r = self.session.get(url, params=params, timeout=30)
            r.raise_for_status()
            return {"ok": True, "data": r.json()}
        except requests.exceptions.HTTPError as e:
            return {"ok": False, "msg": f"HTTP {e.response.status_code}: {e.response.text[:300]}"}
        except Exception as e:
            return {"ok": False, "msg": str(e)}

    def get_raw(self, path: str) -> dict:
        """PDF/binary icerik icin ham byte dondurur."""
        if not self.session:
            return {"ok": False, "msg": "Baglanti yok"}
        try:
            url = f"{self.base_url}/{path}"
            r = self.session.get(url, timeout=60)
            r.raise_for_status()
            return {"ok": True, "data": r.content}
        except Exception as e:
            return {"ok": False, "msg": str(e)}

    def post(self, path: str, body: dict = None) -> dict:
        if not self.session:
            return {"ok": False, "msg": "Baglanti yok"}
        try:
            url = f"{self.base_url}/{path}"
            r = self.session.post(url, json=body or {}, timeout=30)
            r.raise_for_status()
            return {"ok": True, "data": r.json()}
        except Exception as e:
            return {"ok": False, "msg": str(e)}

    def close(self):
        if self.session:
            self.session.close()
            self.session = None


# Global baglanti
sap = SAPConnection()

# ═══════════════════════════════════════════════════════════════
#  MCP Server
# ═══════════════════════════════════════════════════════════════

mcp = FastMCP(name="SAP Is Karti Server", version="1.0.0")


@mcp.tool()
def connect_sap() -> dict:
    """SAP sunucusuna baglan (Bearer token ile)."""
    return sap.connect()


@mcp.tool()
def search_siparis(siparis_no: str) -> dict:
    """
    Siparis numarasiyla uretim siparisi ara.

    Args:
        siparis_no: Siparis/uretim numarasi (orn: 100001)
    Returns:
        Bulunan siparislerin listesi
    """
    # OData sorgusu
    filter_str = f"AUFNR eq '{siparis_no}'"
    result = sap.get("ProductionOrderSet", {"$filter": filter_str, "$top": "10"})

    if not result["ok"]:
        # Alternatif: RFC_READ_TABLE veya farkli entity
        result = sap.get(
            f"ProductionOrderSet?$filter=AUFNR eq '{siparis_no}'"
        )

    if result["ok"]:
        orders = result["data"].get("d", {}).get("results", [])
        return {"ok": True, "count": len(orders), "orders": orders}
    return result


@mcp.tool()
def download_is_karti(siparis_no: str, save_path: str) -> dict:
    """
    Tek siparis icin is karti PDF indir.

    Is akisi:
      1. Siparisin ekli dokumanlarini listele
      2. Is karti tipindekini bul
      3. PDF olarak indir

    Args:
        siparis_no: Siparis numarasi
        save_path: Kayit klasoru yolu
    Returns:
        Indirilen dosya yolu ve boyutu
    """
    save_dir = Path(save_path)
    save_dir.mkdir(parents=True, exist_ok=True)
    file_name = f"IsKarti_{siparis_no}.pdf"
    file_path = save_dir / file_name

    doc_type = env("SAP_DOC_TYPE", "ZJC")

    # Yontem 1: OData — dokuman eki olarak indir
    result = sap.get(
        f"ProductionOrderSet('{siparis_no}')/Attachments"
        f"?$filter=DocumentType eq '{doc_type}'"
    )
    if result["ok"]:
        docs = result["data"].get("d", {}).get("results", [])
        if docs:
            doc = docs[0]
            doc_id = doc.get("DocumentID", doc.get("DocID", ""))
            if doc_id:
                # PDF indir
                pdf_result = sap.get_raw(
                    f"DocumentSet('{doc_id}')/Attachment/$value"
                )
                if pdf_result["ok"] and pdf_result["data"]:
                    file_path.write_bytes(pdf_result["data"])
                    return {
                        "ok": True,
                        "path": str(file_path),
                        "size": len(pdf_result["data"]),
                    }

    # Yontem 2: OData — Smartform ciktisi
    smartform = env("SAP_SMARTFORM", "Z_IS_KARTI")
    result = sap.get(
        f"PrintJobSet"
        f"?$filter=Smartform eq '{smartform}' and ObjectKey eq '{siparis_no}'"
        f"&$format=application/pdf"
    )
    if result["ok"]:
        data = result["data"]
        if isinstance(data, bytes):
            file_path.write_bytes(data)
            return {"ok": True, "path": str(file_path), "size": len(data)}
        # JSON icinde base64 PDF varsa
        pdf_b64 = data.get("d", {}).get("PDFContent", "")
        if pdf_b64:
            raw = base64.b64decode(pdf_b64)
            file_path.write_bytes(raw)
            return {"ok": True, "path": str(file_path), "size": len(raw)}

    # Yontem 3: Siparis detay + ek indir
    detail = sap.get(f"ProductionOrderSet('{siparis_no}')")
    if detail["ok"]:
        order = detail["data"].get("d", {})
        # PDF_Indirme_URL al
        pdf_url = order.get("PDFUrl", order.get("JobCardUrl", ""))
        if pdf_url:
            pdf_result = sap.get_raw(pdf_url)
            if pdf_result["ok"] and pdf_result["data"]:
                file_path.write_bytes(pdf_result["data"])
                return {"ok": True, "path": str(file_path), "size": len(pdf_result["data"])}

    return {
        "ok": False,
        "msg": (
            f"Siparis {siparis_no} icin is karti PDF bulunamadi. "
            "SAP OData servis yapisini kontrol edin: "
            "ProductionOrderSet, Attachments, DocumentSet entity'leri."
        ),
    }


@mcp.tool()
def batch_download(siparis_listesi: list, save_path: str) -> dict:
    """
    Toplu is karti indirme.

    Args:
        siparis_listesi: Siparis numarasi listesi
        save_path: Kayit klasoru
    Returns:
        Basarili/basarisiz sayisi ve detaylar
    """
    results = {"total": len(siparis_listesi), "ok": 0, "fail": 0, "files": [], "errors": []}

    for i, no in enumerate(siparis_listesi, 1):
        no = str(no).strip()
        if not no:
            continue

        log.info(f"[{i}/{results['total']}] {no}")
        r = download_is_karti(no, save_path)

        if r.get("ok"):
            results["ok"] += 1
            results["files"].append({"no": no, "path": r["path"], "size": r["size"]})
        else:
            results["fail"] += 1
            results["errors"].append({"no": no, "msg": r.get("msg", "")})

    return results


@mcp.tool()
def disconnect_sap() -> dict:
    """SAP baglantisini kapat."""
    sap.close()
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════
#  Entry
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    mcp.run(transport="stdio")

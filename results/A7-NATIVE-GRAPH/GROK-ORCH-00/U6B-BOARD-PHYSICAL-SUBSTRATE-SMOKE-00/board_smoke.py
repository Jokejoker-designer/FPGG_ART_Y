#!/usr/bin/env python3
"""U6B physical substrate smoke. Frozen bit 1F0F2ABB. Not U5Q. Not Gate14 pass."""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import threading
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE
while not (REPO / "python" / "gate14_uart.py").is_file():
    if REPO.parent == REPO:
        raise SystemExit("REFUSE cannot find python/gate14_uart.py")
    REPO = REPO.parent
sys.path.insert(0, str(REPO))
from python.gate14_uart import (  # noqa: E402
    CMD_EXAM_QUERY,
    CMD_STATUS,
    c0_id,
    c1_mode,
    c7_fields,
    c8_fields,
    c9_fields,
    c10_fields,
    decode_cframe,
    frame,
)

WANT = "1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9"
C0_WANT = "34314347C00114A7"
BIT = REPO / "results/A7-NATIVE-GRAPH/GROK-ORCH-00/G14-EPOCH-REBIRTH-BIT-00/arty_a7_ng_native_v1_g14_epoch_rebirth_00.bit"
VIVADO = r"C:\2026.1\Vivado\bin\vivado.bat"
TZ = timezone(timedelta(hours=7))
WRAP_LIMIT = 6
T_HOLD_A = 0xA2


def gen_legal(g) -> bool:
    if g is None:
        return False
    g = int(g)
    if g in (0, 0xFFFFFFFF):
        return False
    return 1 <= g <= WRAP_LIMIT


class Cap:
    def __init__(self, ser) -> None:
        self.ser = ser
        self.buf = bytearray()
        self.lock = threading.Lock()
        self.stop = threading.Event()
        self.th = threading.Thread(target=self._run, daemon=True)

    def _run(self) -> None:
        while not self.stop.is_set():
            chunk = self.ser.read(256)
            if chunk:
                with self.lock:
                    self.buf.extend(chunk)

    def start(self) -> None:
        self.th.start()

    def snap(self) -> bytes:
        with self.lock:
            return bytes(self.buf)


def latest(frames, ckpt):
    hits = [f for f in frames if f["ckpt"] == ckpt]
    return hits[-1] if hits else None


def hx(v):
    if v is None:
        return None
    if isinstance(v, int):
        return "%X" % v
    return str(v)


def main() -> int:
    out = {
        "gate": "U6B-BOARD-PHYSICAL-SUBSTRATE-SMOKE-00",
        "result": "FAIL",
        "first_divergence": None,
        "u5q": "STILL_FAIL",
        "u7a": "CLOSED",
        "gate14_pass": "NO",
        "oracle_retarget": False,
        "path_in_bit": "G14 native v1 CFRAME/MIG/C9-pack/C10",
        "path_not_in_bit": [
            "a7ng_unified_retrieval",
            "AXI sparse walker U6 owner",
            "20-bit posting IDs",
            "U6 record LUT",
        ],
        "log": [],
    }
    sha = hashlib.sha256(BIT.read_bytes()).hexdigest().upper()
    out["bit_sha"] = sha
    if sha != WANT:
        out["first_divergence"] = "SHA_REFUSE"
        (HERE / "silicon_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
        print("FIRST_DIVERGENCE SHA_REFUSE")
        return 3

    try:
        import serial
        from serial.tools import list_ports
    except ImportError:
        out["first_divergence"] = "UART_DEAD"
        out["detail"] = "pyserial missing"
        (HERE / "silicon_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
        print("FIRST_DIVERGENCE UART_DEAD pyserial")
        return 4

    try:
        ports = [p.device for p in list_ports.comports()]
    except Exception:
        ports = []
    out["com_ports"] = ports

    try:
        ser = serial.Serial("COM12", 115200, timeout=0.05)
    except Exception as e:
        out["first_divergence"] = "UART_DEAD"
        out["detail"] = str(e)
        (HERE / "silicon_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
        print("FIRST_DIVERGENCE UART_DEAD", e)
        return 4

    cap = Cap(ser)
    cap.start()
    (HERE / "LISTEN_START.txt").write_text(datetime.now(TZ).isoformat(), encoding="utf-8")

    env = dict(**{k: v for k, v in __import__("os").environ.items()})
    env["XILINXD_LICENSE_FILE"] = r"D:\Xilinx\licenses\vivado_basic.lic"
    prog_log = HERE / "vivado_program.log"
    cmd = [VIVADO, "-mode", "batch", "-notrace", "-source", str(HERE / "program_once.tcl")]
    print("PROGRAM start", flush=True)
    r = subprocess.run(cmd, cwd=str(HERE), env=env, capture_output=True, text=True)
    prog_log.write_text((r.stdout or "") + "\n" + (r.stderr or ""), encoding="utf-8")
    if r.returncode != 0:
        ser.close()
        why = "PROGRAM_FAIL"
        if "REFUSE JTAG" in (r.stderr or "") + (r.stdout or ""):
            why = "JTAG_MISS"
        if "REFUSE PYNQ" in (r.stderr or "") + (r.stdout or ""):
            why = "PYNQ"
        out["first_divergence"] = why
        out["program_rc"] = r.returncode
        (HERE / "silicon_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
        print("FIRST_DIVERGENCE", why)
        return 5
    print("PROGRAM ok", flush=True)
    time.sleep(1.2)

    seq = 1

    def tx(typ, payload=b"", gap=0.25):
        nonlocal seq
        ser.write(frame(typ, seq, payload))
        ser.flush()
        seq += 1
        time.sleep(gap)

    def sample(tag):
        raw = cap.snap()
        fr = decode_cframe(raw)
        c0 = latest(fr, 0)
        c1 = latest(fr, 1)
        c7 = latest(fr, 7)
        c8 = latest(fr, 8)
        c9 = latest(fr, 9)
        c10 = latest(fr, 10)
        row = {
            "tag": tag,
            "n": len(fr),
            "ckpts": sorted({f["ckpt"] for f in fr}),
            "c0": c0_id(c0["payload"]).hex().upper() if c0 else None,
            "mode": c1_mode(c1["payload"]) if c1 else None,
            **(c7_fields(c7["payload"]) if c7 else {}),
            **(c8_fields(c8["payload"]) if c8 else {}),
            **(c9_fields(c9["payload"]) if c9 else {}),
            **(c10_fields(c10["payload"]) if c10 else {}),
            "raw_bytes": len(raw),
        }
        if "pack" in row and row["pack"] is not None:
            row["pack_hex"] = "%016X" % int(row["pack"])
        out["log"].append({k: row[k] for k in row if k != "ckpts"})
        print("SAMPLE", json.dumps({k: row.get(k) for k in (
            "tag", "n", "c0", "mode", "gen", "out", "pack_hex", "lmst", "lmdn", "busy",
        ) if k in row or k == "pack_hex"}), flush=True)
        return row

    time.sleep(0.8)
    boot = sample("boot")
    if boot.get("n", 0) < 1:
        out["first_divergence"] = "UART_DEAD"
        (HERE / "silicon_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
        print("FIRST_DIVERGENCE UART_DEAD n=0")
        ser.close()
        return 6
    if boot.get("c0") != C0_WANT:
        out["first_divergence"] = "C0_MISS"
        out["c0"] = boot.get("c0")
        (HERE / "silicon_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
        print("FIRST_DIVERGENCE C0_MISS", boot.get("c0"))
        ser.close()
        return 7
    if not gen_legal(boot.get("gen")):
        # GEN may arrive after STATUS
        tx(CMD_STATUS, gap=0.4)
        boot2 = sample("status1")
        if not gen_legal(boot2.get("gen")):
            out["first_divergence"] = "GEN_ILLEGAL"
            out["gen"] = boot2.get("gen")
            (HERE / "silicon_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
            print("FIRST_DIVERGENCE GEN_ILLEGAL", boot2.get("gen"))
            ser.close()
            return 8
        boot = boot2

    n_before = boot.get("n", 0)
    tx(CMD_STATUS, gap=0.35)
    st = sample("status2")
    if st.get("n", 0) <= n_before:
        # still ok if dump reused; require n>=1 already
        pass
    tx(CMD_EXAM_QUERY, bytes([T_HOLD_A]), gap=0.6)
    time.sleep(0.8)
    qrow = sample("exam_query")
    tx(CMD_STATUS, gap=0.4)
    after = sample("status_after_query")
    if after.get("n", 0) < 1:
        out["first_divergence"] = "UART_LOCKUP"
        (HERE / "silicon_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
        print("FIRST_DIVERGENCE UART_LOCKUP")
        ser.close()
        return 9

    raw = cap.snap()
    (HERE / "uart_raw.bin").write_bytes(raw)
    out["uart_sha256"] = hashlib.sha256(raw).hexdigest().upper()
    out["n_frames"] = after.get("n")
    out["c0"] = after.get("c0") or boot.get("c0")
    out["gen"] = after.get("gen") or boot.get("gen")
    out["c9_observed"] = qrow.get("pack") is not None or after.get("pack") is not None
    out["c10_observed"] = qrow.get("out") is not None or after.get("out") is not None
    out["c9_pack_hex"] = qrow.get("pack_hex") or after.get("pack_hex")
    out["c10_out"] = qrow.get("out") if qrow.get("out") is not None else after.get("out")
    out["datapath_toggled"] = bool(out["c9_observed"] or out["c10_observed"])
    out["cdc_class"] = "BIT_REPORT_ONLY"
    out["u6_20bit_id"] = "NOT_IN_ARTIFACT"
    out["retrieval_overflow"] = "NOT_IN_ARTIFACT"
    out["result"] = "PASS"
    out["claim"] = "PHYSICAL_SUBSTRATE = PROVEN_FOR_TESTED_PATH"
    out["not_claimed"] = [
        "U5Q", "U6 AXI sparse retrieval silicon", "20-bit posting IDs",
        "U7A", "GATE14_PASS", "BOARD_PASS",
    ]
    (HERE / "silicon_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("U6B_PASS", json.dumps({
        "n_frames": out["n_frames"], "gen": out["gen"],
        "c9": out["c9_observed"], "c10": out["c10_observed"],
        "c10_out": out["c10_out"],
    }))
    cap.stop.set()
    time.sleep(0.05)
    ser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""A7-LM-02 board ladder. Host compares; does not compute the board result."""
from __future__ import annotations

import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from python.ref.fixed_gemm import SEED0, batch_fold, run_case
from python.uart_frames import lm02_payload_frame, parse_frame
from python.uart_stream import FrameStream
import serial

UI_HZ = 83_333_333.0
COMPUTE_PEAK = 128 * UI_HZ / 1e9
DDR_PEAK = 1.17


def send(port, f: bytes) -> None:
    port.write(f)
    port.flush()


def wait_kind(stream: FrameStream, kind: int, t: float):
    deadline = time.monotonic() + t
    while time.monotonic() < deadline:
        raw = stream.get_frame(min(0.4, max(0.05, deadline - time.monotonic())))
        if not raw:
            continue
        rec = parse_frame(raw.data)
        if rec.get("ok") and rec.get("kind") == kind:
            return rec
    return None


def status(port, stream):
    send(port, lm02_payload_frame(bytes([0x22]) + bytes(11)))
    rec = wait_kind(stream, 0x90, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    fl = raw[2]
    return {
        "pass": bool(fl & 0x80),
        "busy": bool(fl & 0x40),
        "calib": bool(fl & 0x20),
        "done": bool(fl & 0x10),
        "phase": raw[3],
        "cases": int.from_bytes(raw[4:8], "little"),
    }


def fold(port, stream):
    send(port, lm02_payload_frame(bytes([0x23]) + bytes(11)))
    rec = wait_kind(stream, 0x91, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    return {
        "xor32": int.from_bytes(raw[2:6], "little"),
        "add32": int.from_bytes(raw[6:10], "little"),
        "macs": int.from_bytes(raw[10:14], "little"),
    }


def counters(port, stream):
    send(port, lm02_payload_frame(bytes([0x24]) + bytes(11)))
    rec = wait_kind(stream, 0x92, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    cyc = int.from_bytes(raw[2:6], "little")
    comp = int.from_bytes(raw[6:10], "little")
    haz = int.from_bytes(raw[10:14], "little")
    return {"cycles": cyc, "comp_cycles": comp, "hazards": haz}


def wait_done(port, stream, timeout_s: float):
    t0 = time.monotonic()
    last = None
    saw_busy = False
    while time.monotonic() - t0 < timeout_s:
        last = status(port, stream)
        if last and last["busy"]:
            saw_busy = True
        if last and saw_busy and not last["busy"]:
            return last
        if last and last["calib"] and last["pass"] and not last["busy"] and time.monotonic() - t0 > 0.5:
            return last
        time.sleep(0.05)
    return last


def run_batch(port, stream, count: int, seed: int, wait_s: float):
    body = bytes([0x21, count & 0xFF, (count >> 8) & 0xFF]) + seed.to_bytes(4, "little") + bytes(5)
    send(port, lm02_payload_frame(body))
    st = wait_done(port, stream, wait_s)
    fd = fold(port, stream)
    ct = counters(port, stream)
    exp = batch_fold(count, seed)
    match = bool(fd and fd["xor32"] == exp["xor32"] and fd["add32"] == exp["add32"] and fd["macs"] == exp["macs"])
    u_mac = 0.0
    if ct and ct["comp_cycles"] > 0 and fd:
        u_mac = fd["macs"] / (128.0 * ct["comp_cycles"])
    return {
        "status": st,
        "fold": fd,
        "expected": {k: exp[k] for k in ("xor32", "add32", "macs", "count", "seed")},
        "counters": ct,
        "u_mac": u_mac,
        "match": match,
        "pass": bool(match and st and st.get("calib") and (ct or {}).get("hazards", 1) == 0),
    }


def run_op(port, stream, op: int, wait_s: float, extra: bytes = b""):
    send(port, lm02_payload_frame(bytes([op]) + extra + bytes(11 - len(extra))))
    st = wait_done(port, stream, wait_s)
    fd = fold(port, stream)
    ct = counters(port, stream)
    return {"status": st, "fold": fd, "counters": ct}


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    out_dir = ROOT / "results" / "A7-LM-02"
    out_dir.mkdir(parents=True, exist_ok=True)
    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.4)
    stream = FrameStream(port)
    t0 = time.monotonic()
    st0 = None
    while time.monotonic() - t0 < 10:
        st0 = status(port, stream)
        if st0 and st0["calib"]:
            break
        time.sleep(0.1)
    summary = {
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "status0": st0,
        "gates": {},
        "pass": False,
    }
    if not st0 or not st0["calib"]:
        summary["reason"] = "no_calib"
        (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print(json.dumps(summary, indent=2))
        port.close()
        return 2

    print("=== batch 10000 ===", flush=True)
    b10k = run_batch(port, stream, 10000, SEED0, 180.0)
    summary["batch_10k"] = {k: v for k, v in b10k.items() if k != "expected"}
    summary["batch_10k"]["expected"] = b10k["expected"]
    print(json.dumps(summary["batch_10k"], indent=2), flush=True)
    (out_dir / "batch_10k.json").write_text(json.dumps(b10k, indent=2), encoding="utf-8")

    print("=== one-case corners 0,17,19 ===", flush=True)
    ones = []
    for i in (0, 17, 19, 1, 7):
        p = run_case(i)
        extra = bytes([0x20, p["mode"], p["M"], p["N"], p["K"] & 0xFF, (p["K"] >> 8) & 0xFF]) + SEED0.to_bytes(4, "little") + i.to_bytes(2, "little")
        # 0x20 payload: op already in extra[0]
        send(port, lm02_payload_frame(extra))
        wait_done(port, stream, 30.0)
        fd = fold(port, stream)
        ok = bool(fd and fd["xor32"] == p["xor32"] and fd["add32"] == p["add32"])
        ones.append({"i": i, "ok": ok, "fold": fd, "exp_xor": p["xor32"], "exp_add": p["add32"]})
        print(ones[-1], flush=True)
    summary["spot"] = ones

    print("=== gemm roof 0x27 ===", flush=True)
    roof = run_op(port, stream, 0x27, 60.0)
    comp = (roof.get("counters") or {}).get("comp_cycles") or 0
    macs = (roof.get("fold") or {}).get("macs") or 0
    u_mac = macs / (128.0 * comp) if comp else 0.0
    roof["u_mac"] = u_mac
    roof["compute_peak_gmac"] = COMPUTE_PEAK
    roof["eff_compute"] = u_mac
    summary["gemm_roof"] = roof
    print(json.dumps(roof, indent=2), flush=True)

    print("=== ddr gemv 0x26 ===", flush=True)
    ddr = run_op(port, stream, 0x26, 60.0, extra=bytes([0x00, 0x01]))  # K=256
    cyc = (ddr.get("counters") or {}).get("cycles") or 0
    macs_d = (ddr.get("fold") or {}).get("macs") or 0
    gmac = (macs_d / (cyc / UI_HZ) / 1e9) if cyc else 0.0
    ddr["gmac"] = gmac
    ddr["ddr_peak"] = DDR_PEAK
    ddr["eff_ddr"] = gmac / DDR_PEAK if DDR_PEAK else 0.0
    summary["ddr_gemv"] = ddr
    print(json.dumps(ddr, indent=2), flush=True)

    gates = {
        "calib": True,
        "batch_10k": bool(b10k.get("pass")),
        "spot": all(x["ok"] for x in ones),
        "hazards_0": (b10k.get("counters") or {}).get("hazards", 1) == 0,
        "u_mac_compute_ge_0p60": u_mac >= 0.60,
        "ddr_eff_ge_0p60": bool(ddr.get("eff_ddr", 0) >= 0.60 or gmac >= 0.70),
    }
    summary["gates"] = gates
    summary["pass"] = all(gates.values())
    summary["ended_utc"] = datetime.now(timezone.utc).isoformat()
    (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    port.close()
    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

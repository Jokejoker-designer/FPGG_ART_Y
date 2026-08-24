"""A7-LM-02R board ladder. Host compares; does not compute the board GEMM/GEMV."""
from __future__ import annotations

import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from python.ref.fixed_gemm import SEED0, case_params, requant_hw_fold, run_case, run_explicit
from python.uart_frames import lm02_payload_frame, parse_frame
from python.uart_stream import FrameStream
import serial


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
    return {
        "cycles": int.from_bytes(raw[2:6], "little"),
        "comp_cycles": int.from_bytes(raw[6:10], "little"),
        "hazards": int.from_bytes(raw[10:14], "little"),
    }


def counters2(port, stream):
    send(port, lm02_payload_frame(bytes([0x2C]) + bytes(11)))
    rec = wait_kind(stream, 0x94, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    return {
        "dma_under": int.from_bytes(raw[2:6], "little"),
        "bank_haz": int.from_bytes(raw[6:8], "little"),
        "axi_berr": raw[8],
        "axi_rerr": raw[9],
        "swaps": int.from_bytes(raw[10:12], "little"),
    }


def overlap(port, stream):
    send(port, lm02_payload_frame(bytes([0x2D]) + bytes(11)))
    rec = wait_kind(stream, 0x95, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    return {
        "overlap_cyc": int.from_bytes(raw[2:6], "little"),
        "ntile": int.from_bytes(raw[6:8], "little"),
    }


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


def one_case(port, stream, mode, m, n, k, idx, seed, wait_s=60.0):
    extra = bytes([0x20, mode & 1, m & 15, n & 255, k & 255, (k >> 8) & 255])
    extra += seed.to_bytes(4, "little") + idx.to_bytes(2, "little")
    send(port, lm02_payload_frame(extra))
    wait_done(port, stream, wait_s)
    return fold(port, stream), counters2(port, stream), overlap(port, stream)


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    n10k = int(sys.argv[2]) if len(sys.argv) > 2 else 10000
    out_dir = ROOT / "results" / "A7-LM-02R"
    out_dir.mkdir(parents=True, exist_ok=True)
    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.4)
    stream = FrameStream(port)
    t0 = time.monotonic()
    st0 = None
    while time.monotonic() - t0 < 15:
        st0 = status(port, stream)
        if st0 and st0["calib"]:
            break
        time.sleep(0.1)
    summary: dict = {
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "status0": st0,
        "gates": {},
        "pass": False,
        "wording": "per-case folds, not one batch aggregate",
    }
    if not st0 or not st0["calib"]:
        summary["reason"] = "no_calib"
        (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print(json.dumps(summary, indent=2))
        port.close()
        return 2

    pp = []
    for k in (257, 511, 513):
        print(f"=== ping-pong K={k} ===", flush=True)
        exp = run_explicit(0, 1, 128, k, 0, SEED0)
        send(port, lm02_payload_frame(
            bytes([0x29, k & 255, (k >> 8) & 255]) + SEED0.to_bytes(4, "little") + bytes(5)
        ))
        wait_done(port, stream, 90.0)
        fd = fold(port, stream)
        c2 = counters2(port, stream)
        ov = overlap(port, stream)
        match = bool(fd and fd["xor32"] == exp["xor32"] and fd["add32"] == exp["add32"] and fd["macs"] == exp["macs"])
        rec = {
            "k": k,
            "match": match,
            "fold": fd,
            "expected": {"xor32": exp["xor32"], "add32": exp["add32"], "macs": exp["macs"]},
            "counters2": c2,
            "overlap": ov,
        }
        rec["ok"] = bool(
            match
            and c2
            and c2["swaps"] > 0
            and c2["dma_under"] == 0
            and c2["bank_haz"] == 0
            and c2["axi_berr"] == 0
            and c2["axi_rerr"] == 0
            and ov
            and ov["overlap_cyc"] > 0
            and ov["ntile"] >= 2
        )
        pp.append(rec)
        print(json.dumps(rec, indent=2), flush=True)

    print("=== corner 13 / sat 8 ===", flush=True)
    spots = []
    for i in (13, 8):
        p = run_case(i)
        fd, c2, ov = one_case(port, stream, p["mode"], p["M"], p["N"], p["K"], i, SEED0)
        ok = bool(fd and fd["xor32"] == p["xor32"] and fd["add32"] == p["add32"])
        spots.append({"i": i, "corner": p["corner"], "sat": p["sat"], "ok": ok, "fold": fd, "exp_xor": p["xor32"], "exp_add": p["add32"]})
        print(spots[-1], flush=True)

    print("=== requant 0x28 after case 8 ===", flush=True)
    p8 = run_case(8)
    one_case(port, stream, p8["mode"], p8["M"], p8["N"], p8["K"], 8, SEED0)
    send(port, lm02_payload_frame(bytes([0x28, 0]) + bytes(10)))
    wait_done(port, stream, 10.0)
    rq = fold(port, stream)
    exp_x, exp_a = requant_hw_fold(p8["P"], p8["mode"], p8["M"], p8["N"], 0)
    rq_ok = bool(rq and rq["xor32"] == exp_x and rq["add32"] == exp_a)
    summary["requant"] = {"ok": rq_ok, "fold": rq, "exp_xor": exp_x, "exp_add": exp_a}
    print(summary["requant"], flush=True)

    print(f"=== per-case folds 0..{n10k-1} ===", flush=True)
    misses = []
    for i in range(n10k):
        p = run_case(i)
        fd, _, _ = one_case(port, stream, p["mode"], p["M"], p["N"], p["K"], i, SEED0, 30.0)
        ok = bool(fd and fd["xor32"] == p["xor32"] and fd["add32"] == p["add32"])
        if not ok:
            misses.append({"i": i, "fold": fd, "exp_xor": p["xor32"], "exp_add": p["add32"]})
            if len(misses) >= 8:
                break
        if (i & 0xFF) == 0xFF:
            print(f"  checked {i+1}/{n10k} misses={len(misses)}", flush=True)
    summary["per_case"] = {"n": n10k, "misses": misses, "ok": len(misses) == 0}

    gates = {
        "calib": True,
        "k257": bool(pp[0]["ok"]),
        "k511": bool(pp[1]["ok"]),
        "k513": bool(pp[2]["ok"]),
        "corner13": bool(spots[0]["ok"] and spots[0]["corner"]),
        "sat8": bool(spots[1]["ok"] and spots[1]["sat"]),
        "requant_0x28": rq_ok,
        "per_case_10k": bool(summary["per_case"]["ok"]),
    }
    summary["pingpong"] = pp
    summary["spots"] = spots
    summary["gates"] = gates
    summary["pass"] = all(gates.values())
    summary["ended_utc"] = datetime.now(timezone.utc).isoformat()
    (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({k: summary[k] for k in ("gates", "pass", "per_case", "requant")}, indent=2))
    port.close()
    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

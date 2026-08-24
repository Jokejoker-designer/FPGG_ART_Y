"""Reproduce persist_reload hang on the ILA/debug bit and snapshot FSM.

Writes results/A7-LM-06/ila_hang/ only. Does not touch hardware_c0/c1 or C1 bits.
"""
from __future__ import annotations

import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

import serial  # noqa: E402
import a7lm04_close_ladder as L04  # noqa: E402
from a7lm06_hardware_ladder import (  # noqa: E402
    target_frame,
    upload,
    wait_idle_logged,
)
from a7lm06_ila_peek import decode  # noqa: E402
from python.ref.a7lm06_fixed_ref import TinyGPT803k  # noqa: E402
from python.uart_frames import lm04_payload_frame, parse_frame  # noqa: E402
from python.uart_stream import FrameStream  # noqa: E402

OUT_DIR = ROOT / "results" / "A7-LM-06" / "ila_hang"
C1_LADDER = ROOT / "results" / "A7-LM-06" / "hardware_c1" / "ladder.json"
C1_SHA = "67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA"


def diagnose(row: dict | None) -> str:
    if not row:
        return "NO_PEEK"
    flags = []
    if row.get("p_busy") and row.get("persist_bst") == "STORE" and row.get("w_stall"):
        if row.get("p_dma_owner") and row.get("tile_req"):
            flags.append("DEADLOCK_STORE_stall_persist_holds_dma")
        elif row.get("tile_req") or row.get("tile_bst") not in ("IDLE", "DONE/NEXT"):
            flags.append("STORE_wait_tile_refill")
        else:
            flags.append("STORE_stall_no_tile_req")
    if row.get("p_busy") and row.get("persist_bst") in ("REQ", "WAITACK") and row.get("p_dma_owner"):
        if row.get("persist_dst") in ("DRAIN", "WAITDONE", "FEED"):
            flags.append("DMA_chunk_in_flight")
        if row.get("persist_dst") == "WAITDONE" and not row.get("dma_busy"):
            flags.append("WAITDONE_dma_idle_maybe_lost_done")
    if row.get("p_busy") and row.get("persist_bst") == "FILL" and row.get("w_stall"):
        flags.append("FLUSH_fill_stall")
    if not flags and row.get("p_busy"):
        flags.append("BUSY_other")
    if not row.get("p_busy") and row.get("p_done"):
        flags.append("DONE")
    return ",".join(flags) or "IDLE"


def drain_classified(stream: FrameStream, timeout_s: float):
    """Collect frames without dropping 0xA6 / 0xA8."""
    a6 = None
    a8 = None
    deadline = time.monotonic() + timeout_s
    while time.monotonic() < deadline:
        raw = stream.get_frame(min(0.2, max(0.02, deadline - time.monotonic())))
        if not raw:
            if a8 is not None or a6 is not None:
                break
            continue
        rec = parse_frame(raw.data)
        if not rec.get("ok"):
            continue
        kind = rec.get("kind")
        if kind == 0xA6:
            a6 = rec
        elif kind == 0xA8:
            a8 = rec
        if a8 is not None and a6 is not None:
            break
    return a6, a8


def peek_keep_a6(port, stream: FrameStream):
    L04.send(port, lm04_payload_frame(bytes([0x58]) + bytes(11)))
    a6, a8 = drain_classified(stream, 2.0)
    row = None
    if a8 and "dbg" in a8:
        row = decode(int(a8["dbg"]))
    elif a8:
        raw = a8.get("hex") or ""
        data = bytes.fromhex(raw) if raw else b""
        if len(data) >= 10:
            row = decode(int.from_bytes(data[2:10], "little"))
    return a6, row


def persist_and_peek(port, stream: FrameStream, opcode: int, label: str, hang_s: float = 90.0) -> dict:
    snapshots = []
    last_key = None
    stuck_n = 0
    a6 = None
    L04.send(port, lm04_payload_frame(bytes([opcode]) + bytes(11)))
    t0 = time.monotonic()
    last_print = -1.0
    while time.monotonic() - t0 < hang_s:
        got_a6, row = peek_keep_a6(port, stream)
        if got_a6:
            a6 = got_a6
        elapsed = time.monotonic() - t0
        if row:
            row = dict(row)
            row["t"] = round(elapsed, 3)
            row["diag"] = diagnose(row)
            key = (
                row.get("persist_bst"),
                row.get("persist_dst"),
                row.get("persist_ch"),
                row.get("tile_bst"),
                row.get("tile_dst"),
                row.get("w_stall"),
                row.get("p_dma_owner"),
                row.get("wdma_owner"),
                row.get("tile_req"),
                row.get("mem_addr"),
            )
            if key == last_key:
                stuck_n += 1
            else:
                stuck_n = 0
                last_key = key
                snapshots.append(row)
                print(f"{label} t={elapsed:.1f}s {row}", flush=True)
            if elapsed - last_print >= 5.0:
                last_print = elapsed
                print(
                    f"{label} poll t={elapsed:.1f}s stuck={stuck_n} {row.get('diag')} ch={row.get('persist_ch')}",
                    flush=True,
                )
            if a6:
                print(f"{label} A6 {a6}", flush=True)
                break
            if stuck_n >= 12 and row.get("p_busy") and elapsed > 8.0:
                print(f"{label} FROZEN after {elapsed:.1f}s", flush=True)
                break
        elif a6:
            print(f"{label} A6 {a6}", flush=True)
            break
        time.sleep(0.15)
    st = L04.status(port, stream)
    return {
        "opcode": opcode,
        "a6": a6,
        "status": st,
        "snapshots": snapshots,
        "n_unique": len(snapshots),
        "stuck_polls": stuck_n,
        "elapsed_s": round(time.monotonic() - t0, 3),
        "last": snapshots[-1] if snapshots else None,
        "diag": diagnose(snapshots[-1] if snapshots else None),
    }


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    if not C1_LADDER.exists():
        raise RuntimeError("missing C1 ladder evidence; refuse to continue")
    out = {
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "port": port_name,
        "note": "ILA/debug bit only; not a close run; does not overwrite C1",
        "c1_ladder_preserved": True,
    }
    port = serial.Serial(port_name, 115200, timeout=0.05, write_timeout=2.0)
    time.sleep(0.4)
    stream = FrameStream(port)
    try:
        print("phase calib", flush=True)
        out["calib"] = L04.wait_calib(port, stream, 30.0)
        if not out["calib"] or not out["calib"].get("calib"):
            raise RuntimeError(f"calib failed: {out['calib']}")
        print("phase idle_peek", flush=True)
        _a6, idle = peek_keep_a6(port, stream)
        print(f"idle_peek {idle}", flush=True)
        out["idle_peek"] = idle
        if not idle:
            raise RuntimeError("UART 0xA8 peek failed — is the ILA/debug bit programmed?")

        print("phase upload", flush=True)
        blob0 = TinyGPT803k(2).flat_i8()
        upload(port, stream, blob0)

        model1 = TinyGPT803k(2)
        before_rec = model1.backward_full([1], 32, lr=3, apply=False)
        L04.load_ctx(port, [1])
        L04.send(port, target_frame(32, 3))
        print("phase one_full", flush=True)
        out["one_full"] = wait_idle_logged(port, stream, 600.0, "one_full")
        out["expected_forward"] = {"pred": before_rec["pred"], "loss": before_rec["loss"]}
        print(f"one_full {out['one_full']}", flush=True)

        print("phase persist_flush+peek", flush=True)
        out["flush"] = persist_and_peek(port, stream, 0x40, "flush", hang_s=180.0)
        print(f"flush a6={out['flush'].get('a6')} diag={out['flush'].get('diag')}", flush=True)

        print("phase persist_reload+peek", flush=True)
        out["reload"] = persist_and_peek(port, stream, 0x41, "reload", hang_s=120.0)
        print(f"reload a6={out['reload'].get('a6')} diag={out['reload'].get('diag')}", flush=True)
        out["verdict"] = out["reload"].get("diag")
    except Exception as exc:
        out["exception"] = f"{type(exc).__name__}: {exc}"
        print(out["exception"], flush=True)
    finally:
        port.close()
        out["finished_utc"] = datetime.now(timezone.utc).isoformat()
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        path = OUT_DIR / "capture.json"
        path.write_text(json.dumps(out, indent=2), encoding="utf-8")
        print(f"wrote {path}", flush=True)
    return 0 if out.get("reload", {}).get("a6") else 1


if __name__ == "__main__":
    raise SystemExit(main())

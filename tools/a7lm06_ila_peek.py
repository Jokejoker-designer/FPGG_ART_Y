"""Live FSM peek for LM-06 debug bit (UART 0x58 / 0xA8).

Vivado BASIC cannot insert ILA. This reads the same 64-bit dbg_ila bus.
Does not overwrite C1 evidence.
"""
from __future__ import annotations

import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

import serial  # noqa: E402
import a7lm04_close_ladder as L04  # noqa: E402
from python.uart_frames import lm04_payload_frame  # noqa: E402
from python.uart_stream import FrameStream  # noqa: E402

BST = {
    0: "IDLE",
    1: "FILL",
    2: "FWAIT",
    3: "FCAP",
    4: "REQ",
    5: "WAITACK",
    6: "STORE",
    7: "SWAIT",
    8: "DONE/NEXT",
    9: "TOUCH",
}
RG = {0: "TOK", 1: "POS", 2: "L0", 3: "L1", 4: "L2", 5: "L3", 6: "HEAD"}
DST = {0: "IDLE", 1: "GO", 2: "FEED", 3: "DRAIN", 4: "WAITDONE", 5: "ACK"}


def decode(w: int) -> dict:
    return {
        "persist_bst": BST.get(w & 0xF, str(w & 0xF)),
        "persist_dst": DST.get((w >> 4) & 7, str((w >> 4) & 7)),
        "persist_ch": (w >> 7) & 0x1FFF,
        "persist_is_flush": bool((w >> 20) & 1),
        "tile_bst": BST.get((w >> 21) & 0xF, str((w >> 21) & 0xF)),
        "tile_dst": DST.get((w >> 25) & 7, str((w >> 25) & 7)),
        "tile_rg": RG.get((w >> 28) & 7, str((w >> 28) & 7)),
        "tile_miss": bool((w >> 31) & 1),
        "tile_dirty": bool((w >> 32) & 1),
        "tile_req": bool((w >> 33) & 1),
        "persist_req": bool((w >> 34) & 1),
        "w_stall": bool((w >> 35) & 1),
        "p_busy": bool((w >> 36) & 1),
        "p_dma_owner": bool((w >> 37) & 1),
        "wdma_owner": bool((w >> 38) & 1),
        "dma_busy": bool((w >> 39) & 1),
        "mem_we": bool((w >> 40) & 1),
        "p_go_reload": bool((w >> 41) & 1),
        "p_go_flush": bool((w >> 42) & 1),
        "p_done": bool((w >> 43) & 1),
        "mem_addr": (w >> 44) & 0xFFFFF,
        "raw": f"{w:016X}",
    }


def peek(port, stream: FrameStream):
    L04.send(port, lm04_payload_frame(bytes([0x58]) + bytes(11)))
    rec = L04.wait_kind(stream, 0xA8, 2.0)
    if not rec:
        return None
    if "dbg" in rec:
        return decode(int(rec["dbg"]))
    raw = rec.get("hex") or ""
    data = bytes.fromhex(raw) if raw else rec.get("raw") or b""
    if isinstance(data, str):
        data = bytes.fromhex(data)
    if len(data) < 10:
        return None
    return decode(int.from_bytes(data[2:10], "little"))


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    period = float(sys.argv[3]) if len(sys.argv) > 3 else 0.25
    port = serial.Serial(port_name, 115200, timeout=0.2)
    stream = FrameStream(port)
    try:
        for i in range(n):
            row = peek(port, stream)
            print(row, flush=True)
            if i + 1 < n:
                time.sleep(period)
    finally:
        port.close()
    return 0 if row else 1


if __name__ == "__main__":
    raise SystemExit(main())

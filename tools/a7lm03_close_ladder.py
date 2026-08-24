"""A7-LM-03 board ladder. Host compares; does not compute board CE/pred/updates."""
from __future__ import annotations

import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from python.ref.a7lm03_fixed_ref import HEAD_EPOCHS, HEAD_LR, TinyGPT25k, board_corpus, train_full_sgd
from python.uart_frames import lm03_payload_frame, parse_frame
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
    send(port, lm03_payload_frame(bytes([0x35]) + bytes(11)))
    rec = wait_kind(stream, 0xA1, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    fl = raw[2]
    return {
        "after": bool(fl & 0x80),
        "busy": bool(fl & 0x40),
        "done": bool(fl & 0x20),
        "phase": raw[3],
        "wr_n": int.from_bytes(raw[4:8], "little"),
        "pred": raw[8],
        "loss": int.from_bytes(raw[9:11], "little"),
    }


def fold(port, stream):
    send(port, lm03_payload_frame(bytes([0x36]) + bytes(11)))
    rec = wait_kind(stream, 0xA2, 30.0)
    if not rec:
        return None
    raw = rec["raw"]
    return {
        "xor32": int.from_bytes(raw[2:6], "little"),
        "add32": int.from_bytes(raw[6:10], "little"),
        "wr_n": int.from_bytes(raw[10:14], "little"),
    }


def ce_page(port, stream):
    send(port, lm03_payload_frame(bytes([0x37]) + bytes(11)))
    rec = wait_kind(stream, 0xA3, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    return {
        "ce0": int.from_bytes(raw[2:6], "little"),
        "ce1": int.from_bytes(raw[6:10], "little"),
        "loss": int.from_bytes(raw[10:12], "little"),
    }


def wait_idle(port, stream, timeout_s: float):
    t0 = time.monotonic()
    last = None
    saw_busy = False
    while time.monotonic() - t0 < timeout_s:
        last = status(port, stream)
        if last and last["busy"]:
            saw_busy = True
        if last and saw_busy and not last["busy"]:
            return last
        if last and not last["busy"] and time.monotonic() - t0 > 0.4:
            return last
        time.sleep(0.05)
    return last


def write_weights(port, blob: list[int]) -> None:
    for i, b in enumerate(blob):
        addr = i & 0x7FFF
        val = b & 0xFF
        send(port, lm03_payload_frame(bytes([0x30, addr & 0xFF, (addr >> 8) & 0x7F, val]) + bytes(8)))
        if (i & 0xFF) == 0xFF:
            time.sleep(0.002)


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    replay_root = os.environ.get("A7_REPLAY_ROOT")
    out_dir = Path(replay_root) / "A7-LM-03" if replay_root else ROOT / "results" / "A7-LM-03"
    out_dir.mkdir(parents=True, exist_ok=True)
    model = TinyGPT25k(2)
    init_fold = model.fold()
    ref = train_full_sgd(TinyGPT25k(2), board_corpus(8), epochs=HEAD_EPOCHS, lr=HEAD_LR)
    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.3)
    stream = FrameStream(port)
    send(port, lm03_payload_frame(bytes([0x38, 0]) + bytes(10)))
    summary = {
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "gates": {},
        "pass": False,
        "ref": {"loss0": ref["loss0"], "loss1": ref["loss1"], "drop": ref["drop"], "fold": ref["fold"], "all_moved": ref["all_moved"]},
        "init_fold": init_fold,
    }
    st0 = status(port, stream)
    summary["status0"] = st0
    if not st0:
        summary["reason"] = "no_status"
        (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print(json.dumps(summary, indent=2))
        port.close()
        return 2

    print("=== upload init ===", flush=True)
    write_weights(port, TinyGPT25k(2).flat_i8())
    f0 = fold(port, stream)
    summary["fold_init"] = f0
    print(f0, flush=True)

    print("=== corpus 0x3A ===", flush=True)
    send(port, lm03_payload_frame(bytes([0x3A, 8, HEAD_EPOCHS, HEAD_LR]) + bytes(8)))
    wait_idle(port, stream, 600.0)
    fd = fold(port, stream)
    ce = ce_page(port, stream)
    st1 = status(port, stream)
    summary["after_train"] = {"fold": fd, "ce": ce, "status": st1}
    print(json.dumps(summary["after_train"], indent=2), flush=True)

    drop = 0.0
    if ce and ce["ce0"]:
        drop = (ce["ce0"] - ce["ce1"]) / float(ce["ce0"])
    match = bool(fd and fd["xor32"] == ref["fold"]["xor32"] and fd["add32"] == ref["fold"]["add32"])
    wr_ok = bool(st1 and st1.get("wr_n", 0) > 0)

    print("=== AFTER ===", flush=True)
    send(port, lm03_payload_frame(bytes([0x38, 1]) + bytes(10)))
    wr_before = (status(port, stream) or {}).get("wr_n", -1)
    send(port, lm03_payload_frame(bytes([0x34, 16, HEAD_LR]) + bytes(9)))
    wait_idle(port, stream, 30.0)
    wr_after = (status(port, stream) or {}).get("wr_n", -2)
    after_ok = wr_before == wr_after

    gates = {
        "status": st0 is not None,
        "init_fold": bool(f0 and f0["xor32"] == init_fold["xor32"] and f0["add32"] == init_fold["add32"]),
        "ce_drop_ge_0p30": drop >= 0.30,
        "all_banks_ref": bool(ref["all_moved"]),
        "writes_nonzero": wr_ok,
        "fold_match_ref": match,
        "after_zero_writes": after_ok,
    }
    summary["gates"] = gates
    summary["ce_drop"] = drop
    summary["pass"] = all(gates.values())
    summary["ended_utc"] = datetime.now(timezone.utc).isoformat()
    (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    port.close()
    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

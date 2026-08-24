"""One full last-token step on A7-LM-04 vs oracle. Host compares only.

UART family A5/0x84. Persist = DDR flush then reload; fold after reload
must match fold after the FPGA update (not a BRAM-only image).
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from python.ref.a7lm04_fixed_ref import TinyGPT100k, bank_folds, bank_slices, fold_bytes
from python.uart_frames import lm04_payload_frame, lm04_read_frame, lm04_write_frame, parse_frame
from python.uart_stream import FrameStream
import serial

NPARAM = 100352
EXP0 = {"xor32": 2, "add32": 11803320}
EXP1 = {"xor32": 7, "add32": 11822211}


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
            rec.pop("raw", None)
            rec["hex"] = raw.data.hex()
            return rec
    return None


def status(port, stream):
    send(port, lm04_payload_frame(bytes([0x35]) + bytes(11)))
    rec = wait_kind(stream, 0xA1, 2.0)
    if not rec:
        return None
    return {
        "after": rec.get("after"),
        "busy": rec.get("busy"),
        "done": rec.get("done"),
        "calib": rec.get("calib"),
        "persist": rec.get("persist"),
        "phase": rec.get("phase"),
        "wr_n": rec.get("wr_n"),
        "pred": rec.get("pred"),
        "loss": rec.get("loss"),
    }


def fold(port, stream):
    send(port, lm04_payload_frame(bytes([0x36]) + bytes(11)))
    rec = wait_kind(stream, 0xA2, 45.0)
    if not rec:
        return None
    return {"xor32": rec["xor32"], "add32": rec["add32"], "wr_n": rec["wr_n"]}


def persist_page(port, stream):
    send(port, lm04_payload_frame(bytes([0x42]) + bytes(11)))
    return wait_kind(stream, 0xA6, 2.0)


def persist_flush(port, stream):
    send(port, lm04_payload_frame(bytes([0x40]) + bytes(11)))
    rec = wait_kind(stream, 0xA6, 30.0)
    return rec


def persist_reload(port, stream):
    send(port, lm04_payload_frame(bytes([0x41]) + bytes(11)))
    rec = wait_kind(stream, 0xA6, 30.0)
    return rec


def read8(port, stream, addr: int):
    send(port, lm04_read_frame(addr))
    rec = wait_kind(stream, 0xA4, 2.0)
    if not rec:
        return None
    return rec.get("data")


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
        if last and not last["busy"] and time.monotonic() - t0 > 0.5:
            return last
        time.sleep(0.05)
    return last


def wait_calib(port, stream, timeout_s: float = 20.0):
    t0 = time.monotonic()
    last = None
    while time.monotonic() - t0 < timeout_s:
        last = status(port, stream)
        if last and last.get("calib"):
            return last
        time.sleep(0.2)
    return last


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    do_dump = "--dump" in sys.argv[2:]
    skip_persist = "--no-persist" in sys.argv[2:]
    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.4)
    stream = FrameStream(port)
    send(port, lm04_payload_frame(bytes([0x38, 0]) + bytes(10)))
    cal = wait_calib(port, stream)
    print("calib", cal, flush=True)
    model0 = TinyGPT100k(2)
    blob0 = model0.flat_i8()
    print("upload", len(blob0), flush=True)
    for i in range(0, NPARAM, 8):
        chunk = bytes((b & 0xFF) for b in blob0[i : i + 8])
        send(port, lm04_write_frame(i, chunk))
        if (i & 0x3FF) == 0:
            time.sleep(0.002)
            print(f"wr {i}/{NPARAM}", flush=True)
    spots = [0, 1, 16384, 18432, 83968, 100344]
    spot_ok = True
    spot_rec = []
    for a in spots:
        got = read8(port, stream, a)
        exp = [blob0[a + i] & 0xFF for i in range(min(8, NPARAM - a))]
        match = got == exp
        spot_ok = spot_ok and match
        spot_rec.append({"addr": a, "exp": exp, "got": got, "match": match})
        print("spot", a, "match", match, flush=True)
    f0 = fold(port, stream)
    print("fold0", f0, flush=True)
    send(port, lm04_payload_frame(bytes([0x32, 0, 1, 1]) + bytes(8)))
    send(port, lm04_payload_frame(bytes([0x34, 32, 3]) + bytes(9)))
    st = wait_idle(port, stream, 90.0)
    print("after_train", st, flush=True)
    f1 = fold(port, stream)
    print("fold1", f1, flush=True)
    persist = None
    f_reload = None
    if not skip_persist:
        pf = persist_flush(port, stream)
        print("persist_flush", pf, flush=True)
        pr = persist_reload(port, stream)
        print("persist_reload", pr, flush=True)
        f_reload = fold(port, stream)
        print("fold_reload", f_reload, flush=True)
        persist = {"flush": pf, "reload": pr, "fold": f_reload}
    model1 = TinyGPT100k(2)
    model1.backward_full([1], 32, lr=3, apply=True)
    ref1 = model1.flat_i8()
    banks = None
    dump_fold = None
    if do_dump:
        dumped: list[int] = []
        for addr in range(0, NPARAM, 8):
            got = read8(port, stream, addr)
            if got is None:
                banks = {"error": "dump timeout"}
                dumped = []
                break
            dumped.extend(int(b) & 0xFF for b in got[: min(8, NPARAM - addr)])
            if (addr & 0x7FF) == 0:
                print(f"dump {addr}/{NPARAM}", flush=True)
        if dumped:
            bf = bank_folds(dumped)
            rf = bank_folds(ref1)
            dump_fold = fold_bytes(dumped)
            banks = {}
            for name, off, _n in bank_slices():
                banks[name] = {
                    "board": bf[name],
                    "oracle": rf[name],
                    "match": bf[name]["xor32"] == rf[name]["xor32"]
                    and bf[name]["add32"] == rf[name]["add32"],
                    "off": off,
                }
    out = {
        "calib": cal,
        "spots": spot_rec,
        "spot_ok": spot_ok,
        "fold0": f0,
        "status": st,
        "fold1": f1,
        "persist": persist,
        "expect_fold0": EXP0,
        "expect_fold1": EXP1,
        "match0": bool(f0 and f0["xor32"] == EXP0["xor32"] and f0["add32"] == EXP0["add32"]),
        "match1": bool(f1 and f1["xor32"] == EXP1["xor32"] and f1["add32"] == EXP1["add32"]),
        "match_persist": bool(
            skip_persist
            or (
                f_reload
                and f1
                and f_reload["xor32"] == f1["xor32"]
                and f_reload["add32"] == f1["add32"]
            )
        ),
        "banks": banks,
        "dump_fold": dump_fold,
        "pred": None if not st else st.get("pred"),
        "expect_pred": 167,
    }
    print(json.dumps(out, indent=2))
    port.close()
    ok = out["match0"] and out["match1"] and spot_ok and out["match_persist"]
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())

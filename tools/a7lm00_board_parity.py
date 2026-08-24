"""A7-LM-00 remaining contract gates: 1000 logits + 20 generate on Arty UART."""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.lm05_fixed_ref import TinyGPT
from python.uart_frames import lm02_cmd_frame, lm02_ctx_frame, lm03_write_frame, xor14, FRAME_LEN, parse_frame
from python.lm.tiny_gpt_ref import BANK_WORDS
import serial

VEC = json.loads((ROOT / "results" / "golden" / "a7lm00_vectors.json").read_text(encoding="utf-8"))


def send(port, frame: bytes) -> None:
    port.write(frame)
    port.flush()


def read_frame(port, timeout_s: float):
    deadline = time.time() + timeout_s
    state = 0
    while time.time() < deadline:
        b = port.read(1)
        if not b:
            continue
        v = b[0]
        if state == 0:
            state = 1 if v == 0xA5 else 0
        elif state == 1:
            rest = port.read(FRAME_LEN - 2)
            if len(rest) != FRAME_LEN - 2:
                state = 0
                continue
            frame = bytes([0xA5, v]) + rest
            if xor14(frame) == frame[14]:
                return parse_frame(frame)
            state = 0
    return None


def wait_kind(port, kind: int, timeout_s: float = 4.0):
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        rec = read_frame(port, min(0.6, deadline - time.time()))
        if rec and rec.get("ok") and rec.get("kind") == kind:
            return rec
    return None


def load_model(port, model: TinyGPT) -> None:
    for bank, nword in BANK_WORDS.items():
        vals = model.flat_bank(bank)
        addr = 0
        while addr < nword:
            send(port, lm03_write_frame(bank, addr, bytes(v & 0xFF for v in vals[addr : addr + 8])))
            time.sleep(0.0008)
            addr += 8


def dump_logits(port) -> list[int]:
    deadline = time.time() + 0.05
    while time.time() < deadline:
        if not read_frame(port, 0.01):
            break
    send(port, lm02_cmd_frame(3))
    zs = [None] * 32
    for _ in range(16):
        rec = wait_kind(port, 0x75, 1.5)
        if not rec:
            break
        i = rec["idx"]
        if i < 31:
            zs[i] = rec["z0"]
            zs[i + 1] = rec["z1"]
    if any(v is None for v in zs):
        return []
    return [int(v) for v in zs]


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    gold = TinyGPT(seed=2)
    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.2)
    load_model(port, gold)

    n_ok = 0
    for rec in VEC["logits1000"]:
        send(port, lm02_ctx_frame(rec["toks"]))
        time.sleep(0.004)
        send(port, lm02_cmd_frame(1))
        ev = wait_kind(port, 0x74, 4.0)
        zs = dump_logits(port)
        pred_ok = ev and int(ev.get("pred") or -1) == rec["pred"]
        if zs == rec["z"] and pred_ok:
            n_ok += 1
        else:
            send(port, lm02_ctx_frame(rec["toks"]))
            time.sleep(0.002)
            send(port, lm02_cmd_frame(1))
            ev2 = wait_kind(port, 0x74, 4.0)
            zs2 = dump_logits(port)
            pred2 = ev2 and int(ev2.get("pred") or -1) == rec["pred"]
            if zs2 == rec["z"] and pred2:
                n_ok += 1
            elif n_ok < 5:
                print("logit miss", rec["i"], "pred", None if not ev else ev.get("pred"), "zlen", len(zs))

    gen_ok = 0
    for rec in VEC["generate20"]:
        seq = list(rec["prompt"])
        for _ in range(8):
            send(port, lm02_ctx_frame(seq))
            time.sleep(0.001)
            send(port, lm02_cmd_frame(1))
            ev = wait_kind(port, 0x74, 4.0)
            if not ev:
                break
            nxt = int(ev["pred"])
            seq.append(nxt)
            if nxt == 0:
                break
        if seq == rec["seq"]:
            gen_ok += 1
        elif gen_ok < 3:
            print("gen miss", rec["i"], seq, rec["seq"])

    out = {"port": port_name, "logits": f"{n_ok}/1000", "generate": f"{gen_ok}/20", "pass": n_ok == 1000 and gen_ok == 20}
    print(json.dumps(out, indent=2))
    port.close()
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

"""COM scorer for M8-LM-05. Full tiled SGD on every principal tensor.

Corpus CE is measured from FPGA logits (cmd 1 fwd + cmd 3 dumpz 0x75)
plus host shift-max softmax — not from mid-train last_loss on 0x74.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.lm.tiny_gpt_ref import (
    BANK_WORDS,
    TinyGPT,
    micro_corpus,
    train_full_sgd,
)
from python.lm.tensor_ser import sha256_i8
from python.uart_frames import (
    FRAME_LEN,
    lm02_cmd_frame,
    lm02_ctx_frame,
    lm03_write_frame,
    pack15,
    parse_frame,
    xor14,
)

import serial


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


def drain(port, timeout_s: float = 0.15) -> None:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        if not read_frame(port, min(0.05, deadline - time.time())):
            break


def load_model(port, model: TinyGPT) -> None:
    for bank, nword in BANK_WORDS.items():
        vals = model.flat_bank(bank)
        addr = 0
        while addr < nword:
            chunk = [v & 0xFF for v in vals[addr : addr + 8]]
            send(port, lm03_write_frame(bank, addr, bytes(chunk)))
            time.sleep(0.0008)
            addr += 8


def train_step(port, tokens: list[int], tgt: int, lr: int = 8):
    send(port, lm02_ctx_frame(tokens))
    time.sleep(0.001)
    send(port, lm02_cmd_frame(7, tgt, lr))
    return wait_kind(port, 0x74, 4.0)


def fwd(port, tokens: list[int]):
    send(port, lm02_ctx_frame(tokens))
    time.sleep(0.001)
    send(port, lm02_cmd_frame(1))
    return wait_kind(port, 0x74, 4.0)


def dump_logits(port) -> list[int]:
    drain(port, 0.05)
    send(port, lm02_cmd_frame(3))
    zs = [0] * 32
    got = 0
    for _ in range(16):
        rec = wait_kind(port, 0x75, 1.5)
        if not rec:
            break
        i = rec["idx"]
        if i < 31:
            zs[i] = rec["z0"]
            zs[i + 1] = rec["z1"]
            got += 2
    return zs


def ce_from_logits(z: list[int], tgt: int) -> int:
    """Same integer law as TinyGPT.softmax_shift / last_loss."""
    mx = max(z) if z else 0
    exps = [max(0, int(v) - mx + 16) for v in z]
    s = sum(exps) or 1
    return int(s - exps[tgt % 32])


def corpus_ce_fpga(port, pairs: list[tuple[list[int], int]]) -> dict:
    total = 0
    n_ok = 0
    misses = 0
    for pref, tgt in pairs:
        ev = fwd(port, pref)
        if not ev:
            misses += 1
            continue
        zs = dump_logits(port)
        if zs == [0] * 32:
            misses += 1
        total += ce_from_logits(zs, tgt)
        n_ok += 1
    return {"loss": total, "n": n_ok, "misses": misses}


def dump_grads(port) -> list[int]:
    send(port, lm02_cmd_frame(8))
    gs = [0] * 128
    for _ in range(32):
        rec = wait_kind(port, 0x78, 1.5)
        if not rec:
            break
        i = rec["idx"]
        base = i * 4
        for k, v in enumerate(rec["g"]):
            if base + k < 128:
                gs[base + k] = v
    return gs


def dump_cnt(port):
    send(port, lm02_cmd_frame(9))
    return wait_kind(port, 0x7A, 1.5)


def read_bank(port, bank: int, nword: int) -> list[int]:
    out = [0] * nword
    addr = 0
    while addr < nword:
        body = bytes([4, bank & 15, addr & 0xFF, (addr >> 8) & 15]) + bytes(8)
        send(port, pack15(0x72, body))
        rec = wait_kind(port, 0x79, 1.5)
        if rec:
            data = rec["data"]
            for k, v in enumerate(data):
                if addr + k < nword:
                    out[addr + k] = v if v < 128 else v - 256
        addr += 8
    return out


def close_grad(hw: int, rf: int) -> bool:
    d = abs(hw - rf)
    return d <= 2 or (abs(rf) > 0 and d * 20 <= abs(rf))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--out", type=Path, default=ROOT / "results" / "A7-LM-00" / "run_001")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    print("M8-LM-05 scorer: SW0 AFTER off. 7-seg 05xx. CE via dumpz logits.")

    gold = TinyGPT(seed=2)
    sha0 = gold.tensor_sha()
    pairs = micro_corpus(32)
    port = serial.Serial(args.port, args.baud, timeout=0.05)
    time.sleep(0.25)
    load_model(port, gold)
    send(port, lm02_cmd_frame(10))
    wait_kind(port, 0x74, 4.0)

    print("corpus CE before train (dumpz)...")
    ce0 = corpus_ce_fpga(port, pairs)
    print(f"  ce0={ce0}")

    pref, tgt = pairs[0]
    rec = gold.backward_full(pref, tgt, lr=8, apply=False)
    pack = gold.sample_grads128_full(rec)
    drain(port, 0.1)
    cnt_pre = dump_cnt(port)
    ev = train_step(port, pref, tgt, 8)
    drain(port, 0.05)
    cnt0 = dump_cnt(port)
    ghw = dump_grads(port)
    n_ok = sum(int(close_grad(ghw[i], pack[i])) for i in range(128))
    gold.backward_full(pref, tgt, lr=8, apply=True)

    def _u16(rec, key):
        return 0 if not rec else int(rec.get(key) or 0) & 0xFFFF

    wr_head = (_u16(cnt0, "wr_head") - _u16(cnt_pre, "wr_head")) & 0xFFFF
    wr_blk = (_u16(cnt0, "wr_frz") - _u16(cnt_pre, "wr_frz")) & 0xFFFF
    print(
        f"first_train grad_match={n_ok}/128 wr_head_d={wr_head} wr_blk_d={wr_blk} "
        f"pre={cnt_pre} post={cnt0} ev={ev}"
    )

    online = []
    for ep in range(8):
        s = 0
        for p, t in pairs:
            if ep == 0 and p == pref and t == tgt:
                s += rec["loss"]
                continue
            ev2 = train_step(port, p, t, 8)
            s += 0 if not ev2 else int(ev2.get("loss") or 0)
        online.append(s)
        print(f"epoch {ep} online_last_loss={s}")

    print("corpus CE after 8 epochs (dumpz)...")
    ce1 = corpus_ce_fpga(port, pairs)
    print(f"  ce1={ce1}")
    drop_fpga = 0.0 if ce0["loss"] == 0 else (ce0["loss"] - ce1["loss"]) / ce0["loss"]
    drop_online = 0.0 if not online or online[0] == 0 else (online[0] - online[-1]) / online[0]

    twin = TinyGPT(seed=2)
    rec_tr = train_full_sgd(twin, pairs, epochs=8, lr=8)

    moved_hw = {}
    for bank, nword in BANK_WORDS.items():
        dumped = read_bank(port, bank, nword)
        moved_hw[str(bank)] = sha256_i8(dumped) != sha0[
            {0: "tok", 1: "pos", 2: "wq", 3: "wk", 4: "wv", 5: "wo", 6: "ff1", 7: "ff2", 8: "head"}[bank]
        ]
    all_moved_hw = all(moved_hw.values())

    send(port, lm02_cmd_frame(12, 1))
    time.sleep(0.01)
    cnt1 = dump_cnt(port)
    w1 = 0 if not cnt1 else cnt1.get("wr_head", 0)
    b1 = 0 if not cnt1 else cnt1.get("wr_frz", 0)
    for p, t in pairs[:8]:
        send(port, lm02_ctx_frame(p))
        send(port, lm02_cmd_frame(7, t, 8))
        wait_kind(port, 0x74, 4.0)
    cnt2 = dump_cnt(port)
    w2 = 0 if not cnt2 else cnt2.get("wr_head", 0)
    b2 = 0 if not cnt2 else cnt2.get("wr_frz", 0)
    after_ok = bool(cnt1) and bool(cnt2) and w2 == w1 and b2 == b1

    send(port, lm02_cmd_frame(12, 0))
    send(port, lm02_cmd_frame(11))
    wait_kind(port, 0x74, 4.0)

    ok = (
        n_ok == 128
        and drop_fpga >= 0.30
        and rec_tr["all_moved"]
        and all_moved_hw
        and wr_head > 0
        and wr_blk > 0
        and after_ok
        and ce0["misses"] == 0
        and ce1["misses"] == 0
    )
    out = {
        "milestone": "M8-LM-05",
        "port": args.port,
        "grad_match_128": n_ok,
        "loss0": ce0["loss"],
        "loss1": ce1["loss"],
        "loss_drop": drop_fpga,
        "ce_method": "dumpz_softmax_shift",
        "ce0_detail": ce0,
        "ce1_detail": ce1,
        "online_loss0": online[0] if online else None,
        "online_loss1": online[-1] if online else None,
        "online_drop": drop_online,
        "loss_drop_ref": rec_tr["drop"],
        "all_moved": rec_tr["all_moved"],
        "all_moved_hw": all_moved_hw,
        "moved_hw": moved_hw,
        "wr_head": wr_head,
        "wr_blk": wr_blk,
        "wr_head_abs": _u16(cnt0, "wr_head"),
        "wr_blk_abs": _u16(cnt0, "wr_frz"),
        "after_writes0": after_ok,
        "first_ev": None if not ev else ev.get("pred"),
        "pass": ok,
        "claim": "FULL_TINY_TRANSFORMER_BACKPROP_FPGA_BOARD_VALIDATED" if ok else None,
    }
    (args.out / "board_report.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print(json.dumps(out, indent=2))
    port.close()
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())

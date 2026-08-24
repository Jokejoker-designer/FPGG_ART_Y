"""A7-LM-00 close ladder T2–T5. Same bitstream. Stop-and-wait dumpz. No RTL."""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.lm.tiny_gpt_ref import BANK_WORDS
from python.ref.lm05_fixed_ref import TinyGPT
from python.uart_frames import (
    lm02_cmd_frame,
    lm02_ctx_frame,
    lm03_write_frame,
    pack15,
    parse_frame,
)
from python.uart_stream import FrameStream
import serial

EXPECTED_Z_IDX = set(range(0, 32, 2))
VEC_PATH = ROOT / "results" / "golden" / "a7lm00_vectors.json"
_REPLAY_ROOT = os.environ.get("A7_REPLAY_ROOT")
OUT_DIR = (
    Path(_REPLAY_ROOT) / "A7-LM-00" / "ladder"
    if _REPLAY_ROOT
    else ROOT / "results" / "A7-LM-00" / "ladder"
)


def send(port, frame: bytes) -> None:
    port.write(frame)
    port.flush()


def wait_kind(stream: FrameStream, kind: int, timeout_s: float):
    deadline = time.monotonic() + timeout_s
    while time.monotonic() < deadline:
        raw = stream.get_frame(max(0.01, deadline - time.monotonic()))
        if raw is None:
            continue
        rec = parse_frame(raw.data)
        if rec.get("ok") and rec.get("kind") == kind:
            return rec
    return None


def collect_dumpz(stream: FrameStream, port, timeout_s: float = 2.0) -> dict:
    send(port, lm02_cmd_frame(3))
    logits: list[int | None] = [None] * 32
    seen: set[int] = set()
    duplicates: list[int] = []
    unexpected: list[int] = []
    deadline = time.monotonic() + timeout_s
    while seen != EXPECTED_Z_IDX and time.monotonic() < deadline:
        raw = stream.get_frame(max(0.01, deadline - time.monotonic()))
        if raw is None:
            break
        rec = parse_frame(raw.data)
        if rec.get("kind") != 0x75:
            continue
        idx = int(rec["idx"])
        if idx not in EXPECTED_Z_IDX:
            unexpected.append(idx)
            continue
        if idx in seen:
            duplicates.append(idx)
            continue
        seen.add(idx)
        logits[idx] = int(rec["z0"])
        logits[idx + 1] = int(rec["z1"])
    missing = sorted(EXPECTED_Z_IDX - seen)
    return {
        "complete": not missing,
        "logits": logits,
        "seen": sorted(seen),
        "missing": missing,
        "duplicates": duplicates,
        "unexpected": unexpected,
        "bad_crc_total": stream.bad_crc,
        "resync_bytes_total": stream.resync_bytes,
    }


def fwd_dumpz(port, stream: FrameStream, toks: list[int]) -> dict:
    send(port, lm02_ctx_frame(toks))
    send(port, lm02_cmd_frame(1))
    ev = wait_kind(stream, 0x74, 4.0)
    dump = collect_dumpz(stream, port, 2.0)
    pred = None if not ev else int(ev.get("pred"))
    zs = dump["logits"] if dump["complete"] else None
    return {"pred": pred, "dump": dump, "z": zs}


def load_model(port, model: TinyGPT, stream: FrameStream | None = None) -> None:
    for bank, nword in BANK_WORDS.items():
        vals = model.flat_bank(bank)
        addr = 0
        while addr < nword:
            send(port, lm03_write_frame(bank, addr, bytes(v & 0xFF for v in vals[addr : addr + 8])))
            time.sleep(0.0008)
            addr += 8
    send(port, lm02_cmd_frame(10))
    if stream is not None:
        wait_kind(stream, 0x74, 4.0)
        deadline = time.monotonic() + 0.05
        while time.monotonic() < deadline:
            if stream.get_frame(0.01) is None:
                break


def dump_grads(port, stream: FrameStream) -> list[int]:
    send(port, lm02_cmd_frame(8))
    gs = [0] * 128
    got = 0
    deadline = time.monotonic() + 8.0
    while got < 32 and time.monotonic() < deadline:
        rec = wait_kind(stream, 0x78, max(0.05, deadline - time.monotonic()))
        if not rec:
            break
        i = rec["idx"]
        base = i * 4
        for k, v in enumerate(rec["g"]):
            if base + k < 128:
                gs[base + k] = v
        got += 1
    return gs


def dump_cnt(port, stream: FrameStream):
    send(port, lm02_cmd_frame(9))
    return wait_kind(stream, 0x7A, 1.5)


def read_bank(port, stream: FrameStream, bank: int, nword: int) -> list[int]:
    out = [0] * nword
    addr = 0
    while addr < nword:
        body = bytes([4, bank & 15, addr & 0xFF, (addr >> 8) & 15]) + bytes(8)
        send(port, pack15(0x72, body))
        rec = wait_kind(stream, 0x79, 1.5)
        if rec:
            data = rec["data"]
            for k, v in enumerate(data):
                if addr + k < nword:
                    out[addr + k] = v if v < 128 else v - 256
        addr += 8
    return out


def ce_from_logits(z: list[int], tgt: int) -> int:
    mx = max(z) if z else 0
    exps = [max(0, int(v) - mx + 16) for v in z]
    s = sum(exps) or 1
    return int(s - exps[tgt % 32])


def train_step(port, stream: FrameStream, tokens: list[int], tgt: int, lr: int = 8):
    send(port, lm02_ctx_frame(tokens))
    send(port, lm02_cmd_frame(7, tgt, lr))
    return wait_kind(stream, 0x74, 4.0)


def open_port(name: str) -> tuple:
    port = serial.Serial(name, 115200, timeout=0.02)
    time.sleep(0.2)
    return port, FrameStream(port)


def t2(port, stream, gold_z, gold_pred) -> dict:
    exact = 0
    complete = 0
    missing_n = 0
    for _ in range(1000):
        rec = fwd_dumpz(port, stream, [2])
        if rec["dump"]["complete"]:
            complete += 1
            missing_n += len(rec["dump"]["missing"])
            if rec["z"] == gold_z and rec["pred"] == gold_pred:
                exact += 1
        else:
            missing_n += len(rec["dump"]["missing"])
    return {
        "stage": "T2_same_case",
        "exact": f"{exact}/1000",
        "dump_complete": f"{complete}/1000",
        "missing_idx_total": missing_n,
        "bad_crc": stream.bad_crc,
        "resync": stream.resync_bytes,
        "retries": 0,
        "pass": exact == 1000 and complete == 1000 and stream.bad_crc == 0,
    }


def t3(port, stream, vec) -> dict:
    a, b = vec[0], vec[1]
    exact = 0
    complete = 0
    for i in range(500):
        for rec in (a, b):
            got = fwd_dumpz(port, stream, rec["toks"])
            if got["dump"]["complete"]:
                complete += 1
                if got["z"] == rec["z"] and got["pred"] == rec["pred"]:
                    exact += 1
    return {
        "stage": "T3_alternate_01",
        "exact": f"{exact}/1000",
        "dump_complete": f"{complete}/1000",
        "bad_crc": stream.bad_crc,
        "resync": stream.resync_bytes,
        "retries": 0,
        "pass": exact == 1000 and complete == 1000,
    }


def t4(port, stream, vec) -> dict:
    exact = 0
    complete = 0
    bad = []
    for rec in vec:
        got = fwd_dumpz(port, stream, rec["toks"])
        if got["dump"]["complete"]:
            complete += 1
            if got["z"] == rec["z"] and got["pred"] == rec["pred"]:
                exact += 1
            else:
                bad.append(rec["i"])
        else:
            bad.append(rec["i"])
    return {
        "stage": "T4_golden_1000",
        "exact": f"{exact}/1000",
        "dump_complete": f"{complete}/1000",
        "n_bad": len(bad),
        "bad": bad[:20],
        "bad_crc": stream.bad_crc,
        "resync": stream.resync_bytes,
        "retries": 0,
        "pass": exact == 1000 and complete == 1000,
    }


def t5(port, stream, vec) -> dict:
    from python.lm.tensor_ser import sha256_i8
    from python.ref.lm05_fixed_ref import micro_corpus, train_full_sgd

    gold = TinyGPT(seed=2)
    load_model(port, gold, stream)
    time.sleep(0.05)
    exact = 0
    for rec in vec:
        got = fwd_dumpz(port, stream, rec["toks"])
        if got["z"] == rec["z"] and got["pred"] == rec["pred"]:
            exact += 1
    pairs = micro_corpus(32)
    ce0 = 0
    for p, t in pairs:
        got = fwd_dumpz(port, stream, p)
        ce0 += 0 if not got["z"] else ce_from_logits(got["z"], t)
    pref, tgt = pairs[0]
    recb = gold.backward_full(pref, tgt, lr=8, apply=False)
    pack = gold.sample_grads128_full(recb)
    ev = train_step(port, stream, pref, tgt, 8)
    ghw = dump_grads(port, stream)
    n_ok = sum(int(abs(ghw[i] - pack[i]) <= 2 or (abs(pack[i]) > 0 and abs(ghw[i] - pack[i]) * 20 <= abs(pack[i]))) for i in range(128))
    gold.backward_full(pref, tgt, lr=8, apply=True)
    for ep in range(8):
        for p, t in pairs:
            if ep == 0 and p == pref and t == tgt:
                continue
            train_step(port, stream, p, t, 8)
    ce1 = 0
    for p, t in pairs:
        got = fwd_dumpz(port, stream, p)
        ce1 += 0 if not got["z"] else ce_from_logits(got["z"], t)
    twin = TinyGPT(seed=2)
    rec_tr = train_full_sgd(twin, pairs, epochs=8, lr=8)
    names = {0: "tok", 1: "pos", 2: "wq", 3: "wk", 4: "wv", 5: "wo", 6: "ff1", 7: "ff2", 8: "head"}
    sha0 = TinyGPT(seed=2).tensor_sha()
    moved = {}
    for bank, nword in BANK_WORDS.items():
        dumped = read_bank(port, stream, bank, nword)
        moved[str(bank)] = sha256_i8(dumped) != sha0[names[bank]]
    send(port, lm02_cmd_frame(12, 1))
    time.sleep(0.01)
    c1 = dump_cnt(port, stream)
    w1 = 0 if not c1 else int(c1.get("wr_head") or 0)
    b1 = 0 if not c1 else int(c1.get("wr_frz") or 0)
    for p, t in pairs[:8]:
        train_step(port, stream, p, t, 8)
    c2 = dump_cnt(port, stream)
    w2 = 0 if not c2 else int(c2.get("wr_head") or 0)
    b2 = 0 if not c2 else int(c2.get("wr_frz") or 0)
    send(port, lm02_cmd_frame(12, 0))
    send(port, lm02_cmd_frame(11))
    wait_kind(stream, 0x74, 4.0)
    gen_ok = 0
    load_model(port, TinyGPT(seed=2), stream)
    for rec in json.loads(VEC_PATH.read_text(encoding="utf-8"))["generate20"]:
        seq = list(rec["prompt"])
        for _ in range(8):
            send(port, lm02_ctx_frame(seq))
            send(port, lm02_cmd_frame(1))
            evg = wait_kind(stream, 0x74, 4.0)
            if not evg:
                break
            nxt = int(evg["pred"])
            seq.append(nxt)
            if nxt == 0:
                break
        if seq == rec["seq"]:
            gen_ok += 1
    drop = 0.0 if ce0 == 0 else (ce0 - ce1) / ce0
    ok = (
        exact == 1000
        and n_ok == 128
        and gen_ok == 20
        and all(moved.values())
        and w2 == w1
        and b2 == b1
        and drop >= 0.30
    )
    return {
        "stage": "T5_final_and",
        "logits": f"{exact}/1000",
        "grads": f"{n_ok}/128",
        "generate": f"{gen_ok}/20",
        "ce0": ce0,
        "ce1": ce1,
        "ce_drop": drop,
        "all_moved_hw": all(moved.values()),
        "moved": moved,
        "after_writes0": w2 == w1 and b2 == b1,
        "first_ev": None if not ev else ev.get("pred"),
        "loss_drop_ref": rec_tr["drop"],
        "retries": 0,
        "pass": ok,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--from-stage", default="T2")
    args = ap.parse_args()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    vec_blob = json.loads(VEC_PATH.read_text(encoding="utf-8"))
    vec = vec_blob["logits1000"]
    gold = TinyGPT(seed=2)
    port, stream = open_port(args.port)
    load_model(port, gold, stream)
    report = {"port": args.port, "law_id": "lm05-signsgd-v1", "stages": []}
    order = ["T2", "T3", "T4", "T5"]
    start = order.index(args.from_stage) if args.from_stage in order else 0
    try:
        if start <= 0:
            print("T2 same-case [2] x1000...")
            r = t2(port, stream, vec[1]["z"], vec[1]["pred"])
            report["stages"].append(r)
            print(json.dumps(r))
            (OUT_DIR / "T2.json").write_text(json.dumps(r, indent=2), encoding="utf-8")
            if not r["pass"]:
                print("T2 FAIL — stop before T5 close. Continue T3/T4 for diagnosis.")
        if start <= 1:
            print("T3 alternate 0/1...")
            load_model(port, TinyGPT(seed=2), stream)
            r = t3(port, stream, vec)
            report["stages"].append(r)
            print(json.dumps(r))
            (OUT_DIR / "T3.json").write_text(json.dumps(r, indent=2), encoding="utf-8")
        if start <= 2:
            print("T4 golden 1000...")
            load_model(port, TinyGPT(seed=2), stream)
            r = t4(port, stream, vec)
            report["stages"].append(r)
            print(json.dumps(r))
            (OUT_DIR / "T4.json").write_text(json.dumps(r, indent=2), encoding="utf-8")
        t2p = all(s.get("stage") == "T2_same_case" and s["pass"] for s in report["stages"] if s.get("stage") == "T2_same_case")
        t3p = all(s.get("stage") == "T3_alternate_01" and s["pass"] for s in report["stages"] if s.get("stage") == "T3_alternate_01")
        t4p = all(s.get("stage") == "T4_golden_1000" and s["pass"] for s in report["stages"] if s.get("stage") == "T4_golden_1000")
        if start <= 3:
            if not (t2p and t3p and t4p) and start == 0:
                print("Skip T5 — T2/T3/T4 not all PASS")
                report["t5_skipped"] = True
            else:
                print("T5 final AND session...")
                r = t5(port, stream, vec)
                report["stages"].append(r)
                print(json.dumps(r))
                (OUT_DIR / "T5.json").write_text(json.dumps(r, indent=2), encoding="utf-8")
    finally:
        port.close()
    report["ladder_pass"] = all(s.get("pass") for s in report["stages"]) and not report.get("t5_skipped")
    (OUT_DIR / "summary.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"ladder_pass": report["ladder_pass"], "n_stages": len(report["stages"])}, indent=2))
    return 0 if report["ladder_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Freeze ntok=8 checkpoints vs a7lm06_fixed_ref BEFORE XSim.

PROGRAM=NO. Do not edit after the XSim that consumes these files.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm06_fixed_ref import LAW_ID, TinyGPT803k, WMEM_WORDS

BAG = Path(__file__).resolve().parent
HEX = ROOT / "tests" / "xsim" / "a7lm06_wmem.hex"
EXPECTED = ROOT / "tests" / "xsim" / "a7lm06_expected.txt"

WMEM_SHA_LOCK = "C204E55909D99370387C479C74E28C15F285FDDEE20239459D7C0EC3373001E0"
UNIT_TOKENS = [2, 0, 1, 3, 4, 5, 6, 7]
CTRL_TOKENS = [1]


def load_hex(path: Path) -> list[int]:
    blob: list[int] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s:
            continue
        b = int(s, 16) & 0xFF
        blob.append(b - 256 if b >= 128 else b)
    return blob


def sha_i16(rows: list[list[int]]) -> str:
    h = hashlib.sha256()
    for row in rows:
        for v in row:
            h.update(int(v).to_bytes(2, "little", signed=True))
    return h.hexdigest().upper()


def sha_i32(vals: list[int]) -> str:
    h = hashlib.sha256()
    for v in vals:
        h.update(int(v).to_bytes(4, "little", signed=True))
    return h.hexdigest().upper()


def write_i16_hex(path: Path, rows: list[list[int]]) -> None:
    with path.open("w", encoding="utf-8") as fh:
        for row in rows:
            for v in row:
                fh.write(f"{int(v) & 0xFFFF:04x}\n")


def prefix8(rows: list[list[int]]) -> list[list[int]]:
    return [list(r[:8]) for r in rows]


def main() -> int:
    wmem_sha = hashlib.sha256(HEX.read_bytes()).hexdigest().upper()
    if wmem_sha != WMEM_SHA_LOCK:
        print("STOP_FAIL wmem sha", wmem_sha, "want", WMEM_SHA_LOCK)
        return 2
    blob = load_hex(HEX)
    if len(blob) != WMEM_WORDS:
        print("STOP_FAIL wmem_len", len(blob))
        return 3
    gold = int(EXPECTED.read_text(encoding="utf-8").splitlines()[0])

    m = TinyGPT803k(0)
    m.load_flat(blob)
    z1, pred1 = m.forward(CTRL_TOKENS)
    if pred1 != gold:
        print("STOP_FAIL control pred", pred1, "golden", gold)
        return 4

    emb = m.embed(UNIT_TOKENS)
    caches = []
    x = emb
    for ly in m.layers:
        x, cache = m.block(x, ly)
        caches.append(cache)
    logits, pred8 = m.forward(UNIT_TOKENS)
    # forward() re-runs; pred must match last hidden
    if pred8 != max(range(len(logits)), key=lambda i: (logits[i], -i)):
        print("STOP_FAIL pred inconsistency")
        return 5

    ckpt: dict = {
        "gate": "LM06-NTOK8-KNOWNNESS-DIFF-00",
        "PROGRAM": "NO",
        "law_id": LAW_ID,
        "wmem_sha256": wmem_sha,
        "control": {
            "tokens": CTRL_TOKENS,
            "pred": int(pred1),
            "logit0": int(z1[0]),
            "golden_pred": gold,
        },
        "unit": {
            "tokens": UNIT_TOKENS,
            "pred": int(pred8),
            "logit0": int(logits[0]),
            "logits_sha256": sha_i32(logits),
            "emb_sha256": sha_i16(emb),
            "emb_prefix": prefix8(emb),
        },
        "layers": [],
    }
    write_i16_hex(BAG / "oracle_emb.hex", emb)
    write_i16_hex(BAG / "oracle_n1_l0.hex", caches[0]["n1"])
    write_i16_hex(BAG / "oracle_y_last.hex", [x[-1]])

    for li, cache in enumerate(caches):
        rec = {"ly": li}
        for name in ("xs", "n1", "q", "k", "v", "a", "h", "n2", "hid", "y"):
            rec[f"{name}_sha256"] = sha_i16(cache[name])
            rec[f"{name}_prefix"] = prefix8(cache[name])
        rec["z_heads"] = cache["z"]
        ckpt["layers"].append(rec)

    payload = json.dumps(ckpt, indent=2) + "\n"
    (BAG / "checkpoints.json").write_text(payload, encoding="utf-8")
    ckpt_sha = hashlib.sha256(payload.encode("utf-8")).hexdigest().upper()
    (BAG / "ORACLE_SHA.txt").write_text(
        f"{ckpt_sha}  checkpoints.json\n{wmem_sha}  a7lm06_wmem.hex\n",
        encoding="utf-8",
    )
    svh = BAG / "ntok8_oracle.svh"
    svh.write_text(
        "\n".join(
            [
                "// Frozen BEFORE XSim by freeze_oracle.py. Do not edit after run.",
                f"localparam int ORACLE_CTRL_PRED = {pred1};",
                f"localparam int ORACLE_UNIT_PRED = {pred8};",
                f"localparam int ORACLE_CTRL_LOGIT0 = {int(z1[0])};",
                f"localparam int ORACLE_UNIT_LOGIT0 = {int(logits[0])};",
                f"localparam int NTOK8 = 8;",
                f"localparam int D = 128;",
                "",
            ]
        ),
        encoding="utf-8",
    )
    print("CONTROL pred", pred1, "logit0", z1[0])
    print("UNIT pred", pred8, "logit0", logits[0])
    print("emb_sha", ckpt["unit"]["emb_sha256"][:16])
    print("n1_l0_sha", ckpt["layers"][0]["n1_sha256"][:16])
    print("CKPT_SHA", ckpt_sha)
    print("WROTE", BAG / "checkpoints.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""A7-LM-00 parity. Host golden first; --port later talks to Arty UART."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.lm05_fixed_ref import TinyGPT  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default=None, help="Arty COM. Omit = host-golden only.")
    ap.add_argument("--vectors", type=Path, default=ROOT / "results" / "golden" / "a7lm00_vectors.json")
    args = ap.parse_args()
    vec = json.loads(args.vectors.read_text(encoding="utf-8"))
    assert vec["law_id"] == "lm05-signsgd-v1"

    gold = TinyGPT(seed=2)
    assert gold.tensor_sha() == vec["init_sha"]

    n_ok = 0
    for rec in vec["logits1000"]:
        z, pred = gold.forward(rec["toks"])
        if [int(x) for x in z] == rec["z"] and int(pred) == rec["pred"]:
            n_ok += 1
    assert n_ok == 1000, n_ok

    g_ok = 0
    for rec in vec["grads8x128"]:
        m = TinyGPT(seed=2)
        pack = m.sample_grads128_full(m.backward_full(rec["toks"], rec["tgt"], lr=8, apply=False))
        if [int(x) for x in pack] == rec["g"]:
            g_ok += 1
    assert g_ok == 8, g_ok

    gen_ok = 0
    for rec in vec["generate20"]:
        seq = TinyGPT(seed=2).generate(rec["prompt"], max_new=8)
        if [int(x) for x in seq] == rec["seq"]:
            gen_ok += 1
    assert gen_ok == 20, gen_ok

    step = TinyGPT(seed=2)
    step.backward_full([1, 2, 3], 4, lr=8, apply=True)
    assert step.tensor_sha() == vec["one_step"]["sha1"]

    out = {
        "milestone": "A7-LM-00",
        "mode": "host_golden" if not args.port else "board_pending",
        "logits": f"{n_ok}/1000",
        "grad_cases": f"{g_ok}/8",
        "generate": f"{gen_ok}/20",
        "checkpoint_sha": "exact",
        "board": None if not args.port else "NOT WIRED — Arty UART port is the next sub-gate",
        "pass": args.port is None,
    }
    print(json.dumps(out, indent=2))
    if args.port:
        print("A7-LM-00 board UART not implemented. Do not claim PASS.", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

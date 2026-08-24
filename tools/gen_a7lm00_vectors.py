"""Emit locked A7-LM-00 golden vectors from lm05-signsgd-v1. Host only."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.lm05_fixed_ref import TinyGPT, V  # noqa: E402


def main() -> int:
    out = ROOT / "results" / "golden"
    out.mkdir(parents=True, exist_ok=True)
    gold = TinyGPT(seed=2)
    init_sha = gold.tensor_sha()

    logits = []
    rng_state = 20260817
    import random

    rng = random.Random(rng_state)
    for i in range(1000):
        n = rng.randint(1, 8)
        toks = [rng.randint(0, V - 1) for _ in range(n)]
        z, pred = gold.forward(toks)
        logits.append({"i": i, "toks": toks, "z": [int(x) for x in z], "pred": int(pred)})

    grads = []
    for i in range(8):
        n = 1 + (i % 8)
        toks = [((i + 1) * 3 + k) % V for k in range(n)]
        tgt = (16 + i) % V
        rec = TinyGPT(seed=2).backward_full(toks, tgt, lr=8, apply=False)
        pack = TinyGPT(seed=2).sample_grads128_full(rec)
        grads.append({"i": i, "toks": toks, "tgt": tgt, "g": [int(x) for x in pack], "loss": int(rec["loss"])})

    gens = []
    for i in range(20):
        prompt = [1 + (i % 15)]
        seq = TinyGPT(seed=2).generate(prompt, max_new=8)
        gens.append({"i": i, "prompt": prompt, "seq": [int(x) for x in seq]})

    step = TinyGPT(seed=2)
    sha0 = step.tensor_sha()
    rec0 = step.backward_full([1, 2, 3], 4, lr=8, apply=True)
    sha1 = step.tensor_sha()

    blob = {
        "law_id": "lm05-signsgd-v1",
        "seed": 2,
        "init_sha": init_sha,
        "logits1000": logits,
        "grads8x128": grads,
        "generate20": gens,
        "one_step": {"sha0": sha0, "sha1": sha1, "loss": int(rec0["loss"])},
    }
    (out / "a7lm00_vectors.json").write_text(json.dumps(blob), encoding="utf-8")
    meta = {
        "logits": len(logits),
        "grad_cases": len(grads),
        "generate": len(gens),
        "init_sha_tok": init_sha["tok"],
        "one_step_moved": {k: sha0[k] != sha1[k] for k in sha0},
    }
    (out / "a7lm00_vectors.meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(json.dumps(meta, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

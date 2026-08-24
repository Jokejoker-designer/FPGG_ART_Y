"""Dump A7-LM-03 init weights + expected forward for xsim. Host does not own board CE."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
import sys

sys.path.insert(0, str(ROOT))
from python.ref.a7lm03_fixed_ref import TinyGPT25k


def main() -> None:
    out = ROOT / "tests" / "xsim"
    out.mkdir(parents=True, exist_ok=True)
    m = TinyGPT25k(2)
    blob = m.flat_i8()
    hex_path = out / "a7lm03_wmem.hex"
    with hex_path.open("w", encoding="ascii") as f:
        for v in blob:
            f.write(f"{v & 0xFF:02x}\n")
    z, pred = m.forward([1])
    loss = m.last_loss([1], 16)
    fold = m.fold()
    m2 = TinyGPT25k(2)
    m2.backward_full([1], 16, lr=3, apply=True)
    fold1 = m2.fold()
    exp = {
        "pred": int(pred),
        "loss": int(loss),
        "logit0": int(z[0]),
        "fold": fold,
        "fold_after_full": fold1,
        "nparam": len(blob),
    }
    (out / "a7lm03_expected.json").write_text(json.dumps(exp, indent=2), encoding="utf-8")
    (out / "a7lm03_expected.txt").write_text(
        f"{exp['pred']}\n{exp['loss']}\n{exp['fold']['xor32']}\n{exp['fold']['add32']}\n"
        f"{fold1['xor32']}\n{fold1['add32']}\n",
        encoding="ascii",
    )
    print(json.dumps(exp, indent=2))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Emit qse_lexicon.svh from frozen lexicon.py (PREREG)."""
from pathlib import Path
from lexicon import LEX, MAX_WORD, LAW

def pack_word(w: str) -> int:
    b = w.encode("ascii")
    assert len(b) <= MAX_WORD
    v = 0
    for i, x in enumerate(b):
        v |= x << (8 * i)
    return v

def main():
    bag = Path(__file__).resolve().parent
    n = len(LEX)
    lines = [
        f"// auto-generated from lexicon.py — {LAW}. Do not hand-edit.",
        f"localparam int unsigned QSE_N_LEX = {n};",
        f"localparam int unsigned QSE_MAX_WORD = {MAX_WORD};",
        "localparam logic [7:0] QSE_CLS [0:QSE_N_LEX-1] = '{",
        ",".join(f"8'd{c}" for _, c, _ in LEX) + "};",
        "localparam logic [7:0] QSE_ID [0:QSE_N_LEX-1] = '{",
        ",".join(f"8'd{i}" for _, _, i in LEX) + "};",
        "localparam logic [7:0] QSE_LEN [0:QSE_N_LEX-1] = '{",
        ",".join(f"8'd{len(w)}" for w, _, _ in LEX) + "};",
        "localparam logic [95:0] QSE_WORD [0:QSE_N_LEX-1] = '{",
        ",".join(f"96'h{pack_word(w):024x}" for w, _, _ in LEX) + "};",
        "",
    ]
    text = "\n".join(lines)
    (bag / "qse_lexicon.svh").write_text(text, encoding="utf-8")
    rtl = bag.parents[3] / "rtl" / "native_graph" / "query" / "qse_lexicon.svh"
    rtl.write_text(text, encoding="utf-8")
    print("WROTE", bag / "qse_lexicon.svh", "and", rtl, "N", n)

if __name__ == "__main__":
    main()

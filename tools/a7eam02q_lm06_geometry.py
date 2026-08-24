"""Measure frozen Q0/Q1 on real TinyGPT803k last-token hiddens.

Tokenizer (frozen, not learned): UTF-8 bytes as token IDs in V=1024.
This is the only honest text interface — LM-06 has no Vietnamese BPE.

Weights: official host oracle TinyGPT803k(seed=2), law lm06-signsgd-v1.
C3 DDR weights were never dumped; we do not invent them.

HOLD is scored last and is NOT used to pick T / seed / encoder.

Native last-token corpus (same-k vs different-k) is a *diagnostic* bag:
that is the task LM-06 was trained to represent. Labeled NATIVE, not PARA.
"""
from __future__ import annotations

import json
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.eam.qenc import Q0_LAW, Q1_LAW, Q1_SEED, encode_q0, encode_q1, hamming64  # noqa: E402
from python.ref.a7lm06_fixed_ref import C, D, TinyGPT803k, last_token_corpus  # noqa: E402

OUT = ROOT / "results" / "A7-EAM-02Q" / "lm06_geometry.json"
HID = ROOT / "results" / "A7-EAM-02Q" / "lm06_hiddens.json"

# Frozen bags — registered before looking at distances.
PARA = [
    ("FPGA nào đang dùng?", "Board hiện tại dùng chip gì?"),
    ("Arty đang nạp bitstream nào?", "Bit hiện tại trên kit là file nào?"),
    ("Nhớ giúp câu hỏi về chip FPGA", "Lưu giúp thông tin board đang dùng chip gì"),
    ("Chip trên board tên gì?", "Kit này dùng FPGA model nào?"),
    ("What FPGA is on the board?", "Which chip is the Arty using?"),
    ("Remember the board part number", "Store the FPGA device name"),
    ("Công trình tầng 2 ống đồng", "Hạng mục ống đồng tại tầng 2"),
    ("Khi nào nghiệm thu?", "Ngày nghiệm thu là lúc nào?"),
]
UNREL = [
    ("FPGA nào đang dùng?", "Giá điều hòa phòng khách bao nhiêu?"),
    ("Board hiện tại dùng chip gì?", "Ngày nghiệm thu tầng 2 là khi nào?"),
    ("Arty đang nạp bitstream nào?", "Công nợ khách hàng A còn lại bao nhiêu?"),
    ("What FPGA is on the board?", "How much does the split AC cost?"),
    ("Remember the board part number", "Pay the supplier tomorrow"),
    ("Công trình tầng 2 ống đồng", "FPGA nào đang dùng?"),
    ("Khi nào nghiệm thu?", "Bitstream đang chạy là cái nào?"),
    ("Chip trên board tên gì?", "Hôm nay ăn gì?"),
]
HOLD = [
    ("Kit này dùng FPGA model nào?", "Chip trên board tên gì?"),
    ("Bitstream đang chạy là cái nào?", "Hôm nay ăn gì?"),
    ("Store the FPGA device name", "Pay the supplier tomorrow"),
]


def utf8_tokens(text: str) -> list[int]:
    b = text.encode("utf-8")
    if not b:
        return [0]
    return [x for x in b[-C:]]


def last_h(model: TinyGPT803k, tokens: list[int]) -> list[int]:
    hs = model.hidden_states(tokens)
    h = hs[-1]
    if len(h) != D:
        raise RuntimeError(f"hidden width {len(h)} != {D}")
    return [int(v) for v in h]


def stats(ds: list[int]) -> dict:
    if not ds:
        return {"n": 0}
    xs = sorted(ds)
    n = len(xs)
    return {
        "n": n,
        "mean": round(sum(xs) / n, 3),
        "p50": xs[n // 2],
        "p90": xs[max(0, (9 * n) // 10 - 1)],
        "min": xs[0],
        "max": xs[-1],
        "rate_le_T": {str(t): round(sum(1 for d in xs if d <= t) / n, 4) for t in (0, 1, 2, 4, 8, 16, 24, 32)},
    }


def pair_ds(model: TinyGPT803k, pairs: list[tuple[str, str]], enc) -> tuple[list[int], list[dict]]:
    ds = []
    rows = []
    for a, b in pairs:
        ha = last_h(model, utf8_tokens(a))
        hb = last_h(model, utf8_tokens(b))
        ka, kb = enc(ha), enc(hb)
        d = hamming64(ka, kb)
        ds.append(d)
        rows.append({"a": a, "b": b, "d": d, "ka": f"{ka:016x}", "kb": f"{kb:016x}", "na": len(utf8_tokens(a)), "nb": len(utf8_tokens(b))})
    return ds, rows


def native_bags(model: TinyGPT803k, enc) -> dict:
    pairs = last_token_corpus(48, seed=7)
    by_k: dict[int, list[list[int]]] = {}
    for pref, tgt in pairs:
        by_k.setdefault(tgt, []).append(pref)
    same: list[int] = []
    diff: list[int] = []
    keys = list(by_k)
    for tgt, seqs in by_k.items():
        hs = [last_h(model, s) for s in seqs]
        codes = [enc(h) for h in hs]
        for i in range(len(codes)):
            for j in range(i + 1, len(codes)):
                same.append(hamming64(codes[i], codes[j]))
        for other in keys:
            if other == tgt:
                continue
            ho = [enc(last_h(model, s)) for s in by_k[other][:2]]
            for c in codes[:2]:
                for o in ho:
                    diff.append(hamming64(c, o))
    return {"same_k": stats(same), "diff_k": stats(diff)}


def decide(q1_para: dict, q1_unrel: dict) -> dict:
    """Threshold chosen from PARA/UNREL only. HOLD is not an input."""
    mp = q1_para.get("mean")
    mu = q1_unrel.get("mean")
    tp8 = q1_para.get("rate_le_T", {}).get("8", 0)
    fp8 = q1_unrel.get("rate_le_T", {}).get("8", 1)
    sep = None if mp is None or mu is None else round(mu - mp, 3)
    # Open 02A only if PARA is clearly closer AND T=8 accepts PARA and rejects UNREL.
    open_02a = bool(
        mp is not None
        and mu is not None
        and sep is not None
        and sep >= 8
        and mp <= 8
        and tp8 >= 0.5
        and fp8 == 0.0
    )
    return {
        "mean_gap_unrel_minus_para": sep,
        "para_mean": mp,
        "unrel_mean": mu,
        "para_tp_T8": tp8,
        "unrel_fp_T8": fp8,
        "open_eam02a": open_02a,
        "reason": (
            "PARA Hamming well below UNREL and T=8 separates"
            if open_02a
            else "no usable associative geometry at HIT_MAX=8 — do not glue LM-06; Q2/representation next, not DDR"
        ),
    }


def main() -> int:
    model = TinyGPT803k(2)
    dump = {"law": "lm06-signsgd-v1", "weight_seed": 2, "d": D, "tokenizer": "utf8-bytes", "items": {}}
    report: dict = {
        "semantic_claim": False,
        "tokenizer": "utf8-bytes (V=1024 has no wordpiece; last C bytes)",
        "weights": "TinyGPT803k(seed=2) official host oracle; C3 DDR not dumped",
        "hold_unused_for_tuning": True,
        "laws": {"q0": Q0_LAW, "q1": Q1_LAW, "q1_seed": Q1_SEED},
        "bags": {"PARA": PARA, "UNREL": UNREL, "HOLD": HOLD},
    }
    for name, enc in (("q0", encode_q0), ("q1", encode_q1)):
        pds, prows = pair_ds(model, PARA, enc)
        uds, urows = pair_ds(model, UNREL, enc)
        report[name] = {
            "PARA": stats(pds),
            "UNREL": stats(uds),
            "PARA_rows": prows,
            "UNREL_rows": urows,
            "native_last_token": native_bags(model, enc),
        }
        dump["items"][name] = {"PARA": prows, "UNREL": urows}

    # HOLD last — measure only.
    hds, hrows = pair_ds(model, HOLD, encode_q1)
    report["q1"]["HOLD"] = stats(hds)
    report["q1"]["HOLD_rows"] = hrows
    report["decision"] = decide(report["q1"]["PARA"], report["q1"]["UNREL"])

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    HID.write_text(json.dumps(dump, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print("WROTE", OUT)
    print("EAM02A_OPEN" if report["decision"]["open_eam02a"] else "EAM02A_NOGO")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

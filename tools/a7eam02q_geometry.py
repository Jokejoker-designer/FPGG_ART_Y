"""A7-EAM-02Q host geometry probe.

Does NOT talk to the board and does NOT read LM-06 silicon.
Pre-registers PARA / UNREL / HOLD text bags.
Without a dumped last-token hidden file, this script only:
  - twin-checks Q0/Q1
  - reports bags
  - runs a synthetic monotonic check (close h vs far h), labeled SYNTHETIC

Real semantic numbers require a later dump of INT16 h[128] per utterance.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.eam.qenc import (  # noqa: E402
    D_MODEL,
    Q0_LAW,
    Q1_LAW,
    encode_q0,
    encode_q1,
    hamming64,
    twin_check,
)

OUT = ROOT / "results" / "A7-EAM-02Q" / "geometry_open.json"

# Pre-registered. HOLD is not used to pick seed / threshold / Q2.
PARA = [
    ("FPGA nào đang dùng?", "Board hiện tại dùng chip gì?"),
    ("Arty đang nạp bitstream nào?", "Bit hiện tại trên kit là file nào?"),
    ("Nhớ giúp câu hỏi về chip FPGA", "Lưu giúp thông tin board đang dùng chip gì"),
]
UNREL = [
    ("FPGA nào đang dùng?", "Giá điều hòa phòng khách bao nhiêu?"),
    ("Board hiện tại dùng chip gì?", "Ngày nghiệm thu tầng 2 là khi nào?"),
    ("Arty đang nạp bitstream nào?", "Công nợ khách hàng A còn lại bao nhiêu?"),
]
HOLD = [
    ("Chip trên board tên gì?", "Kit này dùng FPGA model nào?"),
    ("Bitstream đang chạy là cái nào?", "Hôm nay ăn gì?"),
]


def synth_pair(kind: str, n: int = 32) -> list[tuple[list[int], list[int]]]:
    """SYNTHETIC only — not LM hidden, not semantic evidence."""
    pairs = []
    for k in range(n):
        base = [((k * 17 + i * 3) % 200) - 100 for i in range(D_MODEL)]
        if kind == "close":
            other = list(base)
            other[k % D_MODEL] = base[k % D_MODEL] + 1
        else:
            other = [((k * 29 + i * 11 + 64) % 200) - 100 for i in range(D_MODEL)]
        pairs.append((base, other))
    return pairs


def bag_stats(pairs, enc) -> dict:
    ds = [hamming64(enc(a), enc(b)) for a, b in pairs]
    ds.sort()
    n = len(ds)
    mean = sum(ds) / n
    return {
        "n": n,
        "mean": round(mean, 3),
        "p50": ds[n // 2],
        "p90": ds[max(0, (9 * n) // 10 - 1)],
        "min": ds[0],
        "max": ds[-1],
        "fp_or_tp_at_T": {str(t): sum(1 for d in ds if d <= t) / n for t in (0, 1, 2, 4, 8)},
    }


def main() -> int:
    twin = twin_check()
    close = synth_pair("close")
    far = synth_pair("far")
    report = {
        "lane": "A7-EAM-02Q",
        "status": "OPEN",
        "semantic_evidence": False,
        "note": "PARA/UNREL are text-only until LM-06 last-token dumps exist. synth_* is not semantic.",
        "twin": twin,
        "laws": {"q0": Q0_LAW, "q1": Q1_LAW},
        "bags": {
            "PARA": PARA,
            "UNREL": UNREL,
            "HOLD": HOLD,
            "hold_unused_for_tuning": True,
        },
        "synth_q0": {"close": bag_stats(close, encode_q0), "far": bag_stats(far, encode_q0)},
        "synth_q1": {"close": bag_stats(close, encode_q1), "far": bag_stats(far, encode_q1)},
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(f"WROTE {OUT}")
    if not twin["pass"]:
        print("A7EAM02Q_TWIN_FAIL")
        return 2
    print("A7EAM02Q_OPEN_OK twin=1 semantic_evidence=0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

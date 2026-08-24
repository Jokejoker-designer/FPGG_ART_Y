"""Resource utilisation across the Arty A7-100T bitstreams built in this program.

Reads Vivado post-route utilisation reports and prints absolute counts plus the
percentage of the xc7a100t budget. Also sums the subsystems that a final
integrated Native AI V1 would have to hold at once, since that is the question
the individual numbers do not answer.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# xc7a100tcsg324-1 budget, taken from the reports' own Available column
BUDGET = {"LUT": 63400, "FF": 126800, "BRAM": 135, "DSP": 240,
          "IOB": 210, "BUFG": 32}

ROWS = [
    ("A0.3 encoder (programmed now)", "results/A7-EAM-03E/A03_SIGNED/a7eam03e_a03_utilization_route.rpt"),
    ("A0.1-T encoder", "results/A7-EAM-03E/A01T_CLOSE/a7eam03e_utilization_route.rpt"),
    ("01R router (frozen)", "build/out/a7eam01r_utilization_route.rpt"),
    ("02M episodic memory (frozen)", "build/out/a7eam02m_utilization_route.rpt"),
    ("LM-06 transformer (frozen)", "build/out/a7lm06_utilization_route.rpt"),
]

PAT = {
    "LUT": r"\|\s*Slice LUTs\s*\|\s*(\d+)\s*\|",
    "FF": r"\|\s*Slice Registers\s*\|\s*(\d+)\s*\|",
    "BRAM": r"\|\s*Block RAM Tile\s*\|\s*([\d.]+)\s*\|",
    "DSP": r"\|\s*DSPs\s*\|\s*(\d+)\s*\|",
    "IOB": r"\|\s*Bonded IOB\s*\|\s*(\d+)\s*\|",
    "BUFG": r"\|\s*BUFGCTRL\s*\|\s*(\d+)\s*\|",
}


def parse(path: Path) -> dict | None:
    if not path.exists():
        return None
    txt = path.read_text(encoding="utf-8", errors="replace")
    out = {}
    for key, pat in PAT.items():
        m = re.search(pat, txt)
        out[key] = float(m.group(1)) if m else 0.0
    return out


def main() -> int:
    keys = list(BUDGET)
    hdr = f"{'design':<32}" + "".join(f"{k:>16}" for k in keys)
    print(hdr)
    print("-" * len(hdr))
    got = {}
    for label, rel in ROWS:
        u = parse(ROOT / rel)
        if u is None:
            print(f"{label:<32}  report missing: {rel}")
            continue
        got[label] = u
        line = f"{label:<32}"
        for k in keys:
            pct = 100.0 * u[k] / BUDGET[k]
            line += f"{u[k]:>9.0f} {pct:>5.1f}%"
        print(line)

    subs = ["A0.3 encoder (programmed now)", "01R router (frozen)",
            "02M episodic memory (frozen)", "LM-06 transformer (frozen)"]
    have = [s for s in subs if s in got]
    if len(have) == len(subs):
        print()
        print("naive sum of the four subsystems a Native AI V1 must hold at once")
        print("(separate bitstreams today; this is an upper bound, shared UART/MIG")
        print(" and shared logic would be counted once in a real integration)")
        line = f"{'SUM':<32}"
        over = []
        for k in keys:
            tot = sum(got[s][k] for s in subs)
            pct = 100.0 * tot / BUDGET[k]
            line += f"{tot:>9.0f} {pct:>5.1f}%"
            if pct > 100.0:
                over.append(k)
        print(line)
        print()
        if over:
            print(f"OVER BUDGET on: {', '.join(over)} -- integration cannot be a "
                  f"simple co-instantiation")
        else:
            print("within budget on every resource, so co-instantiation is not "
                  "ruled out by area alone")
    return 0


if __name__ == "__main__":
    sys.exit(main())

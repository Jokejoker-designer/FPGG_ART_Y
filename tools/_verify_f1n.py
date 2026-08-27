#!/usr/bin/env python3
from pathlib import Path
import re
t = Path("rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv").read_text(encoding="utf-8")
print("phase_*100:", sorted(set(re.findall(r"phase\w*_100", t))))
print("w_stall*:", sorted(set(re.findall(r"\bw_stall\w*", t))))
print("hex_nib:", "hex_nib" in t)
print("6'd46 count:", t.count("6'd46"))
print("W_STALL:", "W_STALL" in t)
print("PHASE=", "PHASE=" in t or 'return "P"' in t)
# undeclared check: phase_valid_100 used?
print("phase_valid_100 count:", t.count("phase_valid_100"))
print("phase_valid_100 count:", t.count("phase_valid_100"))
# show nxt_call region
i = t.find("w_stall_100")
print(t[i - 80 : i + 200])

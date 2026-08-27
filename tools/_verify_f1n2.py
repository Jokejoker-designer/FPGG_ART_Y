#!/usr/bin/env python3
from pathlib import Path
import re
t = Path("rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv").read_text(encoding="utf-8")
print("sticky_w_stall", t.count("sticky_w_stall"))
print("latched_phase", t.count("latched_phase"))
# hex_nib function
i = t.find("function automatic logic [7:0] hex_nib")
print(t[i:i+180])
# nxt args
i = t.find("w_stall_100, phase_valid_100")
print("nxt:", repr(t[i:i+80]))
i = t.find("w_stall_ok, phase_ok")
print("args:", repr(t[i:i+60]))
# ab core
c = Path("rtl/native_graph/integrate/a7ng_native_v1_ab_core.sv").read_text(encoding="utf-8")
print("ab w_stall_o port", "w_stall_o" in c)
print("ab connect", ".w_stall(w_stall_o)" in c)

#!/usr/bin/env python3
from pathlib import Path
import re

SOC = Path("rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv")
OUT = Path("tools/_f1n_dump.txt")
t = SOC.read_text(encoding="utf-8")
parts = []

def add(title, s):
    parts.append(f"===== {title} =====\n{s}\n")

for name in ("u_f1m_probe", "u_f1l_probe", "6'd41", "6'd42", "6'd43", "sent_mask"):
    i = t.find(name)
    add(f"find:{name}@{i}", t[max(0, i - 100) : i + 350] if i >= 0 else "MISSING")

ms = list(re.finditer(r"function automatic logic \[(\d+):0\] (\w+)\(", t))
add("functions", "\n".join(f"{a.group(2)} width={a.group(1)} @{a.start()}" for a in ms))

for a in ms:
    if a.group(2) in ("hb_char", "hb_len", "hb_next", "msg_char", "msg_len", "msg_next"):
        add(a.group(2), t[a.start() : a.start() + 250])

for line in t.splitlines():
    if "sent_mask" in line:
        add("sent_mask_line", line)

OUT.write_text("\n".join(parts), encoding="utf-8")
print("ok", OUT.stat().st_size)

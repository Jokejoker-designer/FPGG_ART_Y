#!/usr/bin/env python3
from pathlib import Path
import re

soc = Path("rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv")
t = soc.read_text(encoding="utf-8")

# Fix hex_nib
old = '    return (n < 4\'d10) ? (8\'("0") + 8\'(n)) : (8\'("A") + 8\'(n - 4\'d10));'
new = '    return (n < 4\'d10) ? ("0" + 8\'(n)) : ("A" + 8\'(n - 4\'d10));'
if old not in t:
    raise SystemExit("hex_nib pattern missing: " + repr(t[t.find("hex_nib"):t.find("hex_nib")+200]))
t = t.replace(old, new, 1)

# Show hb_next call
m = re.search(r"assign nxt_sel = hb_next\([\s\S]*?\);", t)
if not m:
    raise SystemExit("no nxt_sel assign")
print("CALL:\n", m.group(0))

# If call missing w_stall_100, patch it
call = m.group(0)
if "w_stall_100" not in call:
    print("PATCHING call")
    old_c = """                           bind_busy_100, wdma_busy_100, wdma_done_100, core_busy_100,
                           pred_nz_100, core_done_100, pred_ready);"""
    new_c = """                           bind_busy_100, wdma_busy_100, wdma_done_100, core_busy_100,
                           w_stall_100, phase_valid_100,
                           pred_nz_100, core_done_100, pred_ready);"""
    if old_c not in t:
        # dump ending
        print(call[-300:])
        raise SystemExit("call end mismatch")
    t = t.replace(old_c, new_c, 1)

soc.write_text(t, encoding="utf-8")
print("hex_nib fixed; call has w_stall:", "w_stall_100" in re.search(r"assign nxt_sel = hb_next\([\s\S]*?\);", t).group(0))

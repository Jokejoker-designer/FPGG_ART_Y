#!/usr/bin/env python3
from pathlib import Path
lines = Path("rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv").read_text(encoding="utf-8").splitlines()
needles = [
    "sticky_wdma_busy, sticky_wdma_done, sticky_core_busy",
    "sticky_core_busy <=",
    "core_busy) sticky_core_busy",
    "phase_o(phase)",
    "wdma_busy_100, wdma_done_100, core_busy_100",
    "u_f1m_probe",
    "u_f1l_probe",
    "logic [44:0] sent_mask",
    "6'd42",
    "6'd43",
    "function automatic logic [7:0] hb_char",
    "function automatic logic [5:0] hb_len",
    "function automatic logic [5:0] hb_next",
    "pred_nz_100",
    "sent_mask[44]",
    "sent_mask[42]",
    "sent_mask <= 45",
    "&sent_mask[44",
    "CORE_BUSY",
    "PRED_NZ",
]
for i, l in enumerate(lines, 1):
    if any(n in l for n in needles):
        print(f"{i}: {l}")

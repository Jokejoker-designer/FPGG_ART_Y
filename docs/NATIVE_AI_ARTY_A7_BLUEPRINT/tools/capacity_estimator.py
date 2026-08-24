#!/usr/bin/env python3
"""Editable planning estimator. It does not replace synthesis/post-route evidence."""
import json
from pathlib import Path

cfg = json.loads((Path(__file__).parents[1] / "configs" / "resource_assumptions.json").read_text())
d = cfg["device"]
blocks = cfg["current_blocks"]
a = cfg["engineering_assumptions"]

base_lut = sum(v["lut"] for v in blocks.values())
base_ff = sum(v["ff"] for v in blocks.values())
base_bram = sum(v["bram"] for v in blocks.values())
base_dsp = sum(v["dsp"] for v in blocks.values())
print("Naive block sum:", base_lut, "LUT,", base_ff, "FF,", base_bram, "BRAM,", base_dsp, "DSP")

for occ in (0.85, 0.90, 0.95):
    lut_budget = int(d["lut"] * occ)
    available = lut_budget - base_lut - a["shared_graph_lut"]
    print(f"\nLUT occupancy budget {occ:.0%}: {lut_budget}, lane LUT headroom {available}")
    for lane_lut in a["lane_lut_scenarios"]:
        n = max(0, available // lane_lut)
        print(f"  {lane_lut:3d} LUT/lane -> {n} lanes (planning only)")

print("\nCompute ceilings at", d["clock_hz"], "Hz, II=1")
for lanes in (8, 16, 24, 32, 64):
    print(f"  {lanes:2d} lanes -> {lanes*d['clock_hz']/1e9:.2f} Gcandidate-scores/s")

bw = a["ddr_mixed_bytes_per_sec"]
print("\nIdeal cold DDR candidate ceilings")
for rec in a["candidate_record_bytes"]:
    print(f"  {rec:2d} B/candidate -> {bw/rec/1e6:.2f} Mcandidates/s")

ctx = a["logical_agent_context_bytes"]
print("\nLogical contexts at", ctx, "bytes/context")
for kib in (32,64,72,128,144):
    print(f"  {kib:3d} KiB -> {(kib*1024)//ctx:,} contexts")
for mib in (16,64):
    print(f"  {mib:3d} MiB DDR -> {(mib*1024*1024)//ctx:,} contexts")

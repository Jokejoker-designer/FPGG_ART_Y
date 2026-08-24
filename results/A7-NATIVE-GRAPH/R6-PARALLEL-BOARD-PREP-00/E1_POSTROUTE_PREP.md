# E1 post-route prep — no bitstream (documentation only)

**Date:** 2026-08-24T20:35:00+07:00  
**Opens after:** `NATIVE_EXISTENCE_XSIM_PASS` + auditor trio  
**This task:** **do not launch** Vivado/P&R while R6 runs  

---

## ONE UNKNOWN (E1)

Does the **actual** A+B integrated hierarchy fit `xc7a100tcsg324-1` with BRAM≤135, WNS≥0, TNS=0?

---

## Collision-safe future paths (MUST NOT touch R6)

| Resource | R6 active (FORBIDDEN) | E1 future (USE THIS) |
|----------|----------------------|----------------------|
| Vivado project dir | `build/native_v1_ab_integrate_00/` | `build/native_v1_ab_e1_cofit_00/` |
| Results / reports | `results/.../NATIVE-V1-AB-INTEGRATE-ACCEPT-00/ab_*` | `results/A7-NATIVE-GRAPH/E1-AB-COFIT-00/` |
| Checkpoints | any `ab_post_*.dcp` in R6 dir | `E1-AB-COFIT-00/ab_post_synth.dcp`, `ab_post_route.dcp` |
| XSim | `tests/xsim/xsim.dir/` | **no XSim in E1** |

**WARNING:** Existing `vivado/tcl/build_native_v1_ab_postroute.tcl` writes into `NATIVE-V1-AB-INTEGRATE-ACCEPT-00/`. **Do not run as-is during/after R6 without retargeting outdir** to `E1-AB-COFIT-00/`.

---

## Future command (documented — NOT executed now)

```powershell
# AFTER R6 close + lock release + human/Grok dispatch only
cd D:\Jetking_sem4\SEM_4\arty-a7-online-lm
# Patch outdir in Tcl OR override:
vivado -mode batch -notrace -source vivado/tcl/build_native_v1_ab_postroute_e1.tcl
# where e1 copy sets:
#   set outdir [file join $root results A7-NATIVE-GRAPH E1-AB-COFIT-00]
#   set build_dir [file join $root build native_v1_ab_e1_cofit_00]
```

Base flow reference: `vivado/tcl/build_native_v1_ab_postroute.tcl` (OOC, `SIM_FULL=0`, `A7LM06_SNAP_LUTRAM_BIND`, **no write_bitstream**).

---

## Required reports (file-backed)

| Report | Tcl / action | Output (under `E1-AB-COFIT-00/`) |
|--------|--------------|----------------------------------|
| Hierarchy utilization | `report_utilization -hierarchical` | `ab_util_hier.rpt` |
| Flat utilization | `report_utilization` | `ab_util_route.rpt` |
| BRAM ownership slice | grep `RAMB36` / `RAMB18` / `LUTRAM` per module | `BRAM_OWNERSHIP_SLICE.tsv` (manual extract) |
| Timing summary | `report_timing_summary -delay_type min_max -max_paths 20` | `ab_timing_route.rpt` |
| Setup/hold scalar | `get_timing_paths` max/min slack | `ab_postroute_metrics.txt` |
| Route status | `report_route_status` | `ab_route_status.rpt` |
| Congestion | `report_design_analysis -congestion` | `ab_congestion.rpt` |
| Control sets | `report_control_sets` | `ab_control_sets.rpt` |
| High fanout | `report_high_fanout_nets -max_nets 25` | `ab_high_fanout.rpt` |
| QoR suggestions | `report_qor_suggestions` | `ab_qor_suggestions.rpt` |
| Clock interaction | `report_clock_interaction` | `ab_clock_interaction.rpt` |

---

## Pass / fail gates (from `STATUS/E1_COFIT_CHECKLIST.md`)

| Metric | Limit |
|--------|-------|
| BRAM (RAMB36 equiv) | ≤ 135 |
| WNS | ≥ 0 |
| TNS | 0 |
| Route | complete |

**Decision:**

- FIT → proceed E2 prep; **stop** arbitrary BRAM chasing on critical path.  
- OVERFLOW → one memory experiment (E1-M) with Task owner; re-run E1 once.

---

## Mandatory DCP artifacts for E2 gate (R1)

| Artifact | Path (under `E1-AB-COFIT-00/`) | Required for E2 |
|----------|-------------------------------|-----------------|
| Post-route DCP | `ab_post_route.dcp` | **YES — mandatory** |
| DCP SHA256 | recorded in E1 CLOSEOUT + `E2_BOARD_PREP.md` manifest row 3 | **YES** |
| Lineage proof | bitstream build references same DCP + source ledger as R6 transitive TSV | **YES** |

**STOP:** E2 board programming is forbidden without file-backed DCP + SHA + lineage. No `optional` DCP path.

---

## Project A lever (not auto-applied)

`LM06-SNAPSHOT-LUTRAM-01`: full post-route **130 BRAM**, WNS +0.125 — available if E1 needs −2 BRAM class only after measured overflow.

---

## Explicit bans (this prep task)

- No `write_bitstream`  
- No Vivado launch from Cursor  
- No overwrite of R6 `xsim_ab_mig.log` or `ab_*` in ACCEPT-00 dir  
- No claim `ROUTE_PASS` from planning doc alone  

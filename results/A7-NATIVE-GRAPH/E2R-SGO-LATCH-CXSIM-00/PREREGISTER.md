# E2R-SGO-LATCH-CXSIM-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SGO_LATCH_CXSIM_DISPATCH.md`  
**Control bag:** `E2R-SGO-CXSIM-MUX-00` CLASS=`SGO_ROSE` SHA `68B32805…` (`xsim.log`); SoC F1u latch RTL  
**Class:** C-XSIM TB replica of UART `latched_sgo_f1u`  
**Board:** NOT used. No COM12. No program. No bitstream. No `vivado.exe` impl.

## Scientific frame (frozen before UNIT run)

| Field | Value |
|-------|-------|
| OBSERVATION | SGO-MUX `SGO_ROSE` (sticky=1 at dest=4). SoC UART `SGO` is `latched_sgo_f1u <= wdma_dbg_sgo` while `sticky_qgo_ui && core_busy_ui`. Silicon sequential `SGO=0`. |
| UNKNOWN | On the SGO-MUX occupancy (dest=4 grant=1 leftover SET, sticky=1), does a TB replica of `latched_sgo_f1u` equal 1? |
| H_CANDIDATE | `LATCH_MISS` — sticky=1 and latch=0 at dest=4 **and** at end (CDC / `core_busy_ui` window misses). |
| H_RIVAL | `LATCH_HIT` — latch=1 at dest=4 **or** end when sticky=1. |
| FALSIFIER | Edit SoC; C-FIX; A2; LiteScope; instantiate `soc_top`+MIG; force dest; retie `s_dma_idle`. |
| UNIT | One query. First dest=4 snapshot + end-of-settle latch vs sticky. Not a cycle farm. |
| CONTROL | SGO-MUX `SGO_ROSE` SHA `68B32805…`; SoC latch + `sync_bits` `u_core_busy_ui` / `u_qgo_ui`; `s_dma_idle=1'b0`. |
| METRICS | sticky, `core_busy`, `core_busy_ui`, `latched_sgo` at first dest=4 and at end. |

## Verdict classes (preregistered)

| Class | Meaning | Marker |
|-------|---------|--------|
| `LATCH_HIT` | dest=4 reached; latched=1 at dest=4 or end when sticky=1 | `E2R_SGO_LATCH_CXSIM_00_XSIM_PASS` |
| `LATCH_MISS` | dest=4 reached; sticky=1 and latched=0 at dest=4 **and** at end | `E2R_SGO_LATCH_CXSIM_00_XSIM_PASS` |
| `FAIL_NO_DESTWAIT` | never dest=4 | no PASS marker |

Residual (declared, not a PASS class): dest=4 reached but sticky=0 at dest=4 **and** at end. Print `CLASS=LATCH_NO_STICKY` and do **not** emit the PASS marker.

## Vehicle (TB-only vs SGO-MUX CONTROL)

Copy `tb_e2r_sgo_cxsim_mux_00.sv`. Keep mux + B1 + shared stub + `s_dma_idle=1'b0` + hold busy after 8 R. `SIM_FULL=0`. DUT-driven dest=4 only. Do not instantiate `soc_top`.

**One TB change:** replica of SoC F1u latch + existing `sync_bits` core_busy→ui and sticky_qgo→ui (same module as SoC `u_core_busy_ui` / `u_qgo_ui`). `sticky_qgo` set on TB `start` pulse (SoC `start_q` analogue). Latch: `latched_sgo_f1u <= dbg_s_go_sticky` while `sticky_qgo_ui && core_busy_ui`.

## Forbidden

- `assign r_path_idle=1`
- Force `TILE_DST` / dest
- C-FIX / A2 / B1 grant change
- LiteScope / ILA
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG
- Retie `s_dma_idle` (keep `1'b0`)
- Product RTL edit
- Board / COM12 / bitstream / JTAG
- BOARD_PASS / existence PASS
- Claim silicon `SGO=0` is GRANT-skew

## Analysis plan (before run)

- Snapshot at first DUT-driven `TILE_DST==4` on `core_clk`.
- Latch and `core_busy_ui` live on `ui_clk`; 2-FF sync to `core_clk` for the dest=4 row (same pattern as MUX sticky). Also OR the live UI bit.
- After dest-wait, settle 128 `core_clk` cycles for END metrics.
- One query = one UNIT. No cycle-farm inference.
- `C_FIX=NONE`. `BOARD_PASS` not claimed. XSim ≠ board.

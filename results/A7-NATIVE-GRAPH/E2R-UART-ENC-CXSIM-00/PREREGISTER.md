# E2R-UART-ENC-CXSIM-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_UART_ENC_DISPATCH.md`  
**Class:** C-XSIM UART encode of sealed leftover triples (hex_nib / hb_char)  
**Board:** NOT used. No COM. No program. No bitstream. No `vivado.exe` impl.  
**Product RTL:** NOT edited. `arty_a7_ng_native_v1_ab_soc_top` / MIG **not instantiated**.  
**C-FIX:** NONE (name only; not applied).

## Scientific frame (frozen before first digit sample)

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon UART (B-FIX `6023D9A3…`) prints `TILE_DST=4` `WDMA_GRANT=0` `RPATH_IDLE=0`. Stub leftover namers cannot occupy dest=4 ∧ grant=0 ∧ idle=0 (RINJ `4,0,1` / RMUX `3,0,0` / Mux `4,1,0`). |
| UNKNOWN | Do any of the three sealed XSim occupancies encode to printed digits `4,0,0`? |
| H_CANDIDATE | Yes — encode artifact (silicon string is not the occupancy). |
| H_RIVAL | No — encode is faithful; only dest=4, grant=0, idle=0 prints `4,0,0`. |
| FALSIFIER | Board F1x; instantiate `soc_top`/MIG; C-FIX; A2; product RTL; edit encode to force a digit mismatch. |
| UNIT | One encode of the three digit positions. Four drive rows are the replication axis of that single unknown (not four unknowns). |
| CONTROL | Drive dest=4, grant=0, idle=0 → must print `4,0,0`. dest=3 must print `'3'` not `'4'`. |
| METRICS | Printed dest/grant/idle chars per row; `FAITHFUL` vs `ARTIFACT`; which row if artifact. |

## Encode law (copied into TB; not edited in `rtl/**`)

From `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv`:

- `hex_nib(n)` = `(n < 10) ? ('0'+n) : ('A'+n-10)`
- `TILE_DST` digit = `hex_nib({1'b0, tile_dst_100})` — `hb_char` sel `6'd43`, i=9
- `WDMA_GRANT` digit = `hex_nib({3'b0, wdma_grant_f1v_100})` — sel `6'd62`, i=11
- `RPATH_IDLE` digit = `hex_nib({3'b0, rpath_idle_f1v_100})` — sel `6'd63`, i=11
- F1w `6'd64→BOOT` alias does **not** apply to these three lines

## Drive rows (replication axis)

| Row | dest | grant | idle | Source |
|-----|------|-------|------|--------|
| RINJ | 4 | 0 | 1 | GRANT0-RINJ |
| RMUX | 3 | 0 | 0 | GRANT0-RMUX |
| MUX | 4 | 1 | 0 | MUX after grant |
| SI | 4 | 0 | 0 | silicon claim (CONTROL) |

## Verdict classes (preregistered)

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ARTIFACT` | a non-SI row prints dest=`4` grant=`0` idle=`0` | none |
| `FAITHFUL` | only SI prints `4,0,0`; RINJ/RMUX/MUX digits match their drives | none |
| `FAIL_ENC` | SI control does not print `4,0,0` or dest=3 prints as `4` | none (name only) |

Marker `E2R_UART_ENC_CXSIM_00_XSIM_PASS` only if classified `ARTIFACT` or `FAITHFUL`.

## Vehicle

TB-only replica of `hex_nib` + `hb_char` cases 43/62/63. Drive `tile_dst_100` / `wdma_grant_f1v_100` / `rpath_idle_f1v_100`. Do **not** instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG. Do not edit `rtl/**`.

## Forbidden

- `graph_late_materialize_00` / Phase 2
- Program board / bitstream / F1x
- Edit `rtl/**`
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG
- Raise grant; apply C-FIX or A2; `assign r_path_idle=1`
- Declare `BOARD_PASS`
- Steal Grok R6 lock

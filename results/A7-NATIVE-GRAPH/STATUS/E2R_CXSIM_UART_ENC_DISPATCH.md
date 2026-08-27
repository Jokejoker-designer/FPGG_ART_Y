# E2R C-XSIM-UART-ENC — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-UART-ENC-CXSIM-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX.**

Silicon UART (B-FIX `6023D9A3…`) prints `TILE_DST=4` `WDMA_GRANT=0` `RPATH_IDLE=0`.  
Stub leftover namers cannot occupy that triple (RINJ `4,0,1` / RMUX `3,0,0` / Mux `4,1,0`).

Encode law (`arty_a7_ng_native_v1_ab_soc_top.sv`):
- `TILE_DST` digit = `hex_nib({1'b0, tile_dst_100})` (`hb_char` sel `6'd43`, i=9)
- `WDMA_GRANT` digit = `hex_nib({3'b0, wdma_grant_f1v_100})` (sel `6'd62`, i=11)
- `RPATH_IDLE` digit = `hex_nib({3'b0, rpath_idle_f1v_100})` (sel `6'd63`, i=11)
- F1w `6'd64→BOOT` alias does **not** apply to these three lines

## Scientific frame

- **OBSERVATION:** silicon digits `4,0,0`. Stub vehicle never occupies `dest=4 ∧ grant=0 ∧ idle=0`.
- **UNKNOWN:** do any of the three sealed XSim occupancies encode to digits `4,0,0`?
- **H_CANDIDATE:** yes — encode artifact (silicon string is not the occupancy).
- **H_RIVAL:** no — encode is faithful; only `dest=4, grant=0, idle=0` prints `4,0,0`.
- **FALSIFIER:** board F1x; instantiate `soc_top`/MIG; C-FIX; A2; product RTL; force a digit mismatch by editing encode.
- **UNIT:** one encode of the three digit positions. Four drive rows are the replication axis of that single unknown (not four unknowns).
- **CONTROL:** drive `dest=4, grant=0, idle=0` → must print `4,0,0` (self-check). Also dest=3 must print `'3'` not `'4'`.
- **METRICS:** printed dest/grant/idle chars for each row; `FAITHFUL` vs `ARTIFACT`; which row if artifact.

## Vehicle

TB-only replica of `hex_nib` + `hb_char` cases 43/62/63. Drive `tile_dst_100` / `wdma_grant_f1v_100` / `rpath_idle_f1v_100`. Do **not** instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG. Do not edit `rtl/**`.

Rows (one query each, same encode):

| Row | dest | grant | idle | Source |
|-----|------|-------|------|--------|
| RINJ | 4 | 0 | 1 | GRANT0-RINJ |
| RMUX | 3 | 0 | 0 | GRANT0-RMUX |
| MUX | 4 | 1 | 0 | MUX after grant |
| SI | 4 | 0 | 0 | silicon claim (CONTROL) |

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ARTIFACT` | a non-SI row prints dest=`4` grant=`0` idle=`0` | none |
| `FAITHFUL` | only SI prints `4,0,0`; RINJ/RMUX/MUX digits match their drives | none |
| `FAIL_ENC` | SI control does not print `4,0,0` or dest=3 prints as `4` | none (name only) |

Marker `E2R_UART_ENC_CXSIM_00_XSIM_PASS` only if classified `ARTIFACT` or `FAITHFUL`.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`.

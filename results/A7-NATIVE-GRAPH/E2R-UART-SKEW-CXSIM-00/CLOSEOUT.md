# E2R-UART-SKEW-CXSIM-00 (C-XSIM UART sequential-sample skew) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_UART_SKEW_DISPATCH.md`  
**Prior:** `results/A7-NATIVE-GRAPH/E2R-UART-ENC-CXSIM-00/CLOSEOUT.md` (FAITHFUL simultaneous encode)  
**Claim scope:** TB-only sequential `hex_nib` / `hb_char` 43 then 62/63 — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (no `soc_top` / MIG; no grant raise; no A2; no `assign r_path_idle=1`; F1w `6'd64→BOOT` not applied; `graph_late_materialize_00` not implemented)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon UART prints `TILE_DST=4` then later `GRANT=0` `RPATH_IDLE=0`. UART-ENC is FAITHFUL for simultaneous digits. Stub leftover namers never occupy dest=4 ∧ grant=0 ∧ idle=0 in one cycle. |
| UNKNOWN | Can dest sampled at TILE_DST-print time and grant/idle sampled later print `4,0,0` without dest having been taken from a same-cycle dest=4 ∧ grant=0 ∧ idle=0 occupancy? |
| H_CANDIDATE | Yes (`SKEW`) — serialization artifact. |
| H_RIVAL | No (`FAITHFUL_SEQ`) — only a held `4,0,0` prints `4,0,0`. |
| FALSIFIER | Board F1x; instantiate `soc_top`/MIG; C-FIX; A2; product RTL. Not used. |
| UNIT | One encode path. Hold vs mid-gap transition is the replication axis. |
| CONTROL | Hold `4,0,0` → `4,0,0`. Hold `4,0,1` → `4,0,1`. |
| METRICS | Printed digits per row; TRANS prints `4,0,0`?; same-cycle `4,0,0` before T_gi? |

## Vehicle

TB-only replica of `hex_nib` + `hb_char` cases `6'd43` (i=9), `6'd62` (i=11), `6'd63` (i=11). Dest digit frozen at T_dst; grant and idle digits taken at T_gi after a 1000 ns gap. Encode copied from `arty_a7_ng_native_v1_ab_soc_top.sv` into `tests/xsim` only. **No** `arty_a7_ng_native_v1_ab_soc_top` instance. **No** MIG. **No** `rtl/**` edit.

## UNIT digits

| Row | Drive T_dst | Drive T_gi | Printed dest,grant,idle | Prints `4,0,0`? | same-cycle 4,0,0 before T_gi? |
|-----|-------------|------------|-------------------------|-----------------|-------------------------------|
| HOLD_SI | 4,0,0 | 4,0,0 | **4,0,0** | yes | yes |
| HOLD_RINJ | 4,0,1 | 4,0,1 | **4,0,1** | no | no |
| TRANS_RINJ_IDLE | 4,0,1 | 4,0,0 | **4,0,0** | yes | **no** |

TRANS dest was sampled while drive was `4,0,1`. After dest freeze, T_gi drive became `4,0,0` (so `samecycle_any=1` at T_gi only). Dest was not re-sampled.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (marker `E2R_UART_SKEW_CXSIM_00_XSIM_PASS`) |
| VERDICT_CLASS | **SKEW** |
| C_FIX | **NONE** |
| DIGITS_HOLD_SI | **4,0,0** |
| DIGITS_HOLD_RINJ | **4,0,1** |
| DIGITS_TRANS | **4,0,0** |
| H_CANDIDATE | **supported** — sequential dest-then-grant/idle samples printed `4,0,0` while dest was taken from occupancy `4,0,1` |
| H_RIVAL | **not supported** — TRANS printed `4,0,0` without holding `4,0,0` at dest-sample time |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Evidence quotes (`xsim.log`)

```text
VEHICLE=tb_hex_nib_hb_char_43_then_62_63 NO_SOC_TOP NO_MIG C_FIX=NONE
LAW TILE_DST=hex_nib({1'b0,tile_dst_100}) sel=6'd43 i=9 sample=T_dst
LAW WDMA_GRANT=hex_nib({3'b0,wdma_grant_f1v_100}) sel=6'd62 i=11 sample=T_gi
LAW RPATH_IDLE=hex_nib({3'b0,rpath_idle_f1v_100}) sel=6'd63 i=11 sample=T_gi
LAW GAP_NS=1000 dest_frozen_at_T_dst
LAW F1w_6d64_BOOT_alias=does_not_apply
ROW=HOLD_SI drive_tdst=4,0,0 drive_tgi=4,0,0 digits=4,0,0 samecycle_before_tgi=1 samecycle_any=1
ROW=HOLD_RINJ drive_tdst=4,0,1 drive_tgi=4,0,1 digits=4,0,1 samecycle_before_tgi=0 samecycle_any=0
ROW=TRANS_RINJ_IDLE drive_tdst=4,0,1 drive_tgi=4,0,0 digits=4,0,0 samecycle_before_tgi=0 samecycle_any=1
DIGITS_HOLD_SI=4,0,0
DIGITS_HOLD_RINJ=4,0,1
DIGITS_TRANS=4,0,0
HOLD_SI_400=1 HOLD_RINJ_OK=1 TRANS_400=1
SAMECYCLE_TRANS_BEFORE_TGI=0 SAMECYCLE_TRANS_ANY=1 TRANS_NEVER_HELD_400=1
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=SKEW
VERDICT_CLASS=SKEW
E2R_UART_SKEW_CXSIM_00_XSIM_PASS verdict=SKEW c_fix=NONE
```

Log SHA256 `7CD7233066CC804EED9792F958CCFB128395D654669B1D2F9C9D2098D6C09DF5` (`xsim.log`).  
TB SHA256 `E20035CA4E2A647E21C74669480DD2A7A4CE95921F46520495C993A21E3D8660`.  
TCL SHA256 `73B6EB77D4C96E0C1DEB337C44D0A1E1E8CB25AD2BBC0919FF61B6D0B5BB007F`.  
`soc_top` SHA256 `4B446422D28046B27FAC3E1003F26B5D6574940E444563048606AD21176B7771` (read-only; not instantiated).  
Vivado 2026.1 xvlog / xelab / xsim. No `vivado.exe` impl. No board.

## Interpretation (critical)

Controls held: HOLD_SI printed `4,0,0`; HOLD_RINJ printed `4,0,1`. TRANS printed `4,0,0` after dest was frozen under drive `4,0,1` and grant/idle were sampled 1 µs later under drive `4,0,0`. Same-cycle `4,0,0` did **not** exist at dest-sample time (`SAMECYCLE_TRANS_BEFORE_TGI=0`). The printed dest digit therefore did not come from a `4,0,0` occupancy.

This bag does **not** say silicon never occupied `4,0,0`. It says: a UART-like sequential sample of dest then grant/idle can print digits `4,0,0` when dest was sampled from `4,0,1`. Silicon text `4` then later `0` `0` is therefore **not** proof of one occupancy. UART-ENC remains FAITHFUL for simultaneous digits. XSim ≠ board. Harness encode ≠ UART capture. **No C-FIX.**

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_uart_skew_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_uart_skew_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_uart_skew_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_uart_skew_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `DIGITS.tsv` | Three-row printed digits |

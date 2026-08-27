# E2R-UART-ENC-CXSIM-00 (C-XSIM UART encode of leftover triples) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_UART_ENC_DISPATCH.md`  
**Claim scope:** TB-only `hex_nib` / `hb_char` cases 43/62/63 — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (no `soc_top` / MIG; no grant raise; no A2; no `assign r_path_idle=1`; F1w `6'd64→BOOT` not applied to these three lines)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon UART (B-FIX `6023D9A3…`) prints digits `4,0,0`. Stub leftover namers cannot occupy dest=4 ∧ grant=0 ∧ idle=0 (RINJ `4,0,1` / RMUX `3,0,0` / Mux `4,1,0`). |
| UNKNOWN | Do any of the three sealed XSim occupancies encode to printed digits `4,0,0`? |
| H_CANDIDATE | Yes — encode artifact (silicon string is not the occupancy). |
| H_RIVAL | No — encode is faithful; only dest=4, grant=0, idle=0 prints `4,0,0`. |
| FALSIFIER | Board F1x; instantiate `soc_top`/MIG; C-FIX; A2; product RTL; edit encode to force a digit mismatch. Not used. |
| UNIT | One encode of the three digit positions. Four drive rows are the replication axis of that single unknown (not four unknowns). |
| CONTROL | Drive dest=4, grant=0, idle=0 → printed `4,0,0`. dest=3 printed `'3'` not `'4'`. |
| METRICS | Printed dest/grant/idle chars per row; `FAITHFUL` vs `ARTIFACT`; which row if artifact. |

## Vehicle

TB-only replica of `hex_nib` + `hb_char` cases `6'd43` (i=9), `6'd62` (i=11), `6'd63` (i=11). Drive `tile_dst_100[2:0]` / `wdma_grant_f1v_100` / `rpath_idle_f1v_100`. Encode copied from `arty_a7_ng_native_v1_ab_soc_top.sv` into `tests/xsim` only. **No** `arty_a7_ng_native_v1_ab_soc_top` instance. **No** MIG. **No** `rtl/**` edit.

## UNIT digits

| Row | Drive dest,grant,idle | Printed dest,grant,idle | Prints `4,0,0`? |
|-----|----------------------|-------------------------|-----------------|
| RINJ | 4,0,1 | **4,0,1** | no |
| RMUX | 3,0,0 | **3,0,0** | no (`dest=3` → `'3'`) |
| MUX | 4,1,0 | **4,1,0** | no |
| SI (CONTROL) | 4,0,0 | **4,0,0** | yes |

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (marker `E2R_UART_ENC_CXSIM_00_XSIM_PASS`) |
| VERDICT_CLASS | **FAITHFUL** |
| ARTIFACT | **no** (no non-SI row printed `4,0,0`) |
| C_FIX | **NONE** |
| DIGITS_RINJ | **4,0,1** |
| DIGITS_RMUX | **3,0,0** |
| DIGITS_MUX | **4,1,0** |
| DIGITS_SI | **4,0,0** |
| H_CANDIDATE | **not supported** — sealed leftover triples do not encode to silicon digits `4,0,0` |
| H_RIVAL | **supported** — only the SI control drive prints `4,0,0`; other rows match their drives |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Evidence quotes (`xsim.log`)

```text
VEHICLE=tb_hex_nib_hb_char_43_62_63 NO_SOC_TOP NO_MIG C_FIX=NONE
LAW TILE_DST=hex_nib({1'b0,tile_dst_100}) sel=6'd43 i=9
LAW WDMA_GRANT=hex_nib({3'b0,wdma_grant_f1v_100}) sel=6'd62 i=11
LAW RPATH_IDLE=hex_nib({3'b0,rpath_idle_f1v_100}) sel=6'd63 i=11
LAW F1w_6d64_BOOT_alias=does_not_apply
ROW=RINJ drive=4,0,1 digits=4,0,1
ROW=RMUX drive=3,0,0 digits=3,0,0
ROW=MUX drive=4,1,0 digits=4,1,0
ROW=SI drive=4,0,0 digits=4,0,0
DIGITS_RINJ=4,0,1
DIGITS_RMUX=3,0,0
DIGITS_MUX=4,1,0
DIGITS_SI=4,0,0
ROW_RINJ_400=0 ROW_RMUX_400=0 ROW_MUX_400=0 ROW_SI_400=1
DEST3_AS_4=0 SI_OK=1
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=FAITHFUL
VERDICT_CLASS=FAITHFUL
E2R_UART_ENC_CXSIM_00_XSIM_PASS verdict=FAITHFUL c_fix=NONE
```

Log SHA256 `9EDC1B3D705FB6D469446B5C4B65CF05F924342F887989B93A2918B3C6523B5B` (`xsim.log`).  
TB SHA256 `200AC8FFCD42BA0124F6E9D90910C5C2738133B7FAFE7BF7B1020B2AE5D7B1EA`.  
TCL SHA256 `0AF34E1ED22BD5A0218317501237560AA4AE70418ED029D30F4EBE24B1AABE7B`.  
`soc_top` SHA256 `4B446422D28046B27FAC3E1003F26B5D6574940E444563048606AD21176B7771` (read-only; not instantiated).  
Vivado 2026.1 xvlog / xelab / xsim. No `vivado.exe` impl. No board.

## Interpretation (critical)

H_RIVAL is **supported** for the preregistered encode unknown: `hex_nib` + `hb_char` cases 43/62/63 print one ASCII nibble per driven bit-vector. RINJ prints `4,0,1`, RMUX prints `3,0,0` (dest=3 is `'3'`, not `'4'`), MUX prints `4,1,0`. Only the SI control row prints `4,0,0`. Silicon UART digits `4,0,0` are therefore **not** an encode collision of the three sealed leftover occupancies.

This bag does **not** say silicon occupancy is dest=4 ∧ grant=0 ∧ idle=0. It says: if those three fields were those values, the UART digits would be `4,0,0`; and the leftover namers' sealed triples would print different digits. XSim ≠ board. Harness encode ≠ UART capture. **No C-FIX.**

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_uart_enc_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_uart_enc_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_uart_enc_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_uart_enc_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `DIGITS.tsv` | Four-row printed digits |

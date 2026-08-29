# E2R C-XSIM-UART-SKEW — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-UART-SKEW-CXSIM-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX.**

UART-ENC (a20ccc54, SHA `9EDC1B3D…`) is **FAITHFUL** for simultaneous digits.  
SoC UART sends `TILE_DST` (sel `6'd43`) then many lines later `WDMA_GRANT` (`6'd62`) and `RPATH_IDLE` (`6'd63`). Core latch is same-cycle while `core_busy`; **printed triple is sequential samples**.

## Scientific frame

- **OBSERVATION:** silicon text is `TILE_DST=4` then later `GRANT=0` `RPATH_IDLE=0`. Stub never occupies `4,0,0` in one cycle. Encode of a simultaneous drive is faithful.
- **UNKNOWN:** can dest sampled at TILE_DST-print time and grant/idle sampled at GRANT/IDLE-print time yield digits `4,0,0` without any same-cycle occupancy `dest=4 ∧ grant=0 ∧ idle=0`?
- **H_CANDIDATE:** yes (`SKEW`) — serialization artifact.
- **H_RIVAL:** no (`FAITHFUL_SEQ`) — only a held `4,0,0` prints `4,0,0`.
- **FALSIFIER:** board F1x; `soc_top`/MIG; C-FIX; A2; product RTL.
- **UNIT:** one encode path; hold vs mid-gap transition is the replication axis.
- **CONTROL:** hold `4,0,0` → print `4,0,0`; hold `4,0,1` → print `4,0,1`.
- **METRICS:** printed digits per row; whether any TRANS row prints `4,0,0`; whether a same-cycle `4,0,0` existed.

## Vehicle

TB-only `hex_nib` (same as UART-ENC). Do **not** instantiate `soc_top`. Drive dest/grant/idle. Sample dest digit at T_dst, then change drive (TRANS rows), then sample grant and idle digits at T_gi. Gap must be > 0 (legal UART gap; 1 µs is enough).

| Row | Drive at T_dst | Drive at T_gi | Expect if H_RIVAL |
|-----|----------------|---------------|-------------------|
| HOLD_SI | 4,0,0 | 4,0,0 | 4,0,0 |
| HOLD_RINJ | 4,0,1 | 4,0,1 | 4,0,1 |
| TRANS_RINJ_IDLE | 4,0,1 | 4,0,0 | 4,0,0 if SKEW |

Do not force a same-cycle `4,0,0` on TRANS before T_gi.

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `SKEW` | TRANS prints `4,0,0` and never held `4,0,0` at one time | none |
| `FAITHFUL_SEQ` | only HOLD_SI prints `4,0,0` | none |
| `FAIL_SKEW` | HOLD_SI fails or HOLD_RINJ ≠ `4,0,1` | none |

Marker `E2R_UART_SKEW_CXSIM_00_XSIM_PASS` only if `SKEW` or `FAITHFUL_SEQ`.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`.

# E2R-UART-SKEW-CXSIM-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_UART_SKEW_DISPATCH.md`  
**Prior:** `results/A7-NATIVE-GRAPH/E2R-UART-ENC-CXSIM-00/CLOSEOUT.md` (FAITHFUL simultaneous encode)  
**Class:** C-XSIM UART sequential-sample skew (hex_nib / hb_char 43 then 62/63)  
**Board:** NOT used. No COM. No program. No bitstream. No `vivado.exe` impl.  
**Product RTL:** NOT edited. `arty_a7_ng_native_v1_ab_soc_top` / MIG **not instantiated**.  
**C-FIX:** NONE (name only; not applied).  
**Phase 2 / `graph_late_materialize_00`:** not this bag.

## Scientific frame (frozen before first sequential sample)

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon UART prints `TILE_DST=4` then many lines later `WDMA_GRANT=0` `RPATH_IDLE=0`. UART-ENC is FAITHFUL for simultaneous digits. Stub leftover namers never occupy dest=4 ∧ grant=0 ∧ idle=0 in one cycle. |
| UNKNOWN | Can dest sampled at TILE_DST-print time and grant/idle sampled at GRANT/IDLE-print time yield printed digits `4,0,0` without any same-cycle occupancy dest=4 ∧ grant=0 ∧ idle=0? |
| H_CANDIDATE | Yes (`SKEW`) — serialization artifact. Printed triple is sequential samples, not one occupancy. |
| H_RIVAL | No (`FAITHFUL_SEQ`) — only a held `4,0,0` prints `4,0,0`. |
| FALSIFIER | Board F1x; instantiate `soc_top`/MIG; C-FIX; A2; product RTL; `assign r_path_idle=1`; collapse all three digits to one sample time. |
| UNIT | One encode path. Hold vs mid-gap transition is the replication axis (not three unknowns). |
| CONTROL | Hold `4,0,0` → print `4,0,0`. Hold `4,0,1` → print `4,0,1`. |
| METRICS | Printed dest/grant/idle chars per row; TRANS prints `4,0,0`?; same-cycle `4,0,0` existed on that row? |

## Encode law (copied into TB; not edited in `rtl/**`)

Same as UART-ENC, from `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` (read-only):

- `hex_nib(n)` = `(n < 10) ? ('0'+n) : ('A'+n-10)`
- `TILE_DST` digit = `hex_nib({1'b0, tile_dst_100})` — sel `6'd43`, i=9 — sampled at **T_dst**
- `WDMA_GRANT` digit = `hex_nib({3'b0, wdma_grant_f1v_100})` — sel `6'd62`, i=11 — sampled at **T_gi**
- `RPATH_IDLE` digit = `hex_nib({3'b0, rpath_idle_f1v_100})` — sel `6'd63`, i=11 — sampled at **T_gi**
- Gap T_gi − T_dst > 0 (legal UART gap; 1 µs)
- F1w `6'd64→BOOT` alias does **not** apply to these three lines

## Drive rows (replication axis)

| Row | Drive at T_dst | Drive at T_gi | Expect if H_RIVAL |
|-----|----------------|---------------|-------------------|
| HOLD_SI | 4,0,0 | 4,0,0 | 4,0,0 |
| HOLD_RINJ | 4,0,1 | 4,0,1 | 4,0,1 |
| TRANS_RINJ_IDLE | 4,0,1 | 4,0,0 | 4,0,0 if SKEW |

TRANS must not occupy dest=4 ∧ grant=0 ∧ idle=0 at any time before T_gi. T_gi drive `4,0,0` is applied only after dest has already been sampled.

## Occupancy monitor (preregistered)

`samecycle_400` on a row = dest==4 ∧ grant==0 ∧ idle==0 observed as a simultaneous drive at any time on that row (including T_gi).  
TRANS dest sample is taken while drive is `4,0,1`. If the printed triple is `4,0,0` and `samecycle_400` is false **before T_gi** and dest was not re-sampled after the transition, that is the SKEW prediction.

## Verdict classes (preregistered)

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `SKEW` | TRANS prints `4,0,0` and never held `4,0,0` at one time (no same-cycle 4,0,0 before T_gi; dest digit frozen at T_dst) | none |
| `FAITHFUL_SEQ` | only HOLD_SI prints `4,0,0` | none |
| `FAIL_SKEW` | HOLD_SI fails or HOLD_RINJ ≠ `4,0,1` | none (name only) |

Marker `E2R_UART_SKEW_CXSIM_00_XSIM_PASS` only if classified `SKEW` or `FAITHFUL_SEQ`.

## Vehicle

TB-only replica of `hex_nib` + `hb_char` cases 43/62/63. Drive `tile_dst_100` / `wdma_grant_f1v_100` / `rpath_idle_f1v_100`. Sample dest at T_dst, change drive on TRANS, sample grant and idle at T_gi. Do **not** instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG. Do not edit `rtl/**`.

## Forbidden

- `graph_late_materialize_00` / Phase 2
- Program board / bitstream / F1x
- Edit `rtl/**`
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG
- Raise grant; apply C-FIX or A2; `assign r_path_idle=1`
- Declare `BOARD_PASS`
- Steal Grok R6 lock

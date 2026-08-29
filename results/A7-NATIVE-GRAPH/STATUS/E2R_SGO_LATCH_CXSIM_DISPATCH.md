# E2R-SGO-LATCH-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-SGO-LATCH-CXSIM-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX. No LiteScope.**

Auditor [907486f8](907486f8-e7e4-4ded-9ac1-236b9645e59f): SGO-MUX **SGO_ROSE** on stub. Silicon `SGO=0` **must not** be sold as GRANT-skew. SoC UART `SGO` = `latched_sgo_f1u <= dbg_s_go_sticky` while `core_busy_ui`.

## Scientific frame

- **OBSERVATION:** Stub sticky=1 at dest=4. SoC prints latched sticky, not the live pulse. Silicon sequential `SGO=0`.
- **UNKNOWN:** on the SGO-MUX occupancy (dest=4 grant=1 leftover SET, sticky=1), does a TB replica of `latched_sgo_f1u` equal 1?
- **H_CANDIDATE:** `LATCH_MISS` — sticky=1 but latch=0 (CDC/`core_busy_ui` window misses). Can explain silicon `SGO=0` without a true `s_go` miss.
- **H_RIVAL:** `LATCH_HIT` — latch=1 whenever sticky=1. Silicon `SGO=0` is stub≠board (need COM12 atomic SGO later).
- **FALSIFIER:** edit SoC; C-FIX; A2; LiteScope; `soc_top`+MIG; force dest; retie `s_dma_idle`.
- **UNIT:** one query; first dest=4 snapshot + end-of-query latch vs sticky.
- **CONTROL:** SGO-MUX `SGO_ROSE` SHA `68B32805…`; SoC latch RTL; F1x ATOM; silicon `SGO=0`.
- **METRICS:** sticky, `core_busy`, `core_busy_ui`, latched_sgo at first dest=4 and at end.

## Vehicle

Copy `E2R-SGO-CXSIM-MUX-00` TB. **TB-only** replica of SoC F1u latch + `sync_bits`/`xpm` core_busy→ui (same 3FF idea as SoC `u_core_busy_ui`). Do not instantiate `soc_top`. Keep `s_dma_idle=1'b0`.

## Verdict

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `LATCH_HIT` | dest=4 reached; latched=1 at dest=4 or end when sticky=1 | none |
| `LATCH_MISS` | dest=4 reached; sticky=1 and latched=0 at dest=4 and at end | none |
| `FAIL_NO_DESTWAIT` | never dest=4 | none |

Marker `E2R_SGO_LATCH_CXSIM_00_XSIM_PASS` only if HIT or MISS.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`.

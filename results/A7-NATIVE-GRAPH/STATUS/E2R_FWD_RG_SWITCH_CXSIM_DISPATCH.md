# E2R-FWD-RG-SWITCH-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-FWD-RG-SWITCH-CXSIM-00/`  
**PROGRAM=NO. No RTL edit. No C-FIX.**

Prior [OSC_2ND](7ef152e0-0472-4017-a123-e2790e686e23) / audit [CLEAN](72ab2bf4-20ba-4443-8877-a5312e0737e9): ST_EMB alone is 1024 TOK + 1024 POS sets. Layers after EMB also use `waddr`. Silicon 300 s `STILL_STALL` vs ~20 min emb-only inference is still ENGINEERING_INFERENCE until after-EMB sets are counted.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | ST_EMB OSC_2ND 2047 switches, leave_emb=1. UART would print CORE_DONE if it rose. |
| UNKNOWN | from `start_fwd` to core `done`, how many TOK / POS / other-rg `waddr` sets? |
| H_CANDIDATE | `FWD_HEAVY` — after-EMB sets ≫ 0; total sets ≫ 2048 |
| H_RIVAL | `EMB_DOM` — after leave_emb, few more rg sets; total ≈ 2048 |
| FALSIFIER | `SIM_FULL=0`; stop at leave ST_EMB; SoC/MIG; C-FIX |
| UNIT | one `start_fwd` until `done` (`ctx_n=8`) |
| CONTROL | OSC_2ND tok=1024 pos=1024 leave_emb; CORE_PRED print law |
| METRICS | tok_sets, pos_sets, other_sets, rg_switches, done, cycles |

Copy the EMB-RG TB. **One change:** do not stop at leave ST_EMB. Watch until `done==1` or timeout (preregister ≥5_000_000 clk; document). Keep `SIM_FULL=1`. Hierarchical peek `st`/`waddr`. Classify other as `waddr` not in TOK or POS windows (`OFF_TOK`/`OFF_POS`/`OFF_L0` from pkg).

| Class | Meaning |
|-------|---------|
| `FWD_HEAVY` | `done=1` and (other_sets>64 or total_sets>2048+64) |
| `EMB_DOM` | `done=1` and after-EMB rg sets ≤ 64 |
| `NO_DONE` | timeout, `done=0` |
| `NO_EMB` | never ST_EMB |

Marker `E2R_FWD_RG_SWITCH_CXSIM_00_XSIM_PASS` if classified. Existence not claimed. DMA-time remains ENGINEERING_INFERENCE.

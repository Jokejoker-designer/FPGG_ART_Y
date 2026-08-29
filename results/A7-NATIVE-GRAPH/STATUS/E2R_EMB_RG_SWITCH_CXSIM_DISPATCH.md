# E2R-EMB-RG-SWITCH-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-EMB-RG-SWITCH-CXSIM-00/`  
**PROGRAM=NO. No RTL edit. No C-FIX.**

Prior [CORE_PRED](ba4453be-6720-457e-a5a2-bea602ea76ac) / audit [CLEAN](d8062956-ed95-4103-82cb-e66c9f2920ad): UART replica prints 54/55 after 51/52. REARM 300 s with no CORE_DONE means `core_done` did not rise in that window (on this print law), not PRINT_DEAD.

ST_EMB sets `waddr` TOK then POS every `(tok,dim)`. Tile holds one region. Existence bind `ctx_n=8`, `D=128` → if every access misses, DMA ≈ `8*128*(1024+128)` = 1.18e6 chunks (~20 min at 1 ms/chunk, ENGINEERING_INFERENCE). Core comment already warns TOK/POS oscillation.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | POS-only miss REGION_DONE nline=128. Silicon 300 s no CORE_DONE. ST_EMB alternates TOK/POS in RTL. |
| UNKNOWN | during one `start_fwd` ST_EMB (`ctx_n=8`), how many TOK vs POS `waddr` sets / region switches? |
| H_CANDIDATE | `OSC_2ND` — ≈ `2*ntok*D` TOK+POS sets (alternate every dim) |
| H_RIVAL | `HOLD_RG` — few switches (one TOK region + one POS for the whole emb) |
| FALSIFIER | `SIM_FULL=0` (DMA farm); SoC/MIG; C-FIX; stop before leave ST_EMB without timeout class |
| UNIT | one `start_fwd` embedding (`ctx_n=8`) |
| CONTROL | ST_EMB sub0 TOK / sub2 POS; REGION_DONE nline law |
| METRICS | tok_sets, pos_sets, rg_switches, cycles in ST_EMB, leave_emb |

Instantiate `tiny_gpt803k_core #(.SIM_FULL(1))` only (stall=0). Do **not** instantiate SoC/MIG. Hierarchical peek `st` / `waddr` (or equivalent). Load `ctx_n_in=8`, pulse `start_fwd`. Count `waddr` in TOK vs POS until `st` leaves `ST_EMB` or timeout (≥100000 clk; document).

| Class | Meaning |
|-------|---------|
| `OSC_2ND` | tok_sets≈1024 and pos_sets≈1024 (2*8*128) |
| `HOLD_RG` | rg_switches ≤ 2 |
| `OSC_OTHER` | left EMB; counts match neither |
| `NO_EMB` | never enter or never leave ST_EMB (timeout) |

Marker `E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_PASS` if classified. Existence not claimed. nline×count×MIG ms stays ENGINEERING_INFERENCE.

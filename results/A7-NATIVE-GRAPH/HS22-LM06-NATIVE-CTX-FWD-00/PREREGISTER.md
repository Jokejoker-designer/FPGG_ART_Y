# PREREGISTER — HS22-LM06-NATIVE-CTX-FWD-00

**Status:** SEALED BEFORE CANDIDATE RTL  
**Owner:** Grok / Project B (`019ffa1c-a65c-71e0-8521-7d285e7c2ffd`)  
**Lock:** `owner=grok` at seal  
**Evidence target:** `XSIM` only  
**Board / COM12 / bitstream:** **FORBIDDEN**  
**Authority:** `PROJECT_A_MEMORY_CONTRACT_V0.md`; `GROK_PLAN.md` §3; TURN Project B assignment  
**Existence-before-quality:** this gate is **existence of the bind**, not HS-02 quality / 800k / BOARD_PASS

---

## ONE UNKNOWN

Under Project A memory contract v0 (semantic TinyGPT core subset, **96 BRAM-equivalent service**, BOARD tensor **not** required for `pred`), can a **new bind adapter only** map sealed Native Global Top-8 IDs into frozen `tiny_gpt803k_core` `ctx_*` + FPGA-owned `start_fwd` and emit an evidence-dependent FPGA `pred` from `ST_ARG`, with **no** host UART `0x32/0x33/0x34`, **no** host-computed token, and **no** sticky `lm_path` in the PASS predicate?

## CONTROL (frozen before measure)

| Item | Value |
|------|--------|
| E0 `global_id[0..7]` | `9, 11, 25, 27, 41, 43, 57, 59` (SOA bench Top-8 @165; **stimulus as recorded graph output**, not host winner command) |
| E1 legal perturbation | `59, 11, 25, 27, 41, 43, 57, 9` (swap first and last of E0; same ID set) |
| Encoding | `ctx_idx=0`, `ctx_n_in=8`, `ctx_pack[8*i +: 8] = global_id[i][7:0]` (IDs fit in 8 bits). **One** `ctx_we` beat. Entity/intent **not** packed this gate. |
| Weights | `tests/xsim/a7lm06_wmem.hex` (same file as LM-06 / WM-00 CONTROL). Upload in INIT **before** exam; `mem_we=0` during exam. |
| Core | frozen `rtl/lm/tiny_gpt803k_core.sv` **unedited**, `#(.SIM_FULL(1))` |
| Memory substitution | **SIM_FULL=1** is an explicit **zero-latency** W/act/snap behavioral store. **Not** physical 96-BRAM tiles. **Not** MIG. **Does not inherit** frozen C3 BOARD recipe / K257/511/513. |
| Snapshot LUTRAM candidate | **Not structurally swapped** this gate (causality, not resource). Contract v0 allows 96-BRAM-equivalent **service**, not a requirement to P&R 96 tiles here. |
| BOARD tensor 34 | **Omitted** (contract: not required for `pred`; **no** C3 BOARD inheritance). |
| Grant | `a7ng_lm_graph_arb`: `req_lm=1`, `req_graph=0` during bind+fwd; `dual_owner_err=0` |
| Train/corpus | `start_train=0`, `start_corpus=0`, `tgt_in` **not** compared as the answer |
| UART | **No** UART module in DUT |

## H_CANDIDATE / H_RIVAL

| ID | Claim |
|----|--------|
| H_CANDIDATE | Bind + frozen core: `pred(E0) != pred(E1)` after both `done=1`; TinyGPT inst=1; start/ctx from bind under `grant_lm` |
| R1 | `pred` invariant to E (empty tok / unused ctx / constant argmax) |
| R2 | Host/UART/`tgt` is start or answer authority |
| R3 | Compose / sticky `lm_path` used as PASS |
| R4 | TinyGPT absent in hierarchy |
| R5 | `python/ref/a7lm06_fixed_ref.py` or any host oracle at compare |
| R6 | Dual GRAPH+LM owner |
| R7 | Frozen core / TermGen / scorer / Top-K / SOA edited |

## Falsifier (any one → FAIL)

- TinyGPT instance count ≠ 1  
- `ctx_we`/`start_fwd` sourced from UART or TB poke used as the Native path  
- `pred(E0)==pred(E1)` with both `done=1`  
- Host/ref computes expected token  
- PASS predicate uses `lm_path` / compose `tok_o`  
- `tiny_gpt803k_core.sv` hash changes  
- TermGen/scorer/Top-K/SOA/MIG/LOOP_STATE/frozen bits edited  
- COM12 / board  
- `dual_owner_err=1`  
- `start_train`/`start_corpus`/`mem_we` during exam  

**Indeterminate (not PASS):** `done=0` / hang / timeout on either packet.

## UNIT / CONTROL / METRICS

- **UNIT:** one independent `(E, start_fwd recipe)` pair. Cycles inside a forward are **not** replications. Minimum 2 packets (E0, E1) + negative control (E0 loaded, no `start_fwd`).  
- **METRICS (preregister):** `tiny_gpt_inst_count`; `bind_ctx_we_beats`; `bind_start_fwd`; `host_ctx_we`; `host_start_fwd`; `uart_0x32`; `uart_0x33`; `pred_E0`; `pred_E1`; `done_E0`; `done_E1`; `grant_lm`; `dual_owner_err`; `mem_we_exam`; `neg_pred_stable`.  
- **PASS_NARROW:** unknown answered (evidence-dependent FPGA `pred`); HLB clean; XSim only.  
- **FAIL:** any falsifier.  
- **LIMIT:** TinyGPT cannot complete forward under SIM_FULL in this harness (timeout) — **not** a stub PASS.

## Allowed / forbidden paths

**Allowed after seal:**

```text
rtl/native_graph/lm/a7ng_native_ctx_bind.sv          NEW
tests/xsim/tb_a7ng_hs22_native_ctx_fwd.sv            NEW
tests/xsim/run_a7ng_hs22_native_ctx_fwd.tcl          NEW
results/A7-NATIVE-GRAPH/HS22-LM06-NATIVE-CTX-FWD-00/**
```

**Forbidden:** `tiny_gpt803k_core.sv`; TermGen/scorer/Top-K/SOA/MIG; frozen bits; `LOOP_STATE.json`; board tops; UART exam as the bind.

## Claims this gate will not make

`BOARD_PASS` · HS-02 semantic · TinyGPT active on Native SoC bit · C3 BOARD inheritance · 800k · wall-clock.

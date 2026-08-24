# SOURCE_MAP — EXT-REPO-STUDY-ESP32-PLE-00

**Commit:** `0b6cc1ba76b31fb77ffcecf2d112d17729b53c7a`  
**Clone path:** `_external/` (read-only reference)

Each claim maps to source file and evidence classification. No unsourced claims.

---

## External claims

| Claim | Source | Section / symbol | Classification |
|-------|--------|------------------|----------------|
| Three tiers: core / stream / table by access pattern | `_external/src/budget.py` | L8–21 module docstring | EXT_REPO_OBSERVED |
| Stream tier = output head sequential scan | `_external/src/budget.py` | L12–16 | EXT_REPO_OBSERVED |
| Table tier = one row per token | `_external/src/budget.py` | L17–18 | EXT_REPO_OBSERVED |
| Per-token table bytes = L × ple_dim × bits/8 | `_external/src/budget.py` | L55–58 | EXT_REPO_OBSERVED |
| Output head excluded from core param_budget | `_external/src/model.py` | param_budget(), ~L229–236 | EXT_REPO_OBSERVED |
| Five ablation arms: baseline, ple, ple_notable, fatembed, bigcore | `_external/src/model.py` | L10–23 | EXT_REPO_OBSERVED |
| FFN binary search for matched core across arms | `_external/src/model.py` | make_model() ~L268–314 | EXT_REPO_OBSERVED |
| Export golden from quantized dequant weights | `_external/src/export.py` | L12–14, L107–114 | EXT_REPO_OBSERVED |
| Group-128 int4 quant incl. table | `_external/src/quantize.py` | L8–9 | EXT_REPO_OBSERVED |
| Host verify max abs diff < 0.02 | `_external/firmware/host_verify/verify.c` | L67–68 | EXT_REPO_OBSERVED |
| Host ppl gate for int8 activations | `_external/firmware/host_verify/ppl.c` | (full file) | EXT_REPO_OBSERVED |
| PSRAM sequential bandwidth probe | `_external/firmware/bandwidth_bench/bandwidth_bench.ino` | sequential scan | EXT_REPO_OBSERVED |
| Flash random row latency 512/3072 B | `_external/firmware/bandwidth_bench/bandwidth_bench.ino` | random row section | EXT_REPO_OBSERVED |
| stage_head_int8 PSRAM staging at boot | `_external/firmware/esp32_llm/esp32_llm.ino` | ~L100–117 | EXT_REPO_OBSERVED |
| Flash mmap model partition | `_external/firmware/esp32_llm/esp32_llm.ino` | ~L131–137 | EXT_REPO_OBSERVED |
| Per-token deq_row on ple_table | `_external/firmware/common/llm.h` | ~L283 | EXT_REPO_OBSERVED |
| mmap bind_q quant tensors | `_external/firmware/common/llm.h` | ~L217–244 | EXT_REPO_OBSERVED |
| Ablation runner script | `_external/experiments/run_ablation.sh` | (full file) | EXT_REPO_OBSERVED |
| Clean confirm regeneration | `_external/experiments/clean_confirm.sh` | L2–5 | EXT_REPO_OBSERVED |
| ~28.9M params decomposition | `_external/RESULTS.md` | §"What 28.9M means" ~L40–44 | EXT_REPO_MEASURED |
| PLE +0.098 nats vs baseline @ vocab 32768 | `_external/RESULTS.md` | ~L26–31 | EXT_REPO_MEASURED |
| ple_notable isolates table contribution | `_external/RESULTS.md` | ~L66–71 | EXT_REPO_MEASURED |
| ~9.5 tok/s end-to-end ESP32 | `_external/RESULTS.md` | ~L10–14 | EXT_REPO_MEASURED |
| PSRAM 60.7 MB/s measured | `_external/RESULTS.md` | bandwidth section | EXT_REPO_MEASURED |
| Flash random 512 B ~20.3 µs | `_external/RESULTS.md` | bandwidth section | EXT_REPO_MEASURED |
| Core left flash-mapped XIP in deploy | `_external/RESULTS.md` | ~L174–176 | EXT_REPO_MEASURED |
| Golden max diff 0.00001 on device | `_external/RESULTS.md` | ~L116–117 | EXT_REPO_MEASURED |
| runs/ artifacts gitignored | `_external/.gitignore` | runs/, data/*.bin | EXT_REPO_OBSERVED |
| RP2040 display UART only | `_external/README.md` | L26–27 | EXT_REPO_OBSERVED |

---

## Native AI claims (authority references only)

| Claim | Source | Classification |
|-------|--------|----------------|
| LM-06 weights DDR-resident; 132 BRAM working machinery | `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/00_CURRENT_AUTHORITY.md` §3 | NATIVE_AI_OBSERVED |
| DDR/BRAM/LUTRAM hierarchy | `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/08_MEMORY_ARCHITECTURE.md` §2 | NATIVE_AI_OBSERVED |
| MIG-METRIC-00 XSim PASS | `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` | NATIVE_AI_MEASURED |
| mig_board_r2 BOARD_MIG 16/16 PASS | `results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_mig_board_r2.md` | NATIVE_AI_MEASURED |
| ddr_wavefront_00 PASS_NARROW | `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` | NATIVE_AI_MEASURED |
| lm06_wm_00 PASS_NARROW bit-exact | `results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_lm06_wm_00.md` | NATIVE_AI_MEASURED |
| Native V1 NOT BOARD_PASS | `LOOP_STATE.json` goal + session note | NATIVE_AI_OBSERVED |

---

## Transferable implications

| Implication | Derived from | Classification |
|-------------|--------------|----------------|
| Classify memory by access pattern | budget.py + 08_MEMORY | TRANSFERABLE_PATTERN |
| Report bytes touched not just stored capacity | budget.py + AUTHORITY §3 | TRANSFERABLE_PATTERN |
| Separate sequential vs random DDR benchmarks | bandwidth_bench.ino + MIG gates | TRANSFERABLE_PATTERN |
| Golden on exact deployed representation | export.py + lm06_wm_00 | TRANSFERABLE_PATTERN |
| Hold core budget constant in ablations | model.py + scientific gates | TRANSFERABLE_PATTERN |
| Reduce data movement when DDR-bound | RESULTS profiles + ddr_wavefront limits | ENGINEERING_INFERENCE |
| Post-V1 sparse DDR adapter research | PLE arms + Native graph sparse fetch | FUTURE_RESEARCH |
| PLE for Native V1 | — | NOT_TRANSFERABLE |
| ESP32 tok/s as Arty evidence | — | NOT_TRANSFERABLE |
| External repo proves Native correctness | — | NOT_TRANSFERABLE |

---

## Inspection gap (uncertainty preserved)

| Gap | Impact |
|-----|--------|
| `runs/` not in clone | Perplexity numbers verified via RESULTS + code path only; not re-run |
| `firmware/model/*` not in clone | On-device golden not re-verified in this session |
| No live ESP32 hardware in audit | All EXT_REPO_MEASURED silicon numbers from RESULTS.md |

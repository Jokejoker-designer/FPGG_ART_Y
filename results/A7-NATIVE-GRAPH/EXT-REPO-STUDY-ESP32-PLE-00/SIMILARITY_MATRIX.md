# SIMILARITY_MATRIX — EXT-REPO-STUDY-ESP32-PLE-00

**Commit:** `0b6cc1ba76b31fb77ffcecf2d112d17729b53c7a`

Similarity classes: **HIGH** / **MEDIUM** / **LOW** / **NONE** — explained by access pattern and
verification role, not marketing parameter counts.

| External concept | External evidence | External access pattern | Native AI analogue | Similarity | Critical difference | Transferable principle | Do not transfer | Master Blueprint location | Evidence level |
|------------------|-------------------|-------------------------|-------------------|------------|---------------------|------------------------|-----------------|---------------------------|----------------|
| ESP32 dense core | `src/model.py`, `llm.h` MATVEC on quant mats | Dense random every token | LM-06 compute + BRAM weight/activation **tiles** (u_w/u_a) | **MEDIUM** | ESP32 core can live flash-XIP; Native holds bounded BRAM tiles, weights in DDR | Bounded hot compute vs cold bulk store | CPU matvec loops; flash XIP as weight store | `08_MEMORY_ARCHITECTURE.md` §2–4 | EXT_REPO_OBSERVED → TRANSFERABLE_PATTERN |
| ESP32 streamed output head | `budget.py` stream tier; `llm.h` head matvec | Full sequential scan per token | LM output / untiled sequential DDR read | **HIGH** | Native mitigates via BRAM tiling; graph domain differs | Bytes-touched dominates bandwidth | Absolute head ms/token from ESP32 | `08_MEMORY_ARCHITECTURE.md` §5–6; `11_RESOURCE_CAPACITY_THROUGHPUT.md` | EXT_REPO_OBSERVED |
| PLE sparse lookup table | `model.py` ple arms; `llm.h` deq_row on ple_table | One indexed row per token | Graph node/episode/relation sparse DDR fetch (pattern only) | **LOW** | PLE changes model law; Native V1 has frozen LM-06 + 01R/02M | Sparse random tier exists in doctrine | PLE model structure, Gemma gate law | `09_LM06_LOWBIT_OPTIMIZATION.md` (frozen); graph DDR §5 | EXT_REPO_OBSERVED → FUTURE_RESEARCH |
| PSRAM hot staging | `esp32_llm.ino` stage_head_int8; PSRAM alloc | Sequential hot buffer reuse | BRAM ping-pong tiles, wavefront buffer | **MEDIUM** | PSRAM is MB-scale; BRAM is ~135 tiles device-wide | Stage once, reuse in fast tier | PSRAM capacity/bandwidth numbers | `08_MEMORY_ARCHITECTURE.md` §2; DDR-WAVEFRONT carry-in | EXT_REPO_MEASURED (RESULTS) |
| Memory-mapped flash | `esp32_llm.ino` partition mmap; `llm.h` bind_q | XIP sequential/random via cache | DDR-resident persistent weights (LM-06) | **LOW** | Flash XIP ≠ AXI MIG DDR3; cache hides unlike FPGA explicit scheduler | Large cold store off fast tier | XIP latency model as DDR model | `08_MEMORY_ARCHITECTURE.md` §1 | EXT_REPO_OBSERVED |
| int4 storage format | `quantize.py`, group-128 int4 weights | Packed cold storage | LM-06 INT8 contract (frozen) | **MEDIUM** | Native V1 does not authorize LM quant law change | Quantize + verify before deploy | Copy quant implementation | `09_LM06_LOWBIT_OPTIMIZATION.md` | EXT_REPO_OBSERVED |
| int8 staged compute format | Head staged int8; optional LLM_INT8_ACT | Hot compute representation | BRAM compute-native tile layout | **MEDIUM** | Staging target is PSRAM not BRAM | Storage-native ≠ compute-native | int8 head staging code | `09` (FUTURE_RESEARCH for law change) | EXT_REPO_OBSERVED |
| Random-row benchmark | `bandwidth_bench.ino` flash random 512/3072 B | Sparse indexed read | Future DDR random NodeRecord/Episode probe | **HIGH** | Native has MIG sequential grid; random metadata not yet isolated | Decompose random vs sequential measurement | ESP32 µs latency as Arty ns | `11_RESOURCE_CAPACITY_THROUGHPUT.md`; MIG-METRIC-00 | EXT_REPO_OBSERVED |
| Sequential bandwidth benchmark | `bandwidth_bench.ino` PSRAM 1 MB scan | Sequential burst-friendly | MIG-METRIC-00 / mig_board_r2 4×4 grid | **HIGH** | FPGA AXI outstanding/burst axes richer than MCU scan | Measure delivery before claiming throughput | MB/s numbers cross-platform | `11`; mig_board_r2 closeout | NATIVE_AI_MEASURED + EXT_REPO_MEASURED |
| Golden export verification | `export.py`, `verify.c`, `golden.txt` | Host reference on deployed quant layout | Twin/oracle, lm06_wm_00 bit-exact CONTROL | **HIGH** | Domain differs (LM vs full graph) | Golden on exact deployed representation | Host as answer authority | `12_FAILURE_DECISION_TREE.md`; lm06_wm_00 | EXT_REPO_OBSERVED; NATIVE_AI_MEASURED |
| Core-matched ablation | `run_ablation.sh`, `model.py` 5 arms | Matched FFN binary search | Scientific one-unknown gates | **HIGH** | MCU training domain ≠ Native teacher-off exam | Hold scarce resource constant | Perplexity arms as Native V1 law | `02_IMPLEMENTATION_ROADMAP.md`; LOOP method | EXT_REPO_OBSERVED |
| Dual-core output split | `esp32_llm.ino` head row split across LX7 | CPU thread parallelism | 16-lane graph scorer | **LOW** | CPU threads ≠ FPGA PE pipeline; different bottleneck | Parallelism only after delivery sufficient | Map cores → PEs 1:1 | `01_SYSTEM_BLUEPRINT.md` (logical vs physical agents) | NOT_TRANSFERABLE |
| TinyStories model | `data/prepare.py`, training scripts | LM training domain | Native V1 retrieval/LM exam domain | **NONE** | Different task, law, evidence class | — | Training domain transfer | OUT_OF_SCOPE | NOT_TRANSFERABLE |
| RP2040 display node | `rp2040_display_node.ino` UART OLED | Serial sink only | NONE (GlassBox out of Native V1 scope) | **NONE** | Display plumbing, not memory architecture | — | RP2040 as compute peer | OUT_OF_SCOPE | NOT_TRANSFERABLE |

---

## Similarity class definitions

| Class | Meaning |
|-------|---------|
| **HIGH** | Same *engineering question* (e.g., sequential vs random traffic, golden-on-export) even if implementation differs |
| **MEDIUM** | Analogous tier role (hot staging, quant formats) with material hierarchy differences |
| **LOW** | Superficial vocabulary match (mmap, "params") masking different mechanisms |
| **NONE** | No valid Native V1 analogue; do not force mapping |

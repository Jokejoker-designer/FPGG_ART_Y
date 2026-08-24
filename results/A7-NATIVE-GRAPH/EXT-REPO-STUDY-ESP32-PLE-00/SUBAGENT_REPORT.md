# SUBAGENT_REPORT — external-memory-architecture-researcher

**Subagent ID:** bc583830-095c-47f5-8eef-6028cb030c01  
**Scope:** READ-ONLY external repository inspection  
**Read-only confirmation:** No Native AI RTL, algorithms, or `LOOP_STATE.json` modified  
**Commit:** `0b6cc1ba76b31fb77ffcecf2d112d17729b53c7a`

---

This file preserves the subagent's technical handoff with uncertainty intact.
Parent synthesis lives in sibling artifacts; this document is the authoritative raw report.

## META

| Field | Value |
|---|---|
| **Commit SHA inspected** | `0b6cc1ba76b31fb77ffcecf2d112d17729b53c7a` |
| **Evidence gap** | `.gitignore` excludes `runs/`, `data/*.bin`, `firmware/model/*` — perplexity/on-chip numbers in `RESULTS.md` are methodology-verifiable from code but artifact files are absent from clone |

### Files inspected (minimum + verification)

**Mandatory minimum:** README.md, RESULTS.md, src/budget.py, src/model.py, src/export.py,
src/quantize.py, firmware/common/llm.h, firmware/esp32_llm/esp32_llm.ino,
firmware/bandwidth_bench/bandwidth_bench.ino, experiments/run_ablation.sh,
experiments/clean_confirm.sh

**Additional:** firmware/host_verify/verify.c, firmware/host_verify/ppl.c,
firmware/esp32_llm/partitions.csv, src/train.py, src/analyze.py,
experiments/run_ple_dim_sweep.sh, firmware/rp2040_display_node/rp2040_display_node.ino,
firmware/rp2040_tinylm/README.md, .gitignore

---

## A. Access-pattern partitioning

**Finding:** Three-tier taxonomy by access pattern in `src/budget.py` L8–21:

- **core** — dense, random, every token → SRAM-scarce budget  
- **stream** — dense sequential scan per token (output head) → bandwidth-bound, off-chip OK  
- **table** — sparse one row per token (PLE) → flash mmap  

`model.py` excludes tied output head from core budget so large vocabularies are classified as
**slow**, not **unaffordable in SRAM**.

**Conflict (documented, not reconciled):** `budget.py` states core must be SRAM-resident, but
`RESULTS.md` reports polished firmware leaves quantized core **flash-mapped XIP** because staging
0.29 MB to PSRAM saved only 1.4 ms/token. Planning doctrine ≠ measured deployment tradeoff.

**Classification:** EXT_REPO_OBSERVED (tier definitions); EXT_REPO_MEASURED (core-in-flash experiment in RESULTS).

---

## B. Bytes touched vs stored parameters

- **Stored:** ~559K core + ~3.1M stream head + ~25M PLE table (RESULTS.md)  
- **Per-token touch:** full head scan + one PLE row via `deq_row()` (`llm.h`)  
- `budget.py` L55–58: `table_row_b = n_layers * ple_dim * bits/8` — bytes-touched model  

**Native AI parallel:** LM-06 persistent weights already DDR-resident; problem is BRAM working
machinery (~132 tiles), not stored capacity. **Classification:** TRANSFERABLE_PATTERN.

**Required statement:** Stored parameter count is not sufficient to compare computational or
semantic capability of ESP32 PLE TinyLM vs Native AI LM-06 + graph stack.

---

## C. Hot staging

| Hot asset | Placement | Mechanism |
|---|---|---|
| Output head | PSRAM int8 | `stage_head_int8()` once at boot |
| Scratch + KV | PSRAM | `MALLOC_CAP_SPIRAM` |
| PLE table + core weights | Flash mmap | `esp_partition_mmap` + `bind_q` |
| Token embed row | Flash on demand | `deq_row(&m->tok_emb, token, …)` per token |

Rejected: staging remaining core to PSRAM — 1.4% gain (RESULTS.md).

**Native mapping:** BRAM bounded working set; LUTRAM ultra-hot control. **Classification:** TRANSFERABLE_PATTERN.

---

## D. Benchmark decomposition

`bandwidth_bench.ino` probes:

1. PSRAM sequential bandwidth (1 MB scan)  
2. Internal SRAM sequential  
3. Flash random row latency (512 B and 3072 B rows)  

**Nuance:** Bench uses 6×512 B random reads as conservative table cost; firmware does one
`deq_row` per token — bench is pessimistic.

**Classification:** EXT_REPO_OBSERVED (code); EXT_REPO_MEASURED (numbers in RESULTS only).

---

## E. Bottleneck migration

Documented progression: naive scalar → PSRAM fp32 head → int8 head + dual-core → PSRAM
bandwidth-bound. Profile states head is bandwidth-bound after int8 staging; next levers are
bytes-read reduction, not more scalar cleanup.

**Classification:** EXT_REPO_MEASURED (RESULTS profiles).

---

## F. Golden / export verification

Chain: `export.py` → `model.bin` + `golden.txt` → `verify.c` (max abs diff < 0.02) →
`ppl.c` int8 activation gate → same `llm.h` on device.

Export golden uses fully quantized dequant weights to isolate port error from quant error.

**Native parallel:** Twin/oracle bit-exact discipline — same verification *class*, different domain.

**Classification:** EXT_REPO_OBSERVED + TRANSFERABLE_PATTERN.

---

## G. Controlled ablation

Arms in `model.py`: baseline, ple, ple_notable, fatembed, bigcore.  
`make_model()` binary-searches `ffn_hidden` for matched core budget.  
`clean_confirm.sh` regenerates under consistent accounting.  
`analyze.py` prints Q1–Q4 decision deltas.

**Classification:** EXT_REPO_OBSERVED; perplexity outcomes EXT_REPO_MEASURED (RESULTS; `runs/` absent).

---

## H. Stored params vs compute

28.9M stored ≠ 28.9M active dense compute. PLE table adds flash capacity with O(1) row touch;
dense core ~559K sets domain ceiling. `bigcore` vs `ple` shows table is flash-abundant capacity,
not free quality.

**Classification:** EXT_REPO_OBSERVED + EXT_REPO_MEASURED.

---

## README vs implementation conflicts

| Topic | README / budget | Implementation / RESULTS |
|---|---|---|
| Core placement | Must fit SRAM | Deploy: core flash XIP |
| Table fetch | Bench 6×512 B | One deq_row per token |
| Training artifacts | RESULTS cites runs/* | runs/ gitignored |

---

## Executive conclusion (subagent)

Strong reference for **memory-hierarchy engineering method**. Not a reference for Native V1
architecture, model law, or performance numbers. Transferable content **reinforces existing**
Master Blueprint doctrine. PLE remains POST-NATIVE-V1 RESEARCH_ONLY.

**Uncertainty preserved:** On-chip tok/s and perplexity numbers not re-run in this audit session;
trusted only via RESULTS.md + code path verification.

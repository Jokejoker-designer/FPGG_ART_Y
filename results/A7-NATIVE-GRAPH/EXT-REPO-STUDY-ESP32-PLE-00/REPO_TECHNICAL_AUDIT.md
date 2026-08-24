# REPO_TECHNICAL_AUDIT — chilly23/RP2040-and-ESP32-AI

**Commit:** `0b6cc1ba76b31fb77ffcecf2d112d17729b53c7a`  
**Evidence class:** EXTERNAL_RESEARCH (not Native AI evidence)

---

## 1. Repository summary

Two-board embedded demo: ESP32-S3 runs a ~28.9M-parameter PLE TinyLM; RP2040 is UART OLED
display only. Training/export on host; inference on MCU. Architecture centers on **three-tier memory
accounting** (core / stream / table) by access pattern, not capacity alone.

---

## 2. Section A — Access-pattern memory partitioning

**EXT_REPO_OBSERVED:** `src/budget.py` L8–21 defines core (dense random, every token),
stream (dense sequential scan — output head), table (sparse one row per token).

**EXT_REPO_OBSERVED:** `src/model.py` `param_budget()` excludes tied output head from core so
vocab scaling is classified as bandwidth cost, not SRAM impossibility.

**EXT_REPO_MEASURED:** `RESULTS.md` documents deployment where quantized core remains
flash-mapped XIP despite SRAM planning constraint — explicit bottleneck tradeoff.

**Native AI analogue:** DDR persistent store vs BRAM active working set vs LUTRAM ultra-hot
(`08_MEMORY_ARCHITECTURE.md` §2). **ALREADY PRESENT** — external repo reinforces, does not invent.

**Critical difference:** ESP32 uses CPU cache + mmap flash + PSRAM; Native AI uses explicit
AXI MIG DDR + BRAM scheduler. **Do not collapse hierarchies.**

---

## 3. Section B — Total capacity vs bytes touched per query

**EXT_REPO_OBSERVED:** `budget.py` L55–58 computes `table_row_b` and sequential head bytes per token.

**EXT_REPO_MEASURED:** RESULTS.md decomposes 28.9M into ~559K core + ~3.1M stream + ~25M table
with per-token touch dominated by head scan + one table row.

**TRANSFERABLE_PATTERN:** Future Native AI experiments should report:

- stored bytes (DDR capacity)  
- bytes touched per query / per token  
- random fetch count vs sequential bytes  
- useful bytes vs metadata bytes  
- reuse distance  

**Do not invent Native AI values in this gate.**

**NATIVE_AI_OBSERVED:** LM-06 weights already DDR-resident; BRAM problem is working machinery
(`00_CURRENT_AUTHORITY.md` Correction #1).

---

## 4. Section C — Hot representation staging

**EXT_REPO_OBSERVED:** `esp32_llm.ino` stages output head int4→int8 in PSRAM once at boot;
scratch/KV in PSRAM; weights/table mmap from flash.

**EXT_REPO_MEASURED:** Staging full core to PSRAM rejected (+1.4% gain only).

**TRANSFERABLE_PATTERN:**

- DDR LM tile → BRAM compute-native tile → MAC reuse (LM06-WM doctrine)  
- DDR compact graph cue → BRAM candidate wavefront → parallel score reuse (DDR-WAVEFRONT direction)

**FUTURE_RESEARCH ONLY:** Low-bit LM-06 staging modifications — LM-06 frozen semantics remain authority.

---

## 5. Section D — Memory benchmark decomposition

**EXT_REPO_OBSERVED:** `firmware/bandwidth_bench/bandwidth_bench.ino` separates:

- PSRAM sequential bandwidth  
- internal SRAM sequential  
- flash random row latency (512 B, 3072 B)  

**EXT_REPO_MEASURED:** RESULTS.md: PSRAM ~60.7 MB/s; flash random 512 B ~20.3 µs; synthetic
table cost ≪ head cost.

**TRANSFERABLE_PATTERN — recommended Native measurement dimensions (not yet all measured):**

| Dimension | Native AI relevance |
|-----------|---------------------|
| Sequential burst bandwidth | MIG-METRIC-00, mig_board_r2 (DONE) |
| Random NodeRecord latency | Future graph metadata gate |
| Random Episode latency | Future episodic fetch gate |
| Burst-start overhead | MIG 4×4 grid partial coverage |
| Outstanding-depth effect | mig_board_r2 grid |
| Read/write asymmetry | Learning writeback (future) |
| Compute-overlap efficiency | DDR-WAVEFRONT-00 (XSim PASS_NARROW) |

---

## 6. Section E — Bottleneck migration

**EXT_REPO_MEASURED:** RESULTS optimization table: 1757 ms/token naive → ~103 ms after int8 head;
head becomes PSRAM bandwidth-bound.

**TRANSFERABLE_PATTERN:** When measured bottleneck is memory delivery, reduce data movement
before adding compute — **tie to measured Native bottlenecks only**:

- ddr_wavefront_00: sustained throughput unchanged vs control (DDR-bound)  
- mig_board_r2: high stall_frac on silicon  
- More PE lanes without delivery fix = declining returns (ENGINEERING_INFERENCE)

**Not universally true** — must be evidenced per gate.

---

## 7. Section F — Golden / export / representation verification

**EXT_REPO_OBSERVED:** `export.py` writes quantized `model.bin` + `golden.txt`; `verify.c` max-abs
gate; `ppl.c` pre-ship int8 activation check.

**TRANSFERABLE_PATTERN — Native AI principle:**

| Test class | Purpose |
|------------|---------|
| MODEL-LAW QUALITY | Semantic / perplexity / task accuracy |
| PACKING / ADDRESSING / MEMORY-PLUMBING CORRECTNESS | Bit-exact twin, tile packing, persist/reload |

**NATIVE_AI_OBSERVED:** lm06_wm_00 bit-exact vs frozen LM-06 CONTROL (LM06_WM_XSIM).

**Do not implement new tests in this gate.**

---

## 8. Section G — Controlled ablation / fair resource accounting

**EXT_REPO_OBSERVED:** Five arms with `make_model()` FFN binary search for matched core;
`ple_notable` isolates table; `fatembed` isolates injection point; `bigcore` spends table budget
on wider core.

**TRANSFERABLE_PATTERN:** Hold scarce resource constant (core budget, PE count, query, graph law)
while varying one architectural component.

**NATIVE_AI_OBSERVED:** Scientific gate method (one unknown, preregistered metrics) already in
blueprint loop.

---

## 9. Section H — Stored parameters vs compute capability

**EXT_REPO_MEASURED:** Domain ceiling set by ~559K dense core; 25M table is sparse touch.

**NOT_TRANSFERABLE:** Comparing "28.9M ESP32 params" vs "802,816 LM-06 params" as capability metric.

**Required statement (gate law):**

> Stored parameter count is not sufficient to compare the computational or semantic capability
> of these systems.

---

## 10. Relation to DDR-WAVEFRONT-00

**EXTERNAL ARCHITECTURAL PRECEDENT / METHODOLOGY SUPPORT only.**

External principle: large backing memory → fetch access-pattern-appropriate subset → stage in fast
memory → reuse locally.

Native planned path: DDR cue plane → bounded buffer → 16 PE wave → Top-K → full metadata for survivors.

**ddr_wavefront_00:** XSim PASS_NARROW — Native still requires own evidence. External repo is **not**
evidence that FPGA architecture will work on board.

---

## 11. Relation to LM06-WM research

**TRANSFERABLE_PATTERN:** Persistent state in slower memory; bounded compute-active representation
in fast memory.

**NATIVE_AI_OBSERVED:** LM-06 persistent weights **already DDR-resident**. Native problem is
reduce/phase-share ~132 BRAM working machinery while maintaining frozen LM-06 semantics.

**lm06_wm_00:** XSim PASS_NARROW (bit-exact). External repo does **not** solve BRAM integration.

---

## 12. Q1–Q9 final answers

| Q | Answer | Classification |
|---|--------|----------------|
| **Q1** Why technically relevant? | Strong method reference for access-pattern tiering, bytes-touched accounting, staging, decomposed benchmarks, golden verification, ablations | TRANSFERABLE_PATTERN |
| **Q2** Structural similarities? | Hot/cold split, sequential vs random traffic classes, golden-before-silicon | TRANSFERABLE_PATTERN |
| **Q3** Already in Master Blueprint? | DDR/BRAM/LUTRAM hierarchy, bytes/query metrics, twin discipline, scientific gates | ALREADY_SUPPORTED |
| **Q4** Measurement methods for future experiments? | Separate sequential vs random DDR probes; bytes/candidate; metadata vs useful bytes | TRANSFERABLE_PATTERN |
| **Q5** Must not transfer? | PLE law, CPU inference, ESP perf numbers, flash XIP as DDR model, dual-core=PE lanes | NOT_TRANSFERABLE |
| **Q6** Evidence for Native correctness? | **NO** — methodology/precedent only | NOT_TRANSFERABLE |
| **Q7** Justify changing live gate? | **NO** — LOOP_STATE unchanged | N/A |
| **Q8** Justify PLE in Native V1? | **NO** | NOT_TRANSFERABLE |
| **Q9** Future hypotheses worth preserving? | Post-V1 sparse DDR adapter table; separate random-metadata benchmarks; MODEL-LAW vs PACKING test split | FUTURE_RESEARCH |

---

## 13. Candidate findings A–G (tested)

| Candidate | Verdict | Evidence |
|-----------|---------|----------|
| A — classify by access pattern | **SUPPORTED** | budget.py, model.py |
| B — bytes touched > stored params | **SUPPORTED** | budget.py, RESULTS.md |
| C — stream vs random need different benchmarks | **SUPPORTED** | bandwidth_bench.ino |
| D — storage vs compute representation differ | **SUPPORTED** | int4 flash + int8 staged head |
| E — golden on deployed representation | **SUPPORTED** | export.py, verify.c |
| F — memory-bound → diminishing returns on compute | **SUPPORTED** | RESULTS bottleneck migration |
| G — fair ablation holds scarce resource | **SUPPORTED** | model.py arms, clean_confirm.sh |

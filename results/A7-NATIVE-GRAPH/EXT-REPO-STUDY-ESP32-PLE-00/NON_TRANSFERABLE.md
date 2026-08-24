# NON_TRANSFERABLE — EXT-REPO-STUDY-ESP32-PLE-00

Explicit list of what Native AI must **NOT** copy from chilly23/RP2040-and-ESP32-AI.

---

## 1. Host-trained inference-only workflow

**EXT_REPO_OBSERVED:** Training and export on host; MCU runs inference only.

**NOT_TRANSFERABLE:** Native AI requires FPGA-native execution for claims involving learning,
search winner, persistent state update, teacher-off retrieval, or next-token authority.

**Master Blueprint:** HLB hard stops; `04_HARDSTOPS.md`.

---

## 2. CPU cache assumptions

**EXT_REPO_OBSERVED:** ESP32 flash XIP, PSRAM, internal SRAM with cache effects.

**NOT_TRANSFERABLE:** Must not treat as equivalent to MIG + DDR3 + BRAM + explicit FPGA scheduler.

**Classification:** NOT_TRANSFERABLE.

---

## 3. Performance numbers

**EXT_REPO_MEASURED:** ~9.5 tok/s, ms/token, PSRAM 60.7 MB/s, flash random µs (RESULTS.md).

**NOT_TRANSFERABLE:** Do not present as Arty A7 performance. Transfer **methodology only**.

---

## 4. PLE model law

**EXT_REPO_OBSERVED:** Per-layer embedding table + gate (`model.py` ple arms).

**NOT_TRANSFERABLE for Native V1.** Status: **POST-NATIVE-V1 RESEARCH CANDIDATE** only.

**CONFLICT** if added to Native V1 — violates frozen LM-06 + graph law ids.

---

## 5. Dual-core CPU parallelism

**EXT_REPO_OBSERVED:** Head matvec split across two LX7 cores.

**NOT_TRANSFERABLE:** Do not map CPU threads directly onto FPGA physical PE lanes.

---

## 6. Memory-mapped flash semantics

**EXT_REPO_OBSERVED:** `esp_partition_mmap`, XIP quant weights.

**NOT_TRANSFERABLE:** Flash XIP behavior does not match AXI MIG DDR behavior.

---

## 7. Parameter count marketing

**EXT_REPO_OBSERVED:** "28.9M parameter model" README headline.

**NOT_TRANSFERABLE:** Do not compare 28.9M vs 802,816 LM-06 as capability metric.

**Required statement:**

> Stored parameter count is not sufficient to compare the computational or semantic capability of these systems.

---

## 8. Additional non-transferable items

| Item | Reason |
|------|--------|
| TinyStories training domain | Different task / evidence class |
| Tied embedding @ vocab 32768 | Different LM architecture |
| `rp2040_tinylm` fallback | Out of scope; display node only in final arch |
| Host Python as runtime oracle | HLB violation on Native evidence path |
| Zero-BRAM LM via flash | Blueprint rejects zero-BRAM LM (`08` §8b) |
| HNSW implementation from PLE | HNSW research-only; no datapath approval |
| ESP32 perplexity as Native sign-off | Different model law and domain |

---

## 9. Silent reconciliation forbidden

If external practice conflicts with Master Blueprint, document as **CONFLICT** in
`MASTER_BLUEPRINT_COMPLIANCE.md`. Example: recommending PLE for Native V1.

---

## 10. Hard-stop self-check

| Hard stop | Status |
|-----------|--------|
| External code copied | **PASS** — none copied |
| RTL modified | **PASS** — none |
| LOOP_STATE modified | **PASS** — none |
| ESP32 perf as Arty perf | **PASS** — not claimed |
| 28.9M as dense compute | **PASS** — decomposed in audit |
| External inference as native learning | **PASS** — not claimed |
| PLE added to Native V1 | **PASS** — not added |
| ESP32 latency as FPGA DDR latency | **PASS** — not claimed |
| CPU cores = FPGA PEs | **PASS** — not claimed |
| Master Blueprint silently changed | **PASS** — unchanged |
| External overrides Native evidence | **PASS** — authority order preserved |
| Subagent created | **PASS** |
| README-only inspection | **PASS** — code cross-checked |
| Findings lack classification | **PASS** — classified in SOURCE_MAP |
| "Similar" without critical difference | **PASS** — SIMILARITY_MATRIX |

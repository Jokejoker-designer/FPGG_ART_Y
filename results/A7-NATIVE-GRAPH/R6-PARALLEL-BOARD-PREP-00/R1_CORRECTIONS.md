# R1 audit condition corrections — R6-PARALLEL-BOARD-PREP-00

**Date:** 2026-08-24T20:44:00+07:00  
**Owner:** Cursor (read-only prep lane)  
**Prompt:** `.agents/handoff/PROMPT_CURSOR_R6_PARALLEL_BOARD_PREP_R1.md`  
**Prompt SHA256:** `556A111BA6861748A3766FC2B9CB62333A4EA753EB6E154DBB91762A1931CCF5`  
**Mode:** `ACTIVE_R1_AUDIT_CONDITION_CORRECTION_NO_PRODUCT`  
**Lock:** `grok` (unchanged)

---

## Verdict

**R1_AUDIT_CONDITIONS_CLOSED** — planning corrections only. Not engineering PASS, not route PASS, not board PASS.

---

## Correction 1 — Transitive source hash ledger

| Field | Value |
|-------|-------|
| Artifact | `R6_TRANSITIVE_SOURCE_SHA256.tsv` |
| Parsed from | `results/A7-NATIVE-GRAPH/NATIVE-V1-AB-INTEGRATE-ACCEPT-00/native_v1_ab_mig_xsim.prj` |
| `.prj` source count | **134** |
| TSV row count | **134** (MATCH) |
| Missing files | **0** |
| Duplicate paths | **0** |
| Ledger SHA256 | `2151615A1E6A2B7D315FC56CE12DF656BC0E87E2ABD80FEEA9AC552582B42A0B` |
| Ledger size | 27,449 bytes |

**Composition:** 29 SV (product/TB) + 104 Verilog (MIG RTL/model) + 1 `glbl.v`.

**Bound into:** `R6_FREEZE_MANIFEST_DRAFT.md` §3b (draft until R6 terminal + final log SHA).

**Not hashed:** live `xsim_ab_mig.log` (APPEND_ONLY policy unchanged).

---

## Correction 2 — Mandatory DCP lineage for E2

| Change | Detail |
|--------|--------|
| `E2_BOARD_PREP.md` | Added P2b (DCP present + SHA) and P2c (lineage proof); P7 source ledger |
| DCP row | Changed from `optional` to **mandatory** |
| STOP rule | E2 forbidden without DCP + SHA + same-lineage proof |
| `E1_POSTROUTE_PREP.md` | Added mandatory DCP artifact table for E2 gate |

---

## Correction 3 — Class A exact memory mode

| Field | Locked value |
|-------|--------------|
| `SIM_FULL` | **1** (not 0, not fixture-weight path) |
| MIG | **No physical MIG model** |
| Weight load | Backdoor `a7lm06_wmem.hex` only while reset/inactive |
| Forward | Full to exact `pred=664` |
| Evidence class | `XSIM_FAST_CAUSAL` / `PASS_NARROW` |
| Proves | LM functional causality only |
| Does NOT prove | Physical memory, SIM_FULL=0, MIG transport, route, board |

**File:** `VERIFICATION_DECOMPOSITION_V0.md` (full rewrite of Class A section).

---

## Files touched (R1)

| File | Action |
|------|--------|
| `R6_TRANSITIVE_SOURCE_SHA256.tsv` | **CREATED** |
| `R6_FREEZE_MANIFEST_DRAFT.md` | §3b ledger binding |
| `VERIFICATION_DECOMPOSITION_V0.md` | Class A locked |
| `E2_BOARD_PREP.md` | Mandatory DCP + lineage |
| `E1_POSTROUTE_PREP.md` | DCP artifact table |
| `R1_CORRECTIONS.md` | **CREATED** (this file) |
| `RESULTS.md` | R1 closeout status |

---

## What was NOT done

- No RTL/TB/Tcl/MIG/R6 evidence edit  
- No Vivado/XSim/P&R  
- No git mutation  
- No R6 process control  
- No COM12/JTAG/board  
- No `lock.owner` change  
- No Class A / E1 / E2 execution  

**STOP** — R1 complete; Grok R6 remains sole active product lane.

# BRAM_OWNERSHIP_REPORT_V1_DRAFT — SPEC §28 extension

**Status:** DRAFT / **NOT** Native V1 ship authority  
**Supersedes for scope:** extends `INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` (integrate_fit cut only)  
**SPEC:** `BRAM_WORKING_MEMORY_SPEC.md` §28  
**feedback:** §14, §15  
**Date:** 2026-08-22  

**Law:** No full integration claim until this report is re-issued against the **final Native V1**
post-route configuration with measured tile counts for every row below.

---

## 1. Rows present in integrate_fit cut (verified)

Copied from `results/A7-NATIVE-GRAPH/INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` — **integrate_fit proxy only**.

| hierarchy | BRAM tiles | role | phase | persistent? | shareable? | DDR-backable? | evidence |
|-----------|----------:|------|-------|-------------|------------|---------------|----------|
| LM-06 `u_w` | 64 | weight staging | LM | within run | limited | weights in DDR | POST_ROUTE LM06 dcp |
| LM-06 `u_snap` | 2 | snapshot | LM | within run | no | optional | same |
| LM-06 `u_a` | 66 | activation scratch | LM | transient | YES vs graph | partial | same |
| Graph hotset / shared cut | ≤64 | query/path WM | GRAPH | transient | phase-mux w/ u_a | overflow→DDR | integrate_fit proxy |
| Episode/index banks DEPTH=16 | 0 | DDR windows | GRAPH | no | n/a | yes | MEM-01_02 XSim |
| WM-00 working set | 0 | LUT/FF intent | GRAPH | no | n/a | DDR feed | BRAM-WM-00 |
| Digilent AXI MIG buffers | 0 | DDR PHY/AXI | always | yes | no | n/a | NG-03 |
| A0.3 encoder | 3 | encoder | — | — | — | not concurrent on cut | frozen block |
| Debug / ILA | 0 | — | — | — | — | off in measure | — |

---

## 2. SPEC §28 required rows — gap analysis

| SPEC required row | integrate_fit draft | Native V1 ship config | Action |
|-------------------|--------------------|-----------------------|--------|
| LM-06 | **PARTIAL** (132-tile full LM06, cut uses shared u_a) | Need full `u_w`/`u_a`/`u_snap` on ship bit | Post-route enum from `a7lm06_post_route.dcp` |
| encoder | **PARTIAL** (listed, dropped on cut) | Concurrent or phased? TBD by final arch | Route util from frozen A0.3 or phase plan |
| graph | **PARTIAL** (hotset cut only) | frontier + Top-K + candidate buffers per SPEC §5 | WM-00 + wavefront + NG-06 hierarchy |
| **router** | **MISSING** | 01R frozen block **56 BRAM** (separate bit) | Add row from `01R` post-route util; phase-share TBD |
| episodic memory | **PARTIAL** (DDR windows 0 BRAM) | MEM-02 index + episode store | DDR-backed — document 0 BRAM |
| **FIFOs** | **MISSING** | NG-02R-FLOW lossless queues; integration FIFOs | Post-route on integrated top |
| MIG-related buffers | **PARTIAL** (0 cited) | MIG IP internal — verify on SoC impl | NG-03 + integrate SoC util rpt |
| debug | **PARTIAL** (0 claimed) | ILA if enabled | Explicit 0 or counted |

---

## 3. Router row (draft — frozen 01R, not integrated)

| hierarchy | BRAM tiles | role | phase | persistent? | shareable? | DDR-backable? | evidence |
|-----------|----------:|------|-------|-------------|------------|---------------|----------|
| 01R sparse router (frozen) | **56** | retrieval routing | GRAPH | within run | **NO** (separate frozen bit) | index in DDR | frozen 01R post-route util |

**Classification:** `NATIVE_AI_OBSERVED` from RESOURCE_BUDGET / frozen block accounting.  
**Not integrated** with LM-06 on one bit in current evidence.

---

## 4. FIFO row (draft — engineering inference)

| hierarchy | BRAM tiles | role | phase | persistent? | shareable? | DDR-backable? | evidence |
|-----------|----------:|------|-------|-------------|------------|---------------|----------|
| NG-02R-FLOW lossless FIFOs | **TBD** | backpressure queues | GRAPH | transient | TBD | no | **OPEN** — enumerate from integrated post-route |
| Integration crossbar FIFOs | **TBD** | LM↔graph boundary | HOLD | transient | phase-gated | no | **OPEN** — `bram_owner_00` scope |

**Action:** Run post-route hierarchy report on **target Native V1 top** when it exists; do not invent tile counts.

---

## 5. 02M episodic (draft)

| hierarchy | BRAM tiles | role | phase | persistent? | shareable? | DDR-backable? | evidence |
|-----------|----------:|------|-------|-------------|------------|---------------|----------|
| 02M episodic (frozen) | **52** | episode bind | GRAPH | DDR authority | NO (frozen bit) | yes | frozen 02M util |

Naive stack with LM-06+01R+02M+A0.3 = **243/135 FALSIFIED**.

---

## 6. Composed tile budgets (measured / falsified)

| composition | BRAM | verdict | evidence class |
|-------------|-----:|---------|----------------|
| LM-06 alone | 132 | working machinery | POST_ROUTE |
| naive 01R+02M+LM-06+A0.3 | 243 | **FALSIFIED** | POST_ROUTE |
| integrate_fit declared cut | 130 | proxy PASS_NARROW | POST_ROUTE_PROXY |
| UA128 + LM-06 132 | 260 | **FALSIFIED** | POST_ROUTE_FIT_LIMIT |
| co-fit max(128,132) | 132 | proxy WNS +0.586 | POST_ROUTE_PROXY |

---

## 7. Phase ownership (SPEC §29–§30) — not evidenced

Required FSM (documentation only until `bram_owner_00`):

```text
GRAPH → BLOCK_NEW_WORK → DRAIN_PE → DRAIN_QUEUE → DDR_COMMIT_IF_DIRTY
      → VERIFY_QUIESCENT → OWNER_SWITCH → LM
```

**Status:** **OPEN** — no post-route proof on integrated Native V1 bit.

---

## 8. Queue linkage

| LOOP_STATE id | This draft satisfies? |
|---------------|----------------------|
| `bram_ownership_report` | **PARTIAL** — gap analysis + router/FIFO draft rows; needs post-route enum |
| `full_integration` | **NO** — blocked until §28 complete on ship config |
| `bram_owner_00` | **NO** — FSM not implemented |

---

## 9. NEXT (documentation)

1. When Native V1 integration top exists: `report_utilization -hierarchical` → fill TBD rows.  
2. Promote this file to `BRAM_OWNERSHIP_POST_ROUTE.md` only after auditor PASS on ship SHA.  
3. Update `COMPLIANCE_GAP_REGISTER.md` G-P3-04 when complete.

**Does not tick LOOP_STATE. Does not declare ARCH_PASS or BOARD_PASS.**

# E2 board prep pack — existence only

**Date:** 2026-08-24T20:35:00+07:00  
**Reconciles:** `STATUS/E2_BOARD_EXISTENCE_RUNBOOK.md`, `STATUS/SECTION14_OPEN_PUNCHLIST.md`  
**STOP:** `BRIDGE.board.com12_authorized_gate = null` — no HW manager, JTAG, COM12, reset, program  

---

## Scope

```text
E2 closes §14 cell #8 (LM-06 active on FPGA response path) at BOARD class — existence only.
S0 (cells 1,4–7) remains separate HS-02 teacher-off lane.
```

---

## Preconditions (all file-backed before any program)

| ID | Requirement | Status @ prep |
|----|-------------|---------------|
| P1 | `NATIVE_EXISTENCE_XSIM_PASS` / CLOSEOUT | **OPEN** — R6 in flight |
| P2 | E1 FIT (util + timing) | **OPEN** |
| **P2b** | **E1 post-route DCP present + SHA256 recorded** | **OPEN** — **MANDATORY** |
| **P2c** | **Bitstream lineage proves same E1 candidate/source as DCP** | **OPEN** — **MANDATORY** |
| P3 | Evidence auditor PASS | **OPEN** |
| P4 | HLB CLEAN | **OPEN** |
| P5 | `com12_authorized_gate == native_v1_existence_board_00` | **null** |
| P6 | Frozen LM06/01R/02M/A0.3 SHA ledger | standing |
| P7 | Transitive source ledger (`R6_TRANSITIVE_SOURCE_SHA256.tsv`) matches programmed lineage | **R1 draft ready** |

**STOP:** If P2b or P2c missing at board time → **do not program**. DCP is **not optional**.

---

## ONE UNKNOWN (E2)

On programmed Arty bit: does raw Native evidence drive **actual LM06** and produce FPGA-owned next token with `host_next_token=0`, `teacher=0`, `external_LLM=0` during response window?

**Not in scope:** 800k, HS-02 semantic grading, reset/retrain, tok/s.

---

## Evidence manifest template (fill at run time)

| # | Artifact | Path / pattern | SHA256 | Present |
|---|----------|----------------|--------|---------|
| 1 | Bitstream | `results/A7-NATIVE-GRAPH/<GATE>/arty_native_v1_existence_00.bit` | | |
| 2 | Bit SHA file | `sha256_<gate>.txt` | | |
| 3 | DCP (**mandatory**) | `E1-AB-COFIT-00/ab_post_route.dcp` | | |
| 3b | DCP lineage proof | CLOSEOUT table: DCP SHA ↔ bitstream build SHA ↔ source ledger | | |
| 4 | Source freeze | CLOSEOUT git SHA + RTL hash table | | |
| 5 | Harness script | `python/...` or `host/...` exact path | | |
| 6 | Host tool SHA | recorded in CLOSEOUT | | |
| 7 | Command line | `COMMANDS.txt` one block | | |
| 8 | Board port | COM12 (authorize only) | | |
| 9 | Reset state | UART header timestamp | | |
| 10 | Raw UART log | `.bin` + `.txt` | | |
| 11 | Counter dump | teacher/host/fpga token table | | |
| 12 | `actual_lm06_active` | 1 | | |
| 13 | `fpga_next_token_valid` | >0 | | |
| 14 | `host_next_token` | 0 | | |
| 15 | Auditor | `AUDIT_*_E2.md` | | |
| 16 | HLB | `AUDIT_HLB_E2.md` CLEAN | | |

---

## §14 reconciliation

| §14 # | Cell | E2 role |
|-------|------|---------|
| 8 | LM-06 active on FPGA path | **Primary E2 close target** |
| 1,4–7 | teacher/LLM/learn/freeze | **S0** — not E2 |
| 2–3 | 800k scale | **Q0** — not E2 |

---

## Human authorization block (paste when ready — NOT now)

```json
"board": {
  "physical_connected": true,
  "com12_authorized_gate": "native_v1_existence_board_00",
  "com12_authorized_by": "human <ISO8601>",
  "note": "Existence board only; no HS-02/800k auto-chain"
}
```

Until set → print `HUMAN_AUTH_REQUIRED` and **STOP**.

---

## Closeout vocabulary

| Result | Meaning |
|--------|---------|
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | Narrow silicon existence |
| `FAIL` | Missing token / host leak |
| `LIMIT` | Partial observability |
| **Forbidden** | `NATIVE_V1_MINI_AI_BOARD_PASS` (human only) |

---

## Parallel with R6

Grok R6 continues. This pack prepares same-day E2 **after** P1–P4 **and mandatory P2b/P2c**; zero board action during prep.

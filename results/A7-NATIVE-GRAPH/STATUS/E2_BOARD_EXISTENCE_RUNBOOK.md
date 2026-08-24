# E2 — Board Existence Runbook (PREP ONLY)

**Status:** `HUMAN_AUTH_REQUIRED` — do **not** program until `BRIDGE.board.com12_authorized_gate` matches this gate id.  
**Date:** 2026-08-24T15:30:00+07:00  
**Owner (prep):** Cursor orchestrator  
**Owner (run):** TBD after Grok `NATIVE_EXISTENCE_XSIM_PASS` + E1 FIT  
**Board:** Arty A7-100T physical connected; authorize still null  

```text
XSIM_PASS != ROUTE_PASS != BOARD_PASS != TEACHER_OFF_PASS != RELEASE_PASS
This runbook targets NATIVE_V1_EXISTENCE_BOARD_PASS only — not full NATIVE_V1_MINI_AI_BOARD_PASS.
```

---

## 0. Preconditions (all must be file-backed)

| # | Precondition | Evidence required | Status now |
|---|--------------|-------------------|------------|
| P1 | AB integrate XSim / MIG_XSIM existence | `NATIVE-V1-AB-INTEGRATE-ACCEPT-00/CLOSEOUT.md` with `NATIVE_EXISTENCE_XSIM_PASS` | **OPEN** (Grok; FAIL_R1_XELAB) |
| P2 | Actual integrated post-route FIT | util + timing; BRAM≤135; WNS≥0; TNS=0 | **OPEN** (depends P1) |
| P3 | Evidence auditor PASS on P1+P2 | AUDIT_* allow existence board | **OPEN** |
| P4 | HLB CLEAN on candidate | no host pred/winner/next-token | **OPEN** |
| P5 | `com12_authorized_gate == native_v1_existence_board_00` (or final gate id) | `BRIDGE.json` | **null** |
| P6 | Frozen LM-06 / 01R / 02M / A0.3 untouched | SHA MATCH ledger | standing |

If any precondition fails → **STOP**. Do not program.

---

## 1. Narrow board unknown (ONE)

```text
ONE UNKNOWN: On the programmed Arty bit, does raw Native evidence drive
ACTUAL LM06 and produce an FPGA-owned next token with host_next_token=0
and teacher/external_LLM=0 during the response window?
```

**Not in scope:** 800k, HS-02 held-out semantic grading, reset/retrain mapping swap, tok/s claims.

---

## 2. Required counters / observables

| Signal | Pass if |
|--------|---------|
| `actual_lm06_active` | 1 |
| `lm_input_evidence_count` | > 0 |
| `logits_valid` | > 0 |
| `fpga_topk_active` | 1 |
| `fpga_next_token_valid` | > 0 |
| `teacher_api_calls` (response window) | 0 |
| `external_LLM_calls` | 0 |
| `host_next_token` | 0 |
| `host_winner` | 0 |
| `host_semantic_hint` | 0 |
| `learn` | 0 |
| `freeze` | 1 |

---

## 3. Archive checklist (before declaring existence board PASS)

| Artifact | Path pattern |
|----------|--------------|
| Bitstream | `results/A7-NATIVE-GRAPH/<GATE>/arty_*.bit` |
| Bit SHA256 | `sha256_*.txt` |
| Git SHA | recorded in CLOSEOUT |
| Host tool SHA | recorded |
| Exact command line | `COMMANDS.txt` |
| Board port | e.g. COM12 |
| Timestamp / reset state | UART header |
| Raw UART log | binary + text |
| Counter dump | teacher/host/fpga token |
| Auditor + HLB | AUDIT_*.md |

---

## 4. Human authorization template (paste into BRIDGE when ready)

```json
"board": {
  "physical_connected": true,
  "com12_authorized_gate": "native_v1_existence_board_00",
  "com12_authorized_by": "human <timestamp>",
  "note": "Scoped to existence board run only; no HS-02/800k auto-chain"
}
```

Until this is set → print `HUMAN_AUTH_REQUIRED` and **STOP**.

---

## 5. Closeout vocabulary

| Result | Meaning |
|--------|---------|
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | Narrow existence on silicon |
| `FAIL` | Token missing / host leak / counter fail |
| `LIMIT` | Partial observability only — not existence |
| **Forbidden** | Self-declare `NATIVE_V1_MINI_AI_BOARD_PASS` |

---

## 6. Parallel note

Grok owns `native_v1_ab_integrate_accept_00`. This runbook does **not** edit that product. Cursor only prepares so E2 starts the same day P1–P4 close.

# Verification decomposition v0 — A / B / C

**Date:** 2026-08-24T20:44:00+07:00 (R1 correction)  
**Purpose:** Planning lane only — **does not weaken or change R6 acceptance mid-run**  

```text
R6 in flight = Class B (real MIG) bounded causal checkpoint toward pred=664.
This document prepares post-R6 verification routing only.
```

---

## Class A — Fast no-MIG full forward / exact pred (LOCKED)

| Field | Value |
|-------|-------|
| **Memory mode** | **`SIM_FULL=1`** (locked — not `SIM_FULL=0`, not fixture-weight path) |
| **MIG** | **No physical MIG model** — no live DDR/AXI storm |
| **Weight load** | Backdoor `a7lm06_wmem.hex` via `$readmemh` **only while reset/inactive** (`feed_en=0`) |
| **Forward** | Full forward through frozen TinyGPT to **exact `pred=664`** on CONTROL |
| **Evidence class** | `XSIM_FAST_CAUSAL` / `PASS_NARROW` |
| **Harness owner** | Grok implement after R6; Cursor VERIFY only |

### Proves

- LM functional causality on CONTROL query  
- No host-forced pred / winner / next-token  

### Does NOT prove

- Physical memory service under load  
- `SIM_FULL=0` silicon path  
- MIG transport (832 B / 52 beats / Top-8 under live SOA)  
- Post-route FIT  
- Board silicon  

**Falsifier:** pred forced; cycle-by-cycle `mem_we` on live MIG (R2 class); `SIM_FULL=0` substituted as Class A.

**Mid-run rule:** Class A is **not** executable while R6 (Class B) runs. No parallel “easier PASS” may replace B.

---

## Class B — Real MIG transport + preregistered bounded causal checkpoint

| Field | Value |
|-------|-------|
| **Question** | Live SOA/MIG → Top-8 → accept/bind → TinyGPT → `pred=664` under MIG_XSIM? |
| **Harness** | `tb_a7ng_native_v1_ab_mig.sv`, `run_a7ng_native_v1_ab_mig.tcl`, MIG model |
| **Evidence class** | `MIG_XSIM` |
| **R6 active unknown** | Same as gate prereg — **currently IN FLIGHT** |
| **Bounded checkpoint** | `SOA_PATTERN_PASS`, `CAPTURE_OK`, phase prints (`EMB`/`LNV`/`LNO`/`MV0`/`LM_HB`), final `NATIVE_V1_AB_MIG_XSIM_PASS` |
| **Acceptance** | `NATIVE_EXISTENCE_XSIM_PASS` per `STATUS/E0_ACCEPTANCE_CRITERIA.md` |
| **Owner** | **Grok** (lock); auditors after Result |

**Current R6 progress (FACT):** WQ L0 through token 6+; `LM_HB` 200k/400k; `pred=0`; not yet WK/ATT/SMX.

---

## Class C — Human-authorized silicon full pred/token

| Field | Value |
|-------|-------|
| **Question** | Programmed Arty produces FPGA-owned token with host/teacher counters zero? |
| **Harness** | E2 runbook + UART/JTAG counters |
| **Evidence class** | `BOARD` |
| **Preconditions** | B PASS + **E1 DCP+SHA+lineage** + auditor trio + `com12_authorized_gate` set |
| **Owner** | Human authorize; never self-declare `BOARD_PASS` |
| **Scope** | Existence board (`NATIVE_V1_EXISTENCE_BOARD_PASS`) — not full §14 |

---

## Auditor routing after R6 terminal

```text
IF R6 → NATIVE_V1_AB_MIG_XSIM_PASS pred=664:
  Task a7-ng-xsim-verify   (re-grade Class B)
  Task a7-hlb-auditor
  Task a7-evidence-auditor (DISPATCH_LOG gate match)
  THEN open E1 (Class A does not skip E1)

IF R6 → FAIL/TIMEOUT:
  Grok owns next single-unknown round
  Class A may inform design — not close gate alone

Class C: blocked until P1–P6 in E2_BOARD_PREP.md (incl. mandatory DCP)
```

---

## Non-weakening statement

| Claim | Allowed now? |
|-------|--------------|
| R6 replaced by Class A only | **NO** |
| Class A with `SIM_FULL=0` as substitute | **NO** |
| WQ progress = existence PASS | **NO** |
| Planning pack = engineering PASS | **NO** |

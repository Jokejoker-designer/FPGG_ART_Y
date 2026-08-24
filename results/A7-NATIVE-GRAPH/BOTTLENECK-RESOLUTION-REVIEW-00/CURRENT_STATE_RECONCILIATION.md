# CURRENT_STATE_RECONCILIATION — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

**Gate:** `NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00`  
**Date:** 2026-08-22  
**Authority:** repository evidence only (`LOOP_STATE.next=STOP` unchanged)  
**Evidence classes used:** `BOARD_MIG`, `MIG_XSIM`, `MIG_XSIM_WAVEFRONT`, `LM06_WM_XSIM`, `POST_ROUTE`, `POST_ROUTE_PROXY`, `POST_ROUTE_FIT_LIMIT`

---

## A. MIG-BOARD-R2 — **VERIFIED**

| Claim | Status | Evidence |
|-------|--------|----------|
| BOARD_MIG PASS | **FACT** | `MIG-BOARD-R2/CLOSEOUT.md`; marker `A7NG_MIG_BOARD_R2_OK` |
| 16/16 burst×outstanding grid | **FACT** | `board_uart_capture.json`: `grid_complete: true`, 16 rows |
| Per-run integrity CLEAN | **FACT** | All cells: `axi_read_bytes=1024`, `data_mm=0`, `exp/rcv/cons=64/64/64` |
| WNS positive | **FACT** | `wns.txt` / closeout: **+1.060 ns** (not +1.142) |
| Not Native V1 BOARD_PASS | **FACT** | Feed-path probe only; `human_declares_board_pass: true` in LOOP_STATE |

### Stall plateau

| Cell | stall_frac | Classification |
|------|----------:|----------------|
| (4,8) | 0.555556 | `NATIVE_AI_MEASURED_DERIVED` |
| (8,4) | 0.555556 | same |
| (16,2) | 0.552448 | near plateau |
| (16,8) | 0.555556 | same |
| (1,1) | 0.960248 | **REJECT** as universal plateau — burst=1 pathological |

**AMEND:** Plateau ~0.55 applies to **burst≥4, out≤8 cluster**, not the full grid.

### eta_beat

For burst=16/out=2: `pe_stall=79`, `pe_busy=64` → `stall_frac=79/(79+64)=0.5524`.

Proposed normalized feeder efficiency:

```text
eta_beat = useful_beats / (useful_beats + service_empty_stall_cycles)
         = 64 / (64 + 79) ≈ 0.4476
```

**VERDICT: AMEND — valid only with explicit counter semantics.**

| Interpretation | Valid? | Notes |
|----------------|--------|-------|
| `pe_busy / (pe_stall + pe_busy)` | **PARTIAL** | Pop-or-stall duty cycle; breaks when `cycles ≠ pe_stall+pe_busy` (cell 1,1) |
| `cons / cycles` (= `recs_per_cyc`) | **YES** | Authoritative sustained rate ≈ 0.444 at best cells |
| `axi_read_beats / cycles` | **YES** | Equals `recs_per_cyc` here (64 beats / 144 cycles) |
| Raw DDR pin efficiency | **NO** | `r_backpressure_cycles=0`; stalls are empty-buffer waits |

Classification: `NATIVE_AI_MEASURED_DERIVED` — do not sell as link utilization without defining counters.

---

## B. DDR-WAVEFRONT-00 — **VERIFIED**

| Claim | Status | Evidence |
|-------|--------|----------|
| PASS_NARROW | **FACT** | `DDR-WAVEFRONT-00/CLOSEOUT.md` |
| Evidence_class=MIG_XSIM_WAVEFRONT | **FACT** | Not BOARD |
| 16-wide emission proved | **FACT** | `jobs_per_emit_cycle=16.0000`, 4/4 full waves |
| Sustained ~0.441 vs control ~0.444 | **FACT** | P2: 0.441379; P4: 0.444444; MIG control (4,8): 0.444444 |
| memory_wait_fraction 0.815–0.998 | **FACT** | P3: 0.814570; P1–P2/P4: 0.97+ |
| 16 B/candidate | **FACT** | `ddr_bytes_per_candidate=16.0000` all patterns |

**VERDICT: ACCEPT** — 16-wide **EMISSION ≠ 16-wide SUSTAINED MEMORY FEED**. LIMIT L3 in closeout is accurate.

Traffic unchanged vs MIG-METRIC-00 control (1024 B, zero inflation). `swap_count` now instrumented (64 at burst=1 → 2 at burst≥4).

---

## C. LM06-WM-00 — **VERIFIED**

| Claim | Status | Evidence |
|-------|--------|----------|
| PASS_NARROW / LM06_WM_XSIM | **FACT** | `VERDICT_lm06_wm_00_BINDING.md` |
| Bit-exact vs frozen CONTROL | **FACT** | `LM06-WM-00/RESULTS.md`; Tier-1 silicon control sealed |
| NOT proved: BRAM reduction | **FACT** | All tiles resident; no synthesis |
| NOT proved: P&R | **FACT** | XSim only |
| NOT proved: DDR latency hiding | **FACT** | Arm B zero-latency functional model |
| NOT proved: timed bounded resident set | **FACT** | NLIVE_ACT=4 not exercised |

### Struck inference — **PRESERVED**

> max 2 tiles demanded/cycle **DOES NOT** imply 2 resident tiles are sufficient.

Binding verdict L11–L29: port-demand count only. Permitted wording: *"In this workload, at most 2 tiles are demanded in the same cycle."*

Traffic/reuse-distance belongs to ladder (`lm06_wm_01..04`), not WM-00.

---

## D. BRAM — **VERIFIED**

### Frozen LM-06 ownership (POST_ROUTE)

| Owner | Tiles | Evidence |
|-------|------:|----------|
| `u_w` | 64 | `MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md` |
| `u_a` | 66 | same (132 `BMEM` primitives) |
| `u_snap` | 2 | same |
| **LM-06 total** | **132** | working machinery, not weight store |

### Naive stacking — **FALSIFIED**

| Composition | BRAM | Verdict | Class |
|-------------|-----:|---------|-------|
| 01R+02M+LM-06+A0.3 | 243/135 | FALSIFIED | POST_ROUTE |
| UA128 + LM-06 132 | 260/135 | FALSIFIED | POST_ROUTE_FIT_LIMIT |
| consol 132 + TinyGPT 132 | 264/135 | FALSIFIED | FIT_LIMIT |

### Shared-capacity proxy

`max(128,132)=132` tiles, WNS +0.586 — `POST_ROUTE_PROXY`. Soft target ≤130 **NOT MET**. HS-22 **OPEN**.

---

## Cross-statement verdict

All four sections (A–D) in the review brief are **consistent with canonical artifacts**. No material contradiction found. Two common misreadings are **rejected**:

1. eta_beat as universal DDR efficiency without counter definition  
2. WM-00 port-demand as working-set size or ping-pong sufficiency proof

# RESULTS — G14-FINAL-GAP-RECONCILIATION-00

```text
READY_TO_PROGRAM = NO
PROGRAM          = NO
GATE14_PASS      = NO
NATIVE_V1_MINI_AI_BOARD_PASS = NO
RTL_EDIT         = NO
```

Authority: `BlueprintV2/14_FINAL_ACCEPTANCE_CHECKLIST.md` (56 boxes).
BOARD artifact: unique bit `1F0F2ABB…FF4B9` commit `9656245` UART `F7BCC0B1`.
Do not reprogram that bit.

`PROJECT_COMPLETE.md` (2026-08-22) is **STALE_CLAIM** as a live rollup
(TinyGPT “ABSENT”, next=`section14_all`). Use this file + `CURRENT_GATE14_STATUS.md`.

---

## Count (strict tick = PASS only)

| Class | N | Meaning |
|-------|--:|---------|
| PASS | **22** | File-backed at required class |
| PASS_NARROW | **20** | True for this Native V1 C9 SoC, but not the full NG-07/16-PE/800k wording |
| OPEN_BOARD | **7** | HS-02 named host flags not live on UART of `1F0F2ABB` |
| OPEN_METRIC | **5** | Measurement reports, not a new law |
| STALE_CLAIM | **1** | August `PROJECT_COMPLETE` as CURRENT |
| FAIL | **0** | |
| OPEN_XSIM | **0** | No remaining XSim law gap that blocks a box |
| **Total boxes** | **56** | |
| **Cannot tick today (strict)** | **12** | 7 OPEN_BOARD + 5 OPEN_METRIC |
| Root B latent | **0 boxes** | Do not put on a final bit |

If MODE=8 + HOST_FORBIDDEN=0 + RTL host-tie-off is accepted as HS-02 live
proof, OPEN_BOARD **collapses to 0** and remaining strict-open is **5 OPEN_METRIC**.

---

## 1. Hardware (7)

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| H1 | Fits `xc7a100t` | **PASS** | POST_ROUTE+BOARD `1F0F2ABB` slice 15581/15850 `e2r_metrics.txt` | — |
| H2 | WNS >= 0 | **PASS** | WNS=+0.373 | — |
| H3 | TNS = 0 | **PASS** | TNS=0 | — |
| H4 | Bitstream SHA archived | **PASS** | `BIT_SHA256.txt` `1F0F2ABB…FF4B9` | — |
| H5 | DDR map archived | **PASS_NARROW** | `NG_DDR_PRIOR_BASE=28'h0300_0000` in `a7ng_pkg.sv` | One-page MAP.md at freeze; not a new bit |
| H6 | Resource report archived | **PASS** | `e2r_metrics` LUT=35917 FF=44164 RAMB36=104 DSP=19 | — |
| H7 | Physical PE from RTL/report | **PASS_NARROW** | CUE `PHYS=4`; C9 graph **1** `scorer_lane` (`PIN.md`) | Do not claim 16 PE |

## 2. Learning boundary (5)

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| L1 | No host gradients | **PASS** | UART cmd/tok/rew only; HS-01 | — |
| L2 | No host ΔW | **PASS** | same | — |
| L3 | No host winner/address/hash | **PASS_NARROW** | glue host_* tied 0; BOARD `HOST_FORBIDDEN_COUNTERS=0` | n_host not on UART |
| L4 | Teacher only in TRAIN | **PASS** | BOARD MODE 5 train → MODE 8 exam | — |
| L5 | Learned state on FPGA | **PASS** | BOARD cons 0→20; C9 A vs forget vs B | — |

## 3. Query attention (4)

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| Q1 | Native entity anchor | **PASS_NARROW** | C9 qid-hardcoded cands; `query_anchor` **not** in fileset | Not NG-07 entity extractor |
| Q2 | Native intent/context | **PASS_NARROW** | same | — |
| Q3 | Same entity / different intent ranking | **PASS** | BOARD HOLD_A vs CONTRA C9/OUT | — |
| Q4 | No teacher attention hint in blind exam | **OPEN_BOARD** | XSim `n_host_*=0`; RTL tie-off | Live host_cue on programmed UART (HS-04) |

## 4. Knowledge graph (4)

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| K1 | Directed typed relations | **PASS** | BOARD C9 rel in pack | — |
| K2 | Contextual bomb/prune | **PASS_NARROW** | vis_w + CONTRA; not full NG bomb FSM | — |
| K3 | Wrong path does not reset global knowledge | **PASS** | BOARD HOLD_A 653 still after UNREL/CONTRA | — |
| K4 | Top-K includes path/relation | **PASS** | BOARD C9 TopK ids | — |

## 5. Parallelism (4) — lock as audited

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| P1 | Declared physical lanes concurrent | **PASS_NARROW** | PHYS=4 / 1 lane; not 16 | Don’t claim 16 |
| P2 | Logical agents reported separately | **PASS_NARROW** | Not claiming 8000 cores | — |
| P3 | Lane utilization measured | **OPEN_METRIC** | — | Report, not a law bit |
| P4 | DDR stalls measured | **OPEN_METRIC** | MIG_XSIM historical | Board stall counter optional |

## 6. Memory (10) — lock as audited for this design

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| M1 | LM weights DDR-backed | **PASS_NARROW** | Tile/DMA exists; exam used on-chip WMEM | Not a 1F0F2ABB miss |
| M2 | Graph/episodes DDR-backed | **PASS** | BOARD FLUSH/KILL/RELOAD then HOLD_A 653 | — |
| M3 | Index DDR-backed if claimed | **PASS** | This SoC does **not** claim HNSW/800k index | — |
| M4 | BRAM bounded working set | **PASS_NARROW** | 32 slots; XSim n_occ=20 | BOARD slot dump not UART |
| M5 | BRAM ownership documented | **PASS_NARROW** | RAMB36=104 + RTL hierarchy | Freeze-time table |
| M6 | No two writers / bank / cycle | **PASS_NARROW** | RTL_FACT | — |
| M7 | DDR bytes/query | **OPEN_METRIC** | — | Counter/report |
| M8 | Candidates/query | **PASS_NARROW** | RTL 8 cands; XSim | UART count optional |
| M9 | No hidden 800k full scan | **PASS** | 8 cands + 32 BRAM; no 800k loop | — |
| M10 | 800k scale bytes/cands | **OPEN_METRIC** | Native V1 exam is 20-fact | Don’t claim 800k runtime |

## 7. Teacher-off (12) — HS-02 live on programmed bit

Checklist: UART stub / constant flag **does not** count.

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| T1 | teacher=0 | **OPEN_BOARD** | No named UART bit | Named live flag **or** doctrine: MODE=8 |
| T2 | external_LLM=0 | **OPEN_BOARD** | TinyGPT on FPGA; no UART flag | Named live flag **or** doctrine |
| T3 | learn=0 | **PASS** | BOARD C1 MODE=8 (bit2=0), live 5→8 | — |
| T4 | freeze=1 | **PASS** | BOARD MODE=8 (bit3=1) | — |
| T5 | host_semantic_cue=0 | **OPEN_BOARD** | RTL 0; XSim n_host=0; `ab_core` ties n_host off UART | Export n_host on CFRAME |
| T6 | host_winner=0 | **OPEN_BOARD** | same | same |
| T7 | host_episode_address=0 | **OPEN_BOARD** | same | same |
| T8 | host_next_token=0 | **OPEN_BOARD** | same | same |
| T9 | host_weight_writes=0 | **OPEN_BOARD** | same | same |
| T10 | held-out wording | **PASS** | BOARD HOLD_A exam after TRAIN | — |
| T11 | unrelated reject | **PASS** | BOARD UNREL 689 / C9 `8786858483828180` | — |
| T12 | contradiction probe | **PASS** | BOARD CONTRA 237 / C9 `2322832182208180` | — |

XSim Gate T is **not** a substitute for T1–T2, T5–T9 under strict HS-02.

## 8. LM-06 (3)

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| LM1 | Active on FPGA response path | **PASS_NARROW** | BOARD C9 then OUT=653 LMST/LMDN=1; XSim `LM_ACTIVE_CHAIN_PROVEN` (`91e0e1f`) | Dest/DDR WDMA not BOARD-class |
| LM2 | Structured Native evidence is context | **PASS_NARROW** | XSim ctx_pack==C9; BOARD C9 before OUT | Hierarchical bind not on UART |
| LM3 | Host does not generate final answer | **PASS** | BOARD OUT from FPGA; host sent exam tok not next-token | — |

Do **not** tick LM from `lm_path` sticky alone. This bit is stronger than that.

## 9. Reset/retrain (2) — **no separate board bit**

Checklist is behavioral only. Same `1F0F2ABB` capture already did it.

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| R1 | Forget/reset removes learned behavior | **PASS** | BOARD `forget_HOLD_A` pack=`2322832182208180` OUT=237 (`exam_log.json`) | — |
| R2 | Retrain different mapping | **PASS** | BOARD HOLD_B C9=`8382438142804140` OUT=60 | — |

`RESET_RETRAIN_XSIM=PASS` (`5ba97a5`). `RESET_RETRAIN_BOARD` for these two boxes is **PASS** on the existing capture. Do not build a reset-only bit.

## 10. Claims (5)

| # | Checkbox | Class | Evidence | Missing |
|---|----------|-------|----------|---------|
| C1 | P_LM=802816 separate | **PASS_NARROW** | TinyGPT 803k / HS-10 | Freeze-time claims file |
| C2 | Encoder params separate | **PASS_NARROW** | Encoder parked; P_enc=0 this SoC | — |
| C3 | Graph nodes not in P_LM | **PASS** | 20 facts ≠ parameters | — |
| C4 | No open-domain/LLM claim | **PASS** | GATE14_PASS=NO | — |
| C5 | Ceilings vs throughput | **OPEN_METRIC** | — | Report |

## Root B (not a checkbox)

| Item | Class | Action |
|------|-------|--------|
| ACK without write (33rd vis_w) | LATENT | Known limitation / future |
| WDMA adapter overflow | LATENT; TinyGPT 1-cycle | Known limitation / future |
| AXI WDMA B-in-flight | INCONCLUSIVE | Not a §14 box |

Do **not** mix into a final Gate14 bit.

---

## What a final bit would be for (if built)

**Not:** teacher-off bit, reset bit, LM bit, metric bit as four programs.

**Only if** HS-02 is applied strictly to T1–T2 and T5–T9:

```text
freeze current C9 SoC + epoch store
+ UART export of n_host_* (and optional teacher/ext_llm named bits)
+ no law change (oracle/C9/scorer/TopK/TinyGPT/bind)
→ unique SHA → one preregistered blind run
→ live n_host=0, MODE=8, HOLD_A/U/C/B
```

If doctrine accepts MODE=8 + HOST_FORBIDDEN=0 + RTL tie-off as HS-02,
**no new bit is required** for remaining OPEN_BOARD. Remaining work is
metric reports (OPEN_METRIC), not silicon.

---

## Recommended decision (this reconciliation)

```text
TRUE_LAW_GAPS              = 0
TRUE_BOARD_OBSERVABILITY   = 7 named HS-02 flags (or 0 under MODE=8 doctrine)
TRUE_METRIC_REPORTS        = 5
RESET_RETRAIN_BOARD_BIT    = NOT_REQUIRED
TEACHER_OFF_ONLY_BIT       = NOT_REQUIRED (fold into one final bit IFF strict HS-02)
LM_ONLY_BIT                = NOT_REQUIRED
ROOT_B_ON_FINAL_BIT        = NO
READY_TO_PROGRAM           = NO   (until freeze+observability decided)
PROGRAM                    = NO
GATE14_PASS                = NO
```

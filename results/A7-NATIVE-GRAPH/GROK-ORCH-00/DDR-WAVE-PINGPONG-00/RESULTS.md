# RESULTS — DDR-WAVE-PINGPONG-00

```text
RTL_EDIT    = YES
  a7ng_cue_soa_wavefront.sv   dual-bank, MAX_INFLIGHT_WAVES=2, same RID
  a7ng_cue_soa_mig_top.sv     ISSUE waits core only (not Global busy)
BIT         = NO
PROGRAM     = NO
SYNTH_IMPL  = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
BURST       = 16
R_FIFO_DEPTH= 4
evidence    = MIG_XSIM + XSIM C9
```

One unknown: can dual-bank two-outstanding prefetch hide recurring
DDR RTT and cut II_STEADY below 46 without changing TopK / Fold6 /
scorer / C9 / LM / oracle.

Overlapping bursts use **one AXI RID**. Sequential R fills bank 0 then
bank 1. No cross-ID order assumption.

---

## Success table

| Check | Result |
| --- | --- |
| waves / AR / beats / bytes | **4 / 4 / 64 / 1024** |
| outstanding_HW / inflight_HW | **2 / 2** |
| AR_OVERLAP | **3** |
| AR(N+1) before LAST_R(N) | **yes** |
| same RID (arid=0) | **yes** |
| drop / dup / overwrite / OOO | **0 / 0 / 0 / 0** |
| RRESP / RLAST / RID_ORDER | **0 / 0 / 0** |
| II_STEADY | **40** < 46 |
| T_QUERY | **281** < 310 |
| SORT_FINAL (md / gv / sort / drop) | **4 / 1 / 28 / 0** |
| SOA_TOPK_PULSE | id=60 score=232 |
| DDR-WAVE-PINGPONG-00 | **PASS** |

Per-wave:

| w | AR_FIRE | LAST_R | ACCEPT | AR(N+1)<LAST_R(N) |
| -: | ---: | ---: | ---: | --- |
| 0 | 1 | 42 | 43 | 19 < 42 |
| 1 | 19 | 58 | 79 | 45 < 58 |
| 2 | 45 | 84 | 119 | 81 < 84 |
| 3 | 81 | 120 | 159 | — |

Accept gaps: **36 / 40 / 40**. II_STEADY = max(W1–W2) = **40**.

P3P4 companion:

```text
T_QUERY     = 281   (was 310)
T_RUN       = 159   (was 188)
C_D         = 121 / 0 / 0 / 0   (W0 fill; later waves hidden)
C_T_MAX     = 33
C_L_MAX     = 31
C_G         = 23 / 16 / 16 / 53
G_SORT      = 28
cand/cycle  = 0.227758
```

`C_D_MAX=121` is ST_FETCH occupancy while two bursts overlap. It is
**not** II. After W0, C_D per accept is 0.

---

## What changed

1. **Dual-bank field-split wave buffers** (not 128b distributed RAM).
2. **MAX_INFLIGHT_WAVES=2**, whole-wave AR, **arid=0** for every burst.
3. Next AR issues as soon as a bank slot exists — **before** LAST_R of
   the previous burst.
4. **ISSUE no longer waits for `global_topk_busy`.** Global still
   accepts only in ST_IDLE. Intermediate C_G (16–23) is covered by
   NG02 C_L=31, so local topk arrives after Global is idle. Holding
   ISSUE on Global re-exposed II=55 after DDR was hidden.

Path @ PHYS=4: 1032 → 744 → 628 → 500 → 432 → 397 → 310 → **281**.

II limiter is now **C_T=33** (TermGen fold6), not DDR.

---

## Frozen / not this gate

```text
FROZEN_C9  = PASS 8382238122802120
FROZEN_OUT = PASS 653/689/237/60
BIT        = NO
PROGRAM    = NO
GATE14_PASS= NO
M10        = KEEP_OPEN
```

NEXT = `ROOFLINE-REMEASURE-05`. Then prefer M10 sparse retrieval
unless that remeasure shows a remaining pathological pipeline barrier.

Do not program. Do not merge as Gate14 pass.

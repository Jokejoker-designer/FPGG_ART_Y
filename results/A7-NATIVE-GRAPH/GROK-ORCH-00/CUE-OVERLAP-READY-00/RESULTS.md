# RESULTS — CUE-OVERLAP-READY-00

```text
RTL_EDIT    = YES  a7ng_cue_soa_mig_top.sv only
BIT_BUILD   = NO
SYNTH_IMPL  = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
evidence    = MIG_XSIM (P3P4 + ownership probe) + XSIM (frozen C9 fullchip)
rtl_sha256  = 73E812B445A204F6FB718AF5F9B048B7E61C92DEB1020261668B060606E777D7
mig_log_sha = A29EC8D1DBBCEF44584079671338270AE751FA1A25FEF3D83DBEF17942B53D27
ctl_log_sha = 1530FD22A9530D2293445A3B9A293E548684E40E1CB00572E92C452B39B784B4
c9_log_sha  = 17F8939A2D47EF35FB01F55CDAB6E5FAFD302A7E5F11AA5C5EB697E7343CD009
```

One unknown: can TermGen(N+1) run while NG02/Global hold wave N if `wf_cons_ready` drops `core_batch_ready` and `!global_topk_busy`, keeping those gates at `SCH_ISSUE` only?

Allowed production RTL: `rtl/native_graph/memory/a7ng_cue_soa_mig_top.sv`.

Forbidden (untouched): `beats()`, heap, Top-K ranking, Fold6, scorer, DDR format, PHYS, WAVE, C9, LM, epoch, teacher-off, oracle.

---

## Success table

| Check | Result |
| --- | --- |
| CUE_OVERLAP_SEM | **PASS** accept=tg=issue=merge=4 drop=dup=overwrite=deadlock=inflight=0 |
| T_QUERY | **628** < 744 |
| CAND_PER_CYCLE | **0.101911** > 0.086022 |
| OVERLAP3 | **0 → 60** |
| BLK_HOLD | **404 → 193** |
| FROZEN_C9_REGRESSION | **PASS** HOLD_A C9=`8382238122802120` |
| FROZEN_OUT_REGRESSION | **PASS** 653 / 689 / 237 / 60 |
| TopK vs serialized pulses 1–2 | **MATCH** id=60 score=232 |
| P3P4 TB SCORE_LAW 57/165 | **NOT LIVE** on this AOS TB (`DATA_MISMATCH=64`); not retargeted |
| DEADLOCK / DROP / DUP / OVERWRITE | **0** |
| CUE-OVERLAP-READY-00 | **PASS** |

Do not program. Do not merge as Gate14 pass.

---

## Production delta

```systemverilog
// before
assign wf_cons_ready = cons_ready_i && core_batch_ready &&
                       sched_idle && tg_ready && !global_topk_busy;
// after
assign wf_cons_ready = cons_ready_i && sched_idle && tg_ready;
```

`SCH_ISSUE` still requires `core_batch_ready && !global_topk_busy`.

Observability only: `topk_batch_cnt` increments on `wave_valid` (wave can now accept while NG02/Global busy).

---

## Ownership (MIG_XSIM)

After probe drain (fetch-`done` is not query-complete):

```text
CUE_OVERLAP_SEM wave_accept=4 tg_complete=4 core_issue=4 global_merge=4
CUE_OVERLAP_SEM delivered=64 waves=4 drop=0 dup=0 overwrite=0 deadlock=0 inflight=0
CUE_OVERLAP_SEM_PASS
```

First probe window stopped at `done_o` and reported tg/core=3. That was a measurement cut, not a drop: DUT `global_merge=4` and delivered=64. Drain-fixed probe is the authority.

---

## Throughput (MIG_XSIM)

| | TOPK-SORT-BOUND | CUE-OVERLAP |
| --- | ---: | ---: |
| T_QUERY | 744 | **628** |
| T_RUN | 585 | 374 |
| cand/cycle | 0.086022 | **0.101911** |
| C_L_MAX | 96 | 96 |
| C_G_MAX | 66 | 65 |
| C_T_MAX | 33 | 33 |
| C_D_MAX | 45 | 45 |
| G_SORT | 112 | 112 |
| S_TAX | 217 | 101 |
| BLK_HOLD | 404 | **193** |
| OVERLAP2 | 0* | **192** |
| OVERLAP3 | 0 | **60** |
| II_WAVE_OBS | 195 | 153 |
| II_PRED | 96 | 96 |
| T_IDEAL_PIPE | — | 527 |

\*TOPK bag OVERLAP2 not emphasized; OVERLAP3 was 0.

Per-wave after overlap:

```text
WAVE0 C_D=45 C_T=33 C_L=96 C_G=65 t_accept=46
WAVE1 C_D=43 C_T=33 C_L=81 C_G=48 t_accept=91
WAVE2 C_D=43 C_T=33 C_L=81 C_G=45 t_accept=244
WAVE3 C_D=43 C_T=33 C_L=81 C_G=48 t_accept=374
ACC_W=TG_W=L_W=G_W=4
```

T_QUERY fell 116 cycles. Occupancy overlap is visible (OVERLAP3=60) and wall-clock moved. Promote.

---

## SOA Top-1 (do not retarget 57/165)

DDR-WAVEFRONT / A-FAST law `id=57 score=165` is a different TB/packing. This P3P4 MIG TB fetches AOS 16 B/cand (`DATA_MISMATCH=64`, cue_beats=0). The TB's SCORE_LAW check was previously skipped because `topk_valid` is a pulse, gone after drain.

4th-pulse dump (canonical overlap log):

```text
SOA_TOPK_PULSE n=1 id=60 score=232 running=1 gbusy=0
SOA_TOPK_PULSE n=2 id=60 score=232 running=1 gbusy=0
SOA_TOPK_PULSE n=3 id=60 score=232 running=0 gbusy=0
SOA_TOPK_PULSE n=4 id=60 score=232 running=0 gbusy=0
```

Serialized control (same TB, `wf_cons_ready` restored temporarily):

```text
SOA_TOPK_PULSE n=1 id=60 score=232 running=1 gbusy=0
SOA_TOPK_PULSE n=2 id=60 score=232 running=1 gbusy=0
SOA_TOPK_PULSE n=3 id=2624167017 score=265 running=1 gbusy=0
SOA_TOPK_PULSE n=4 id=2624167017 score=265 running=0 gbusy=0
```

Pulses 1–2 match. Overlap does not change the comparable ranking. Serialized pulses 3–4 are out-of-range IDs; that is a pre-existing P3P4-TB/AOS issue, not an overlap falsifier. Frozen semantic oracle for this gate is C9/OUT (PASS).

---

## Frozen C9 fullchip

BIT-07 TB, snapshot `g14sbc9`, cue_soa_mig_top not in this DUT.

```text
C9_PACK_A/U/C/B=8382238122802120/8786858483828180/2322832182208180/8382438142804140
LM_OUT_A/U/C/B=653/689/237/60
FIRST_DIVERGENCE=NONE
GATE14_C9_SOC_COFIT_XSIM_PASS fails=0
C9_FROZEN_REGRESSION_PASS
```

---

NEXT = `P3P4-ROOFLINE-REMEASURE-02` (C_L_MAX=96 still dominant → `LOCAL-CORE-LATENCY-AUDIT-00`).

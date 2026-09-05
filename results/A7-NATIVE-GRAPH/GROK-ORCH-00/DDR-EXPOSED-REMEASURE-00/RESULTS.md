# RESULTS — DDR-EXPOSED-REMEASURE-00

```text
RTL_EDIT    = NO
SYNTH_IMPL  = NO
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
evidence    = MIG_XSIM  (bind-only probe)
BASE        = 24dcdc10c0beefafaefdf5c4bc6da51ae13d3ded
```

One unknown: after `GLOBAL-SORT-FINAL-ONLY-00`, is II=45 a
**recurring DDR exposed wait**, a **startup-only fill**, or a
**launch-coupling gap**?

Production RTL, MAX_OUT, FIFO depth, burst length, ping-pong, MIG,
PHYS, TopK, and oracle were not changed. C9 was not re-run
(`RTL_EDIT=NO`).

---

## Success table

| Check | Result |
| --- | --- |
| `DDR_EXPOSED_REMEASURE_PASS` | **yes** |
| `DDR_EXPOSED_REMEASURE_MIG_OK` | **yes** |
| waves / fetch / accept | **4 / 4 / 4** |
| AR / R / MIG AR / MIG R | **4 / 64 / 4 / 64** |
| bytes / beats / bursts | **1024 / 64 / 4** |
| R backpressure | **0** |
| FIFO high-water | **1** |
| outstanding high-water | **1** |
| prefetch inflight high-water | **1** |
| RRESP / RLAST / RID errors | **0 / 0 / 0** |
| drop / empty_stall | **0 / 0** |
| production RTL vs BASE | **unchanged** |

`SOA_PATTERN_FAIL` (`TOPK_NEVER_VALID`, bytes 1024 vs 832) is the
known FINAL-ONLY TB leftover: one ordered pulse after `running=0`,
AOS 16 B/cand. `P3P4_REPAIR_TB_PASS` still printed. Not a
remeasure fail.

---

## Per-wave (probe, running-relative cycle)

| w | AR_FIRE | FIRST_R | LAST_R | FETCH_DONE | AVAIL | ACCEPT | NEXT_AR |
| -: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 3 | 27 | 44 | 46 | 46 | 46 | 50 |
| 1 | 50 | 74 | 89 | 91 | 91 | 91 | 95 |
| 2 | 95 | 119 | 134 | 136 | 136 | 137 | 141 |
| 3 | 141 | 165 | 180 | 182 | 182 | 188 | 0 |

Derived:

| w | AR_TO_FIRST_R | R_DRAIN | FETCH_SERVICE | INTERWAVE_AR_GAP | EXPOSED_HOLD* | EXPOSED_FETCH | n_ar | n_r | C_G |
| -: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | **24** | 18 | **44** | 47 | 0 | **45** | 1 | 16 | 23 |
| 1 | **24** | 16 | **42** | 45 | 0 | **9** | 1 | 16 | 19 |
| 2 | **24** | 16 | **42** | 46 | 1 | **0** | 1 | 16 | 16 |
| 3 | **24** | 16 | **42** | 0 | 6 | **0** | 1 | 16 | 45 |

\* Probe print `EXPOSED_HOLD` is `WAVE_ACCEPT − WAVE_AVAILABLE`, not
`ST_HOLD` occupancy. `HOLD_WAIT_TOT=0`. W3's 6-cycle accept lag is
scheduler/consumer, not DDR R stall.

LAST_R → NEXT_AR (launch after previous drain): **6 / 6 / 7** cycles.

Accept gaps: **45 / 46 / 51**. II_STEADY uses W1–W2 only = **46**.

---

## Four separated terms

| Term | Value | What it is |
| --- | ---: | --- |
| **C_D_SERVICE** | **44** max; **44/42/42/42** | AR_FIRE → FETCH_DONE. Recurring every wave. AR_TO_FIRST_R=24 every wave (MIG RTT inside fetch, not one-time calib). |
| **C_D_EXPOSED** | W0 **45**; W1–W3 **9+0+0=9** | Occupancy of ARM/FETCH while consumer ready and wave not yet valid. **Startup-dominated.** Probe `C_D_EXPOSED_TOT=130`; P3P4 `C_D_EXPOSED=129`. |
| **II_STEADY** | **46** | max(ACC_W1−ACC_W0, ACC_W2−ACC_W1) = max(45,46). Matches C_D_SERVICE + 4-cycle ARM. P3P4 `II_PRED=45`, `II_WAVE_OBS=51` (last-wave gap, not steady). |
| **FINAL_G_TAIL** | **122** | `last_g=310 − ACC_W3=188`. Last-wave C_T+C_L+C_G after last accept. **Not DDR.** |

P3P4 companion (elig, unchanged vs FINAL-ONLY):

```text
T_QUERY     = 310
T_RUN       = 188
C_D         = 45 / 43 / 43 / 43
C_T_MAX     = 33
C_L_MAX     = 31
C_G         = 23 / 19 / 16 / 45
C_D_MAX     = 45
G_SORT      = 28
BLK_HOLD    = 7
BLK_GLOBAL  = 3
BLK_CORE    = 2
cand/cycle  = 0.206452
```

Probe `T_QUERY=188` is the running window (last accept). Elig
`T_QUERY=310` is last merge_done / last Global idle.

---

## Classification (EVIDENCE)

1. **C_D_SERVICE is the II limiter, and it is recurring.**
   II_STEADY=46 ≈ FETCH_SERVICE 42–44 + ARM 4. Intermediate C_G
   (23/19/16) and C_L=31 and C_T=33 are all below II.

2. **C_D_EXPOSED occupancy is startup-only.** W0 fill=45, W1 leftover=9
   because C_T=33 < FETCH_SERVICE=42, then W2–W3 exposed fetch=0.
   Do not read this as “DDR is already hidden on II.” Fetches are still
   serialized: next AR fires only after previous WAVE_ACCEPT
   (`MAX_OUT=1`, one plane buffer, fetch N+1 arms on `do_wave` of N).

3. **Not a large launch gap.** LAST_R→NEXT_AR is 6–7 cycles
   (ACCEPT+ARM). INTERWAVE_AR_GAP 47/45/46 is the next fetch's
   service, not an idle hole. `DDR-LAUNCH-DECOUPLE-00` does not apply.

4. **TAKE-SIFT would not move II_STEADY.** Intermediate C_G is already
   16–23. Cutting CAND+NEXT attacks FINAL_G_TAIL / last-wave C_G, not
   the 46-cycle accept interval.

5. **Ping-pong is the II attack.** To hide FETCH_SERVICE from II,
   fetch N+1 must overlap fetch N (second wave buffer). Overlapping
   fetch N+1 with compute N is already happening and is not enough
   (`C_T=33 < 42`).

`P3P4_DDR_PREFETCH_INDICATED=YES` agrees.

---

## Decision after measurement

```text
recurring C_D_SERVICE on II     → DDR-WAVE-PINGPONG-00
startup-only C_D_EXPOSED occ.   → does NOT override the II fact
large launch gap                → NO (6–7 cy LAST_R→NEXT_AR)
GLOBAL-TAKE-SIFT-00             → do not open for II
```

NEXT = `DDR-WAVE-PINGPONG-00`.

This gate does **not** implement ping-pong. Do not change MAX_OUT,
FIFO, burst, MIG, PHYS, TopK, or oracle here.

Path @ PHYS=4: 1032 → 744 → 628 → 500 → 432 → 397 → **310** (unchanged).

---

## Frozen / not this gate

```text
FROZEN_C9  = HOLD (not re-run; BASE 8382238122802120)
FROZEN_OUT = HOLD (BASE 653 / 689 / 237 / 60)
BIT        = NO
PROGRAM    = NO
GATE14_PASS= NO
M10        = KEEP_OPEN
```

Do not program. Do not merge as Gate14 pass.

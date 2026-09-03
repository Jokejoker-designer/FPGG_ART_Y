# RESULTS — P3P4-METRIC-REPAIR-00

```text
RTL_EDIT    = NO
BIT_BUILD   = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
burst       = 16
outstanding_i = 4   (silicon regs; plane engine still MAX_OUT=1)
evidence    = MIG_XSIM  Digilent MIG + ddr3_model
log_sha     = EC324803C4A5244AEDB5315E92B35B1EC56E650B3F8A33BCE2C53E8CDF2C06D1
probe_sha   = 98C2942907D3BDB6CBA9E96B06F6313A401D05FC3CFCBB368FC2480903D05AEA
```

Packing-expect 832 B is sealed-TB history. This path is AOS 1024 B / 64. That FAIL is packing, not a metric miss.

---

## Query roofline (authority)

```text
T_RUN           = 801     running_o window (matches MEASURE-01 control shape; burst=16 vs burst=1)
T_QUERY         = 1032    running + last-wave drain (TG/NG/Global after running_o falls)
cand/cycle      = 0.062016
C_D_EXPOSED     = 45      all of it is WAVE0 fill
C_D_SERVICE_OCC = 169     raw ST_FETCH occupancy (hidden after WAVE0)
C_T_OCC         = 128     η_TG = 0.750000 = 6/8 protocol
C_L_OCC         = 511     NG02 scorer + local heap + ST_PUSH
NG_PUSH         = 32      = 4 waves × 8
C_G_OCC         = 368
G_SORT          = 256     = 4 waves × 64  (per-wave ST_SORT, not final-only)
empty_stall     = 0       P4 counter; NOT the same as C_D_EXPOSED
OVERLAP2        = 151
OVERLAP3        = 0
BLK_HOLD        = 621     wavefront in HOLD, compute will not accept
BLK_GLOBAL      = 287
BLK_CORE        = 358
BLK_SCHED       = 0
BLK_TG          = 0
AXI             = 1024 B  (16 B/cand, full scan)
```

## Per-wave service

| wave | C_D | C_T | C_L | C_G | t_accept | sum |
| ---: | --: | --: | --: | --: | -------: | --: |
| 0 | 45 | 33 | 132 | 101 | 46 | 311 |
| 1 | 43 | 33 | 117 | 84 | 313 | 277 |
| 2 | 42 | 33 | 117 | 102 | 548 | 294 |
| 3 | 43 | 33 | 117 | 0* | 801 | 193 |

`*` WAVE3 `C_G` latch missed (`G_W=3`). Occupancy `C_G_OCC=368` and `G_SORT=256` are the authority that the fourth sort ran. Drain after `T_RUN` is 231 cycles ≈ last-wave `C_T+C_L+C_G`.

```text
II_WAVE_OBS     = 267     max t_accept gap
II_PRED_MAX_Ci  = 132     = max(C_L)  ← stage ceiling
FILL0           = 311
T_IDEAL_PIPE    = 707     = 311 + 3×132
S_TAX           = 325
S_PCT           = 0.315
```

---

## Hypotheses

| claim | verdict |
| --- | --- |
| H_CANDIDATE: serialized FSM, S_tax large, Fold6 protocol II=8, Global sorts every wave, C_D_exposed may be fill-only | **SUPPORTED** |
| H_RIVAL: DDR is the wall-clock limiter | **FALSIFIED** after WAVE0. `empty_stall=0`. `BLK_HOLD=621` = compute not accepting a wave that is already fetched. |

η_TG = 0.75 is exactly 6 arithmetic steps / 8 protocol cycles. `C_T_MAX=33` ≈ `16/4×8`. Arithmetic floor remains `24` cycles/wave (`TERMGEN-II6-00`). That is **not** `II_PRED`.

`II_PRED = C_L = 132`. Local NG02 (score + stream heap + ST_PUSH) is the stage ceiling. Global `C_G_MAX=102` with **64 ST_SORT cycles every wave** (`256/4`).

`OVERLAP3=0`: never three of {DDR, TG, NG, Global} busy together. Pairwise overlap is DDR fetch of N+1 vs compute N, and NG `ST_PUSH` vs Global.

---

## What this does **not** authorize

- Increasing PHYS (PHYS=16 already showed T_query does not fall).
- DDR outstanding/prefetch as the next gate (`C_D_EXPOSED` is WAVE0 fill only; later waves wait in HOLD).
- GATE14_PASS / BOARD_PASS / program / oracle retarget.
- Treating `empty_stall=0` as “no DDR”. Service occupancy is 169; exposed wait after fill is 0.

---

## Next gate (plan order, now evidence-ranked)

Plan row 2 remains `TOPK-SORT-BOUND-00` (64 → ~29 sort cycles) because both `C_L` and `C_G` pay the rectangular sort. Then `GLOBAL-SORT-FINAL-ONLY-00` (4×sort → 1×sort, 256 → ~64 sort cycles). Then `CUE-OVERLAP-READY-00` to spend `BLK_HOLD=621`.

`TERMGEN-II6-00` is real (`η=0.75`) but below the ceiling. DDR prefetch stays parked.

# RESULTS — G14-RESET-RETRAIN-00

```text
RESET_RETRAIN_XSIM           = PASS
FIRST_DIVERGENCE             = NONE
ROOT_CAUSE                   = n-a
FULL_CHIP_REGRESSION         = PASS  (C9+OUT 653/689/237/60 + A_NOT_RESURRECTED)
READY_TO_PROGRAM             = NO
PROGRAM                      = NO
GATE14_PASS                  = NO
BOARD_PASS                   = not_claimed
NATIVE_V1_MINI_AI_BOARD_PASS = NO
```

No FPGA program. No new bit. Frozen oracle / epoch / TinyGPT / bind untouched.

---

## Graph C9 (`XSIM`) — slot vis + C9

| Phase | GEN | seq/ack | n_occ | n_vis | n_stale | HOLD_A/B C9 |
|-------|-----|---------|-------|-------|---------|-------------|
| BASELINE | 2 | 0/0 | 0 | 0 | 0 | `2322832182208180` |
| A_VISIBLE | 2 | 20/20 | 20 | 20 | 0 | **`8382238122802120`** |
| RESET | 3 | 20/20 | 20 | **0** | 20 | `2322832182208180` |
| B_VISIBLE | 3 | 40/40 | 20 | 20 | 0 | **`8382438142804140`** |
| A_NOT_RESURRECTED | 3 | 40/40 | 20 | 20 (B rows) | 0 | HOLD_A `2322832182208180` |

After TRESET, A rows stay occupied with stamp=2 but `vis_w=0` (stale). Retrain B overwrites those slots (`rel=2 obj=C000 stamp=3`). HOLD_A after B is forget/C3 pack, not A.

Marker: `RESET_RETRAIN_C9_XSIM_PASS`

---

## Full-chip SoC (`XSIM`) — C9 + OUT

| Phase | Evidence |
|-------|----------|
| TRAIN_A | graph=20 rew=20 seq=20 ack=20 |
| A_VISIBLE | HOLD_A C9=`8382238122802120` **OUT=653** |
| RESET | GEN 1→2 |
| A_NOT_VISIBLE | FORGET HOLD_A C9=`2322832182208180` OUT=237 |
| RETRAIN_B | graph=20 rew=20 seq=40 ack=40 |
| B_VISIBLE | HOLD_B C9=`8382438142804140` **OUT=60** |
| A_NOT_RESURRECTED | HOLD_A C9=`2322832182208180` **OUT=237** (not 653) |
| U/C freeze-A | OUT 689 / 237 |

Marker: `RESET_RETRAIN_SOC_XSIM_PASS`

---

## PASS checklist

1. A học đúng trước reset — HOLD_A C9/OUT oracle.
2. Reset làm A biến mất query-visible — vis=0, C9≠A.
3. Không stale epoch-A vis_w — n_vis=0 after TRESET.
4. B commit state mới — seq 20→40, B vis rel=2/obj=C000.
5. Query B = HOLD_B preregistered C9+OUT.
6. Mapping A không tự phục hồi — HOLD_A after B ≠ A oracle.
7. FIRST_DIVERGENCE=NONE.

Do **not** program `1F0F2ABB`. Unique reset/retrain board bit is **not** required for this XSim gate. Next Gate14 items remain teacher-off / LM-06 active chain / scale — not this bit.

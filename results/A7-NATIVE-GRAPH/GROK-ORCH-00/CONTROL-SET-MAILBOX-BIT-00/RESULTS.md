# CONTROL-SET-MAILBOX-BIT-00 — results

**PROGRAM=NO.** Do not overwrite existence `B0F42C11`.

```text
BIT_OK sha256=582F9E4753413B4856E497111A7A29256A1110E00F03D4D89F1B248F74EEF452
WNS=+0.960 TNS=0 RAMB36=103 (unchanged)
```

| | Closure `DD4842DC` | Mailbox `582F9E47` | Δ |
|--|--:|--:|--:|
| LUT | 50665 (79.91%) | **38864 (61.30%)** | **−11801** |
| FF | 57404 | **38053** | **−19351** |
| Slice | 15839 / 15850 | **15446 / 15850** | **−393** |
| Free slices | 11 | **404** | +393 |
| Control sets | 2492 | 2433 | −59 |
| BRAM36 | 103 | 103 | 0 |

Prereg target: ≥1000 free (used ≤14850). Actual free **404**.

```text
MAILBOX_FF_HYPOTHESIS = CONFIRMED   (wavefront FF dump)
SLICE_1000_FREE       = NOT_MET     (404 < 1000)
BRAM_INFER            = NOT_EVIDENCED (RAMB36 still 103; arrays likely LUTRAM after leaving async reset)
```

Still not enough for a learner. Next: more working-set out of FF (r0/r1 banks, AXI-bridge async-reset RAMs) **or** accept 404 as reserve and shrink learner, not FIFO-BRAM→LUTRAM.

Board UART of this SHA needs a **new token**.

# A7-EAM-03E-A0.1 — Timing then seed robustness

**Parent:** `A7-EAM-03E-A.md`  
**Law:** still `eam03e-a0-signsgd-v1` (no law change).  
**A1:** closed.

A0 proved **plasticity**: FPGA forward+update, SAME can shrink, reset erases, swapped labels invert geometry.  
A0 did **not** prove **discriminative** geometry. Seed `0x22222222`: SAME 2135→1487 while DIFF 1679→229,  
`M = d(anchor,DIFF) − d(anchor,SAME) = 229 − 1487 = −1258`.

Authority quantity:

```
M = d(anchor, DIFF) − d(anchor, SAME)
```

Need `M > 0` after train, and preferably `M_post > M_pre`, on the confirmation set.

## A0.1-T — timing only (this bitstream)

Pipeline `pacc` / MAC. **Do not change** law, seed, dataset, or integer outputs.

| Frozen | Value |
|--------|--------|
| Seed | `0x11111111` |
| Strings | `ALPHA` / `BETA.` / `OMEGA` |
| Train steps | 32 SAME+DIFF pairs (TB) |
| `d1` | `Σ (\|hA−hB\| >> 5)` |

Golden (xsim A0, must not move):

| Phase | d1(AB) | d1(AC) |
|-------|-------:|-------:|
| After seed + prime | 3930 | 5362 |
| After 32-step BETA=SAME | **1093** | **2012** |
| After RESEED | 3930 | — |
| After 32-step OMEGA=SAME | 1574 | **451** |

Gate: **WNS ≥ 0, TNS = 0** at 100 MHz, DSP 0, golden integers bit-identical.  
If any golden d1 changes → **regression**, not a timing win.  
No BOARD_PASS on A0 until T and L both PASS.

Datapath change allowed: serialize 64-wide `pacc` to one adder (same sum, commutative); register MAC product then add (same terms, same order); register SignSGD operands (`sgn` / `wdelta`) before the E/Wh write. Arithmetic order unchanged.

### Attempt log (not BOARD_PASS)

| Attempt | Change | xsim golden | WNS / TNS | SHA |
|---------|--------|-------------|-----------|-----|
| A0 | 64-wide pacc | 3930/5362→1093/2012 | **−1.891 / −990.6** | `12DD690C…8059783` |
| A0.1-T pacc | serialize pacc + registered MAC | **identical** | **−0.563 / −5.218** | `7E13CA749FC9189EBC9DACD0D73DEC43AA3B12F4B4D9CA50E7A749F3E9648421` |
| A0.1-T eupd | + register `sgn_r`/`wdelta_r` before sat8 write | **identical** | **−0.119 / −0.407** | `ADD9E46280A697FD40C46911F5E477EF5B3A02EF36FE8054F9642216951C2262` |

pacc bit archived at `results/A7-EAM-03E/a01t_pacc/`. Critical path after pacc was `i_reg → g mux → sat8 → e_wd` (10.46 ns), not projection.

## A0.1-L — L0 baseline only (after T)

No law change. This is **L0** of the A0.2 ablation: same `eam03e-a0-signsgd-v1`, extra EVAL telemetry if the T-closed datapath can carry it without a golden regression.

Law change is **not** this version. See `A7-EAM-03E-A02.md` (**A0.2-L**, `eam03e-a02-triplet-v1`).

If L0 still inverts seed `0x22222222` on both `M_L1` and `M_cos`, that is the A0.2-L reason-to-exist — not a silent `m` tweak.

Kidi bags stay out of T.

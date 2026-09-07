# RESULTS — U6-UNIFIED-RETRIEVAL-00

```text
XSIM = U6_UNIFIED_RETRIEVAL_PASS
```

Independent host golden (not derived from RTL) vs XSim, 15 queries:

| Q | name | mode | ncand | trunc | ovf | top0 | sc0 |
|---|------|------|-------|-------|-----|------|-----|
| 0 | chiller | QSE | 4 | 0 | 0 | 00000000 | 8 |
| 1 | water_chiller | QSE | 22 | 0 | 0 | 00000001 | 16 |
| 2 | leak_chiller | QSE | 4 | 0 | 0 | 00000000 | 8 |
| 3 | payroll | QSE | 0 | 0 | 0 | 00fffff0 | 0 |
| 4 | soccer | QSE | 0 | 0 | 0 | 00fffff0 | 0 |
| 5 | adversarial | QSE | 0 | 0 | 0 | 00fffff0 | 0 |
| 6 | dup_chiller | QSE | 4 | 0 | 0 | 00000000 | 8 |
| 7 | cap64 | POKE | 64 | 0 | 0 | 00001388 | 8 |
| 8 | cap80 | POKE | 64 | 16 | 1 | 000013ec | 8 |
| 9 | sentinel | POKE | 1 | 0 | 0 | 000c34ff | 8 |
| 10 | empty | POKE | 0 | 0 | 0 | 00fffff0 | 0 |
| 11 | unknown | POKE | 0 | 0 | 0 | 00fffff0 | 0 |
| 12 | tie | POKE | 2 | 0 | 0 | 00001770 | 8 |
| 13 | sat_pos | POKE | 1 | 0 | 0 | 00001b58 | 635 |
| 14 | sat_neg | POKE | 1 | 0 | 0 | 00001b59 | -768 |

Cuts A–F: candidate IDs, 20-bit evidence LUT, base/final scores, frozen prior=0 (learn=0), exact Top-8 order including pads.

Causality:

- `POISON_LEGACY_HOLD` — pulsing disconnected `a7ng_learned_prior_graph.query_valid_i` left chiller Top-K unchanged.
- `POISON_AXI n=2 top0=000abcde` — overwriting both T0 and T2 chiller posting beats (identical `{0,1,2,3}`) changed Top-K. One copy is not enough: the other table still supplies the same IDs.

Overflow: Q8 `trunc=16 ovf=1` latched from walker; not silent.

Host semantic OR-counter `n_host=0` on every query.

High ID `799999 = 20'hC34FF` survives AXI → LUT → scorer → Top-K.

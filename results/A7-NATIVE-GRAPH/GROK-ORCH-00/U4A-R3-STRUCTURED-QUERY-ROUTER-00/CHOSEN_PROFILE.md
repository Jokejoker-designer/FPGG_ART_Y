# CHOSEN_PROFILE — U4A-R3 HOST_MODEL, not silicon freeze

```text
QUERY_LAW     = qse-v1-lexicon-hdc-00
GOLD          = ENTITY_CANON labels (not admitted-head union)
CHOSEN        = P4_4k_h64
CAND_CAP      = 64     # Pareto 95%-of-max label-recall then min bytes
label_r16     = 0.952  (P2_8k_h128 ref) / 1.0 at cap 64 on P4
label_r64     = 1.0 on P4
scale_cov P4  = 0.328  (>=0.20)
P2_*          = REJECTED scale coverage < 0.20 (k0 has ~72 distinct values)
P8_2k_h16     = REJECTED scale coverage 0.041
```

800k occupancy is **not** semantic recall. U5 closed. BIT=NO.

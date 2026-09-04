# CHOSEN_PROFILE — HOST_MODEL only, not a silicon freeze

```text
profile     = P2_8k_h128
n_tables    = 2
n_buckets   = 8192
head_cap    = 128
CAND_CAP    = 192     # Pareto 95%-of-max-recall then min bytes
coverage    = 1.0
mean_recall@192 = 0.968
mean_bytes@192  = 3060
P8_2k_h16   = REJECTED coverage=0.0568
```

Gold = rec_keys bucket membership **including overflow**.
`relevant=set(union_of_heads)` is forbidden.
256 is not privileged; sweep included 64..2048.
Not U5. Not a bitstream freeze.

# RESULTS — U4A-R2-SPARSE-ROUTER-RIVAL-00

```text
GOLD            = independent rec_keys bucket membership INCLUDING overflow
relevant=union  = REMOVED
P8_2k_h16       = REJECTED coverage=0.0568 (<0.20)
P2_4k_h64       = keep (cov 0.351, recall@256 0.327 vs gold)
P2_4k_h256      = keep (cov 1.0, recall@256 0.655, head_hit 1.0)
P2_8k_h128      = keep (cov 1.0, ovf 31, head_hit 1.0)
CHOSEN_PROFILE  = P2_8k_h128
CHOSEN_CAND_CAP = 192   # Pareto 95%-of-max-recall then min bytes
                          # NOT the old hard-coded 256
mean_recall@192 = 0.968
mean_bytes@192  = 3060
```

Sweep included 64,128,192,256,384,512,1024,2048 so 256 is not privileged.
P8 fails the coverage reject. Overflowed records stay in gold; true recall@K
is |gold ∩ cands[:K]| / |gold|.

HOST_MODEL only. Not a silicon freeze. Not U5.

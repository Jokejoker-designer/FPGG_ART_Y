# RESULTS — U4A-SPARSE-ROUTER-RIVAL-AUDIT-00

```text
EVIDENCE_CLASS = HOST_MODEL  (not BOARD, not MIG_XSIM)
N              = 800,000 addressable
N_QUERY        = 200
LAW            = qfe-v1-crc16-mix-00
RTL_EDIT       = NO
PROGRAM        = NO
```

Unique-record coverage (records with ≥1 posting):

| Profile | tables | buckets | head_cap | coverage | overflow_posts | dir_bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| **P2_deep** | 2 | 4096 | 64 | **0.351** | 1,075,712 | 65,536 |
| P4_mod | 4 | 4096 | 32 | 0.195 | 2,675,712 | 131,072 |
| P8_shallow | 8 | 2048 | 16 | 0.057 | 6,137,856 | 131,072 |

At cap=256 all profiles admit ~128 cands/query, ~2 kB, dups≈0. `recall_k0=1.0` is tautological once cap ≥ admitted union; **not** Gate14 semantic recall.

Frozen for next RTL (HOST_MODEL, amendable if later quality fails):

```text
ROUTER_PROFILE_FINAL = P2_deep   (2 tables × 4096 × head 64)
CAND_CAP_FINAL       = 256
DDR_QUERY_BOUND_FINAL= 4127 bytes
FULL_SCAN            = NO
```

U4A = **PASS**.

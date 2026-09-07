# PREREG — U6-UNIFIED-RETRIEVAL-00

```text
GATE            = U6-UNIFIED-RETRIEVAL-00
BASE            = 5aa8285533b0f4a571dac5328b28a1f8a5ef5fc1
CANDIDATE_OWNER = a7ng_sparse_dir_axi
LEGACY_PATH     = DISCONNECTED (learned_prior_graph cand_* not in U6 top)
LEARN            = 0
LEARNED_DELTA   = frozen zero
QUERY_LAW       = qse-v1-lexicon-hdc-00
VALIDITY_LAW    = U4A-R6
N_TABLES        = 4
N_BUCKETS       = 4096
CAND_CAP        = 64
K               = 8
ID_W            = 20
BIT             = NO
PROGRAM         = NO
U7A             = CLOSED
U7              = CLOSED
U8              = CLOSED
GATE14_PASS     = NO
```

PRIMARY_UNKNOWN: see user brief.

## Score-term law (FPGA, not host)

Query vs record 8-bit class IDs. `learn=0` ⇒ prior=0, penalty=0, path=0.

```text
entity_match   = (q_ent!=0 && q_ent==r_ent) ? +8 : 0
intent_match   = (q_int!=0 && q_int==r_int) ? +8 : 0
relation_match = (q_rel!=0 && q_rel==r_rel) ? +8 : 0
context_match  = (q_ctx!=0 && q_ctx==r_ctx) ? +8 : 0
```

Directed sat records may carry stored terms. Production corpus records do not.

## Compose tree (must match scorer_lane, not left-fold)

```text
partial = sat(sat(e,i), sat(r,c))
score   = sat(sat(partial, path), sat(prior, -pen))
```

8-bit terms cannot reach ±32767. SAT cases prove RTL==host compose of extreme terms.

## Tie law

`beats()`: valid > score > id < lane <

Underfill: pad to K=8 with `v=0`, `id=32'h00FF_FFF0+i`, `s=0`, `lane=0`.

## Overflow

Latch walker `q_overflow_o` / `n_trunc_o` onto U6 outputs. Truncated search ≠ complete.

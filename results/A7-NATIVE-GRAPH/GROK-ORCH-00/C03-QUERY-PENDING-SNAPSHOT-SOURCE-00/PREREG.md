# PREREG — C03_QUERY_PENDING_SNAPSHOT_SOURCE

```text
GATE              = C03-QUERY-PENDING-SNAPSHOT-SOURCE-00
PARENT            = U9R-FINAL-REGRESSION-00 FAIL QUERY_NO_SNAPSHOT
FROZEN_RTL        = bdddbd68 (do not rewrite U9R bag to PASS)
UNKNOWN           = when SYNTHETIC_CAND_GEN=0, C_FIRE/query must raise
                    snapshot/pending from the live parent Top-K path
                    (not qv_to_graph into cand_* graph)
BIT               = NO
PROGRAM           = NO
U9S               = NO
```

U8R muxes C9 IDs from `graph_id_i` but glue still waits graph snapshot while
`qv_to_graph=0`. Smallest revision: pending/snapshot source = parent
completion, not disabled cand walk. New bag; keep U9R FAIL raw.

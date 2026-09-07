# PREREG — U4A-R4-SELECTIVITY-FALSIFIER-00

Frozen before the run. Do not change qse law, P4, CAND_CAP, gold, routing, or thresholds.

```text
GATE            = U4A-R4-SELECTIVITY-FALSIFIER-00
BASE            = e54096fa656e1dccc7063fb0e28dd7dc67bfcc00
BRANCH          = grok-orch/v31-canonical-00
QUERY_LAW       = qse-v1-lexicon-hdc-00
PROFILE         = P4_4k_h64
CAND_CAP        = 64
GOLD            = independent ENTITY_CANON labels (same as U4A-R3)
RTL_EDIT        = NO
BIT             = NO
PROGRAM         = NO
COM12           = UNTOUCHED
U5              = CLOSED
GATE14_PASS     = NO
EVIDENCE        = HOST_MODEL
```

PRIMARY_UNKNOWN:
Does P4_4k_h64 genuinely discriminate queries, or is recall high because
it admits most/all of the small labeled corpus?

Directed queries (frozen):
1. known FPGA-domain: "chiller"
2. paraphrase: "water chiller"
3. same entity / different intent: "leak chiller"
4. unrelated: "payroll tax form"
5. other-domain: "soccer match score"
6. adversarial: first ADV_SEED string from U3Q-R3 freeze (same LCG)

PASS only if ALL:
1. relevant FPGA queries (1–3) recall >= 0.80 (U4A-R3 frozen; not retargeted)
2. unrelated (4–6) candidate_count < corpus_size
3. unrelated pairwise Jaccard < 1.0 (sets not identical full corpus)
4. reduction_ratio > 0 for unrelated
5. gold independent (not admitted-head union)
6. CRC not used as route key
7. no threshold retarget

If candidate_count ~= corpus_size for most/all queries:
  U4A-R3 QUALITY CLAIM = INVALIDATED
  ROUTER_SELECTIVITY_FAIL
  do not continue to U4 AXI

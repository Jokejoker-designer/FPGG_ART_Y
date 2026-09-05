# RESULTS — U4A-R5-NULL-KEY-TABLE-ABLATION-00

```text
RESULT           = MEASURE_PASS
EVIDENCE_CLASS   = HOST_MODEL
RTL_EDIT         = NO
KEY0_SKIP        = NOT APPLIED
PRIMARY_ANSWER   = ALL4 admit-all is reproduced by T3 alone.
                   k1 is a contributor (12/42 in bucket 0), not the sole cause.
```

## Corpus key occupancy (42 titles)

| key | records == 0 | bucket0 occupancy |
|-----|----------------|-------------------|
| k0 | 0 | 0 |
| k1 | 12 | 12 |
| k2 | 0 | 0 |
| k3 | **42** | **42** |

`k3==0` on every labeled title: none of those strings hit an intent-class word, so `intent_cue` stays 0. `k3==0_and_intent_id!=0` = 0.

## Null queries (payroll / soccer / adversarial)

All have `k0=k1=k2=k3=0`.

| config | null cand count | admit-all? |
|--------|-----------------|------------|
| T0 | 0 | no (empty) |
| T1 | 12 | no |
| T2 | 0 | no |
| **T3** | **42** | **yes** |
| ALL4 | 42 | yes |
| T02 | 0 | no |

`leak chiller` (non-zero intent): T3 count=0, ALL4 count=15. Router **does** discriminate when a non-zero feature exists.

## Law meaning of 0 (frozen qse, not a new invention)

```text
entity/intent/relation/context id 0 = unknown / absent family
k0==0, k1==0 = absent ID composite, not a legitimate family value
k2==0 / k3==0 = no class bind (absent cue) unless a bind XOR-collides to 0
               (not observed on this corpus for k2; k3 is absent-intent)
```

R5 does **not** implement `key==0 → skip`. That belongs to a later validity gate if accepted.

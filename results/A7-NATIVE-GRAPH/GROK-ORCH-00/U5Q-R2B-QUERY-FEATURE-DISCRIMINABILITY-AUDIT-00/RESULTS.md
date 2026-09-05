# RESULTS — U5Q-R2B-QUERY-FEATURE-DISCRIMINABILITY-AUDIT-00

```text
RESULT            = MEASURE_PASS
OVERALL_DIAGNOSIS = PARTIAL_FIELD_COLLISION
NO_EXACT_VIS_TWIN = YES
```

Catalog unique texts. U5Q gold. vis = `{k0,k1,k2,k3,v0..v3}`.

| query | R | exact vis twins | frac inseparable | same k0 | same k1 | same k2 | same k3 |
|-------|---|-----------------|------------------|---------|---------|---------|---------|
| chiller | 323 | **0** | 0 | 0 | 323 | 8 | 323 |
| water chiller | 122 | **0** | 0 | 122 | 122 | 122 | 122 |
| leak chiller | 13 | **0** | 0 | 0 | 13 | 13 | 13 |

No relevant catalog record is **bit-identical** on the full router-visible vector to an irrelevant record.

Therefore **not** `NO_ROUTER_GEOMETRY_CAN_SEPARATE_THEM` at full vis.

Partial collisions are real: T1 (`k1` rel|ctx) and T3 (`k3` intent cue) are shared with hard-negatives for every chiller-family query. `water chiller` collides on **all four** keys with some irrel — matches U5Q precision 0.28.

UNION over colliding tables admits FPs. AND / drop-T1 can reduce FPs (U5Q-R1) but R2A already showed raw grain still cannot meet cap-64 instance recall.

# PREREG — U5Q-R2B-QUERY-FEATURE-DISCRIMINABILITY-AUDIT-00

After R2A. No RTL. No new bit. No program. No profile sweep.

```text
GATE            = U5Q-R2B-QUERY-FEATURE-DISCRIMINABILITY-AUDIT-00
BASE            = 9755147a11efefc37146257e61fa546dc0a5b334
GRAIN_CONTEXT   = R2A TYPE_CLASS fits cap; RAW does not
QUERY_LAW       = qse-v1-lexicon-hdc-00 UNCHANGED
VISIBLE         = {k0,k1,k2,k3,v0,v1,v2,v3}
RTL_EDIT        = NO
BIT             = NO
PROGRAM         = NO
U7A             = CLOSED
```

## Primary unknown

Can `{k0,k1,k2,k3,valid}` separate relevant vs hard-negative
**at TYPE_CLASS grain** (and as catalog instances)?

## Pair test (catalog, unique texts; multiplicity ignored)

For each U5Q confirmation query with non-empty gold:

```text
R = catalog records with U5Q relevant=true
I = catalog records with relevant=false  (hard-negative pool)

route vis = (k0,k1,k2,k3,v0,v1,v2,v3)

N_IDENTICAL_VIS_TWINS
  = |{ r in R | exists i in I with vis(r)==vis(i) }|

N_ROUTE_KEYS_MIXED
  = route keys that contain both R and I

FRAC_REL_INSEPARABLE = N_IDENTICAL_VIS_TWINS / |R|
```

Also per-field: same k0 / k1 / k2 / k3 / valid-mask vs some I.

At TYPE_CLASS: two different class tuples with identical vis
=> router cannot separate those classes.

## Diagnosis

```text
NO_ROUTER_GEOMETRY_CAN_SEPARATE_THEM
  if FRAC_REL_INSEPARABLE > 0 on a bound query
  (exact vis collision relevant vs irrelevant)

PARTIAL_FIELD_COLLISION
  collisions on some k* but not full vis

FEATURES_SEPARATE_AT_CLASS_GRAIN
  no exact vis twin; class tuples unique in vis
```

Does not invent new keys. Does not open U7A.

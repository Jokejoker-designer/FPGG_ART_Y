# PREREG — U7C-LEARN-STORE-LIMIT-00

```text
GATE              = U7C-LEARN-STORE-LIMIT-00
DECISION          = LIMIT (not SCALE)
DEPTH             = 32  (hot working set)
NAK_AT_WRITE      = 33  (distinct TYPE_CLASS × QUERY_CONTEXT keys)
RTL_EDIT          = NO
BIT               = NO
PROGRAM           = NO
800K_ONCHIP       = FORBIDDEN this close path
```

Native V1 close freezes `a7ng_learned_prior_store` DEPTH=32 as the
production working-set LIMIT. 800k records stay off-chip / not hosted.
Do not grow BRAM to 800k in this DAG. Evidence: U7 XSim occupancy 32,
FIRST_NAK_AT_WRITE=33, G14-SCALE-800K-00 C9_800K_STORE=NOT_IMPLEMENTED.

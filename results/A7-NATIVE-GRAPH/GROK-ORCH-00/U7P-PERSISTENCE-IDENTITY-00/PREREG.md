# PREREG — U7P-PERSISTENCE-IDENTITY-00

```text
GATE              = U7P-PERSISTENCE-IDENTITY-00
UNKNOWN           = FLUSH then RELOAD restores learned ranking
RTL_EDIT          = NO
STORE_SCHEMA      = PERSIST-IDENTITY-SCHEMA-V2 Option A (already PASS)
BIT               = NO
PROGRAM           = NO
```

Close-path identity is two-beat DDR `{subj,obj}` then `{rel,pri,pen,stp}`.
Do not force 16-bit IDs. Do not hash identity. persist_gen_fast not this gate.

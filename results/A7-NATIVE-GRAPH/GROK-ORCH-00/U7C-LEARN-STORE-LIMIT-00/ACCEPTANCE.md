# ACCEPTANCE — U7C (qa-only)

```text
VERDICT   = PASS
OVERCLAIM = false
FRAUD     = false
SCOPE     = architecture LIMIT freeze of DEPTH=32 working set
```

## Checks

- RTL parameter `DEPTH = 32` unchanged (RTL_EDIT=NO this gate).
- Fresh U7 XSim after heap/QSE: marker
  `U7_CONTEXTUAL_LEARNING_EFFECTIVENESS_PASS`, occupancy 32, NAK at 33.
- PERSIST_RELOAD_MATCH=1 (used by P4, not claimed as silicon).
- Host semantic counters = 0.
- 800k on-chip is explicitly NOT claimed; G14-SCALE-800K-00 remains
  NOT_IMPLEMENTED.

## Forbidden

Relabel LIMIT as SCALE. Relabel XSim as silicon. Open Q-head to "fix"
capacity. PROGRAM. Reseat `1F0F2ABB`.

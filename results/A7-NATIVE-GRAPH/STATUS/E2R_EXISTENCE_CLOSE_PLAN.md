# Existence close — 2026-08-29

**Goal:** UART `pred=664`.

| Slot | Status |
|------|--------|
| Tile dest after ACK | CHUNK2_GO (stub) |
| POS region | REGION_DONE nline=128 |
| UART after W_STALL | CORE_PRED (replica) |
| ST_EMB TOK↔POS sets | OSC_2ND |
| Full-fwd switches | 2048 (not 4.3e6 misses) |
| TOK/POS switch = miss? | **this turn** (THRASH-NEXT) |
| From-boot ≥40 min | PREP_READY; wait `com12_authorized_gate=E2R-UART-HOLD-LONGBOOT-00` |
| EXISTENCE | **NO** |

No C-FIX. Do not reprogram on leftover REARM. Do not task `graph_late_materialize_00`.

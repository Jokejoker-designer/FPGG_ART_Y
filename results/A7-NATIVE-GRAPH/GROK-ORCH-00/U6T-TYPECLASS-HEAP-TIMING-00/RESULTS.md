# RESULTS — U6T

| Stage | WNS | TNS | failing EP |
|---|---:|---:|---:|
| U6 synth-only (control) | -4.103 | -3562 | 948 |
| OOC route no RTL | -5.783 | -4471 | 930 |
| OOC route HEAPIFY 2-phase | -3.349 | -89 | 50 |

Worst post-patch path: QSE `wbuf_reg → entity_id_o_reg` (not heap).
U6 XSim marker still `U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS`.

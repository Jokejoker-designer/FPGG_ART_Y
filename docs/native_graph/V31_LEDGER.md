# V31 ledger (PLAN §10)

Parent selects by requested `start_gate` + this table. Scout may not rewind an accepted gate.

| gate_id | status | evidence_class | source SHA | next | scope |
|---|---|---|---|---|---|
| U8-R3 | ACCEPTED | XSIM structural | encoder `bbd95f7f` | historical | Top-K→LM pred=861 MISMATCH; note “do not open U8R/U9” is **this bag’s** scope, not global |
| U8-SOC-ROOTB-WDMA-00 | ACCEPTED | SLICE_XSIM | `3b3aebe` | residual C04 | dest ready not wired through production core |
| U8R-REMOVE-SYNTHETIC-PRODUCTION-00 | ACCEPTED | XSIM + RTL_FACT | `bdddbd68` | residual C03 | C9 mux source; not query/reward liveness |
| U9-FINAL-SOURCE-FREEZE-00 | ACCEPTED | docs/manifest | `4ca071e` freeze docs; PRODUCTION_RTL=`bdddbd68` | P10 | freeze ≠ Master satisfaction |
| U9R-FINAL-REGRESSION-00 | FAIL | XSIM + RTL_FACT | pin `bdddbd68` | C03 (not U9S) | R2 QUERY_NO_SNAPSHOT; bag immutable |
| C03-QUERY-PENDING-SNAPSHOT-SOURCE-00 | PASS | XSIM + RTL_FACT | revision after freeze | C02 | parent snap+G1 pending; qv_to_graph=0; not soc_top |
| C02-PRODUCTION-PATH-INTEGRATION-00 | PASS | XSIM + RTL_FACT | ab_core u_tc | UART residual | prod_tc_lm shares TinyGPT; soc_top UART not feeding tc_tok; FULL_SOC INTEGRATION_GAP |

Prerequisite residuals (not covered by accepted PASS): C02 integration, C03 pending/snapshot, C04 WDMA dest ready, C05 M10 member evidence, C06 oracle 861≠653, C09 reset/retrain, C10 host-leak negative tests.

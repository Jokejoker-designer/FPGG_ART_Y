# RESULTS — U3-DDR-WAVE-PINGPONG-00

V3.1 DAG close. No new RTL. Evidence already on `492277f` and reconfirmed by U1 canonical harness (`T_QUERY=275`).

| Check | 492277f bag | U1 harness |
| --- | ---: | ---: |
| dual_bank / MAX_INFLIGHT | 2 | 2 |
| same RID | yes | yes |
| AR(N+1) before LAST_R(N) | yes | yes |
| outstanding_HW | 2 | 2 |
| AR_OVERLAP | 3 | 3 |
| drop/dup/ovw/ooo | 0 | 0 |
| RRESP/RLAST/RID | 0 | 0 |
| II_STEADY | 40 < 46 | 40 |
| T_QUERY | 281 | **275** |
| bytes/beats | 1024/64 | 1024/64 |

U1 TOP1 id=9 score=165 is the AOS-schema golden. Ping-pong bag 60/232 was the legacy harness golden, not a DUT change.

U3 = **PASS**. PROGRAM=NO.

# LIMIT — mig_board

| Limit | Meaning |
|-------|---------|
| Evidence_class | BOARD_MIG ≠ Native V1 BOARD_PASS |
| Not HS-02 | Teacher-off / blind exam out of scope |
| Not equality | BOARD stall ≠ MIG_XSIM stall cell-for-cell |
| cons(4,8)=68 | Slight overshoot vs TOTAL=64 (AR pipe); DROP=0 |
| Sticky-done r1 | Superseded capture archived as `*_r1_sticky_done.*` |

**Allowed claim:** Digilent AXI MIG silicon ddr_feed stall_frac (1,1)/(4,8) on Arty A7-100T; mig.prj MATCH.

**Forbidden claim:** Native V1 BOARD_PASS; invent GB/s; XSim = board; hand-edit mig.prj.

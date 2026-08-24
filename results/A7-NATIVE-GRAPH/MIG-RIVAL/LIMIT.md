# LIMIT — mig_h_rival (post-repair)

| Limit | Meaning |
|-------|---------|
| H_RIVAL FALSIFIED | Digilent MIG_XSIM rows exist; "synthetic-only" rival rejected |
| Evidence_class | MIG_XSIM ≠ BOARD silicon PE stall |
| TOTAL=64 | Reduced vs synthetic 256 |
| Not BOARD_PASS | No silicon ddr_feed UART claim this gate |
| Not HS-02 | Teacher-off / blind exam out of scope |
| Not equality | Synthetic best 0.475410 ≠ MIG best 0.549296 |

**Allowed claim:** Digilent AXI MIG feed stall_frac (1,1)/(4,8) under ddr3_model XSim; frozen + mig.prj MATCH.

**Forbidden claim:** BOARD_PASS; MIG PE stall = synthetic 0.475410; invent GB/s.

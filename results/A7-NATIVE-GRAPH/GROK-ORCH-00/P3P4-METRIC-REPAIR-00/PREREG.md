# PREREG — P3P4-METRIC-REPAIR-00

```text
GATE        = P3P4-METRIC-REPAIR-00
SOURCE      = cue_soa_mig_top PHYS=4 WAVE=16 (obs SoC / F24150BD lineage)
RTL_EDIT    = NO
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD (C9 653/689/237/60) — not this gate
GATE14_PASS = NO

UNKNOWN     = C_D, C_T, C_L, C_G, II_wave, cand/cycle, S_tax, eta_TG,
              DDR exposed vs DDR service on one 64-cand query
CONTROL     = G14-METRIC-MEASURE-01 MIG_XSIM: T_QUERY ELIG=1699
              FIRE=12 ACT=48 empty_stall=0 axi=1024 delivered=64
UNIT        = one SOA query, N=64, burst=16, outstanding=4 (silicon regs)
              plane engine still MAX_OUT=1 (RTL fact, not changed)
H_CANDIDATE = serialized FSM: II_wave ≈ sum(Ci), S_tax large,
              eta_TG < 1 because Fold6 protocol II=8 not 6,
              C_G includes per-wave ST_SORT, C_D_exposed may be 0
              even if C_D_service > 0 (prefetch of next wave after accept)
H_RIVAL     = DDR is the wall-clock limiter (C_D_exposed dominant)
FALSIFIER   = edit RTL; program; close GATE14; treat empty_stall as C_D_exposed;
              sell PHYS increase as throughput; invent BOARD numbers
EVIDENCE    = MIG_XSIM (Digilent MIG + ddr3_model). Not BOARD.
```

# PREREG — G14-METRIC-MEASURE-01

```text
SOURCE      = exact final-observability RTL lineage (C12 / 29596ac / PHYS=4 / SIM_FULL=0 SoC)
RTL_EDIT    = NO
BIT         = NO
PROGRAM     = NO

P3 UNKNOWN  = lane active / eligible cycles on PHYS=4 via XSim hierarchy
P4 UNKNOWN  = DDR stall cycles of this SoC's SOA path under MIG model
M7 UNKNOWN  = AXI R/W byte delta per complete query on current C9 SoC
M10         = KEEP_OPEN (no 800k experiment this gate)

H_CANDIDATE = hierarchical probes on a7ng_cue_soa_mig_top (SoC u_soa)
              + persist_ddr_we on g1g5 C9 query are enough to tick P3/P4/M7
H_RIVAL     = stub AXI stall ≠ MIG stall; C9 exam has no AXI4 master
FALSIFIER   = edit RTL; program; invent BOARD numbers; close M10; sell
              feeder-only TB as this SoC without saying so
UNIT        = one SOA query (64 cand, burst=16, outstanding=4 = silicon regs)
              + one C9 HOLD_A exam query
```

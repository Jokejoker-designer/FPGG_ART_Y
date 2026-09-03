# RESULTS — G14-METRIC-MEASURE-01

```text
RTL_EDIT    = NO
BIT_BUILD   = NO
PROGRAM     = NO
ORACLE_CHANGE = NO
M10         = KEEP_OPEN
GATE14_PASS = NO
SOURCE      = cue_soa_mig_top PHYS=4 in obs SoC (29596ac / F24150BD lineage)
```

No RTL was edited. New TBs + bind probe only.

---

## P3_LANE_UTIL

Complete 64-cand query (MIG model of SoC `u_soa`):

```text
value           = 0.007063
method          = hierarchical tg_valid_in vs running
                  bind g14_p4_hier_probe on a7ng_cue_soa_mig_top
                  PHYS=4; FIRE=12; ACT_SUM=48; ELIG=1699
evidence_class  = MIG_XSIM
artifact_sha    = p4_xsim.log 7AD953C9975CDFA1717B51D430E34DB01CF8B2F4E4A499268E62F9094975AF62
box_tick        = PASS
```

AXI-stub XSim of the same DUT hung after 32/64 (`ng02` flow_state=6 ST_PUSH,
`batch_ready=0`). Prefix snapshot (not a complete query):

```text
P3_LANE_UTIL_AT_32 = 0.013746   ACT=16 ELIG=291 FIRE=4
evidence_class     = XSIM (stub; incomplete)
```

Eligible = `running_o`. Active = `$countones(tg_valid_in)`.
12 FIRE cycles × 4 PHYS = 48 ACT on the complete MIG query.

---

## P4_DDR_STALL

```text
value           = 0 empty-stall cycles; stall_frac=0.000000
                  r_backpressure_cycles=0
method          = buffer_empty_stall_o + r_backpressure_cycles_o
                  on cue_soa_mig_top under Digilent MIG + ddr3_model
                  (tb_a7ng_ddr_cue_soa + bind probe; no RTL edit)
evidence_class  = MIG_XSIM
artifact_sha    = p4_xsim.log 7AD953C9…
box_tick        = PASS
```

Sealed TB still expects SOA 832 B; current fetch is AOS 1024 B / 64 beats
(`cue_beats=0`). Pattern FAIL is packing-expect, **not** a stall-counter miss.
Query completed: delivered=64, waves=4.

Stub XSim empty_stall=0 is **not** promoted to MIG_XSIM.

---

## M7_DDR_BYTES_PER_QUERY

SOA query (64 cand, complete, MIG):

```text
axi_read_bytes      = 1024
axi_read_beats      = 64
axi_write_bytes     = 0   (preload is before the query window)
bytes_per_candidate = 16.0000
evidence_class      = MIG_XSIM
```

C9 HOLD_A exam (`g1g5_cofit`, no AXI4 master):

```text
axi4_read_bytes           = 0
axi4_write_bytes          = 0
persist_ddr_write_bytes   = 0     (exam window)
flush_persist_write_bytes = 528   (FLUSH, not exam)
evidence_class            = XSIM
artifact_sha              = m7c9_xsim.log 0B588BE211A1164346DCF6148B7E9298009F5BEDDFE3FF423C09F6D1B8EB3222
```

C9 pack in this no-LM wrapper was `2322832182208180` (not HOLD_A oracle).
Byte deltas still stand: exam does not issue AXI4.

```text
box_tick = PASS
```

---

## M10_SCALE_800K

```text
status          = KEEP_OPEN
bytes_per_query = not_proven at 800k
candidates_per_query = not_proven at 800k
scaling_method  = none this gate
evidence_class  = INCONCLUSIVE
box_tick        = OPEN
silent_NA       = REFUSED
```

---

## Rollup

```text
OPEN_METRIC_BEFORE = 4
OPEN_METRIC_AFTER  = 1
P3 = PASS  (MIG_XSIM)
P4 = PASS  (MIG_XSIM stall=0)
M7 = PASS  (MIG_XSIM 1024 B/SOA query; XSIM 0 B/C9 exam)
M10= OPEN  KEEP_OPEN
PROGRAM            = NO
GATE14_PASS        = NO
LAW_GAPS           = 0
XSIM_GAPS          = 0   (P3 stub hang is documented; MIG completed)
BOARD_GAPS         = 0
METRIC_GAPS        = 1   (M10)
FAIL               = 0
```

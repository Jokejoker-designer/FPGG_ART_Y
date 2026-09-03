# RESULTS — G14-OPEN-METRIC-00

READ-ONLY on programmed unique obs bit. No synth, impl, XPR, program, RTL, oracle.

```text
BIT_SHA        = F24150BDE6F69080B3C5865386C49F6F02300782FFB4037FAF044BB2099840F7
PROGRAM_COUNT  = 1
PROGRAM        = NO
RTL_EDIT       = NO
BIT_BUILD      = NO
ORACLE_CHANGE  = NO
GATE14_PASS    = NO
```

Authority: `BlueprintV2/14_FINAL_ACCEPTANCE_CHECKLIST.md` SHA256
`826D9215FF0F3A17E4E1B18F353313546544C5F17BA5839BDD1E148F7E814FF7`
(text **not** edited this gate).

---

## P3_LANE_UTIL

```text
value           = INCONCLUSIVE on F24150BD
method          = Inventory CFRAME C0–C12 + UART_SLIM=1 print select on this SoC.
                  No lane_busy / lane_util / recs_per_cyc field on the programmed UART.
evidence_class  = INCONCLUSIVE          (this bit, required DUT)
artifact_sha    = BIT F24150BD…
                  exam_log 4E80F238CE2F7665C14ED99D33D360413794E388411D8C0121A6237FB0562E0F
                  cframe_sched 2B93E559E8D80636233043DD06FBE42BF96A26979BEC7BCFB1DAE3C54ED8E0C5
                  top 00613B8A6FD060004EC6BFAA060566A938562513E0BA8D0C53EE759FC9907135
box_tick        = OPEN
```

Related, **not this DUT**, do not promote:

| Number | Class | DUT | Artifact |
|--------|-------|-----|----------|
| recs/cyc **0.444444** (burst=4,out=8, N=64) | MIG_XSIM | `tb_a7ng_ddr_feed_mig` feeder | `MIG-METRIC-00/MIG_METRIC_ROW.md` `13D52730…` |
| stall_frac 0.555556 same cell | MIG_XSIM | same | same |
| lane_util ~2.8% (NON-GATE) | MIG_XSIM_WAVEFRONT | wavefront TB | `BOTTLENECK-RESOLUTION-REVIEW-00/FORMULA_TO_SIGNAL_MAP.md` |

PHYS=4 is a **synth generic** on this bit (`build_g14_final_obs_bit_00.tcl`), not utilization.
C9 graph scores K=8 via `a7ng_topk_stream_minheap` — occupancy of a result, not busy/available cycles.

---

## P4_DDR_STALL

```text
value           = INCONCLUSIVE on F24150BD
method          = C7 `busy` on HOLD_A is persist-path err/busy (`c7_fields`), not PE stall.
                  UART_SLIM=1 drops `w_stall` text probe (sel 51).
                  CFRAME has no pe_stall / stall_frac.
evidence_class  = INCONCLUSIVE          (this bit)
artifact_sha    = exam_HOLD_A busy=false  exam_log 4E80F238…
                  silicon_result 9E77091166A49F825CC07278F3E9923967FDA07E47A6935F5F81AA448CA5CEAA
                  UART_RAW FAC30E79FD9E1802C4A4505920A96724CA03CE3709B70FAA7E3A8772D5F486D2
box_tick        = OPEN
```

Historical feeder (NOT C9 exam on this bit):

```text
MIG_XSIM stall_frac (1,1) = 0.960445
MIG_XSIM stall_frac (4,8) = 0.555556
artifact_sha              = MIG_METRIC_ROW 13D52730CAC91EB43527FEB500C1CD04BF692E51EBF47EA72C0D786E91C3186D
                            GATE_mig_metric_00 BDFBAC9DD84DF413ACC790826C2BB92C44481353587D3C79A2EA929B869C5F00
```

Authority `00_CURRENT_AUTHORITY.md` correction 4: MIG-BOARD/feeder evidence does **not**
inherit onto a later SoC bit. Correction 3: never sell cumulative 2048/80 as per-run.

---

## M7_DDR_BYTES_PER_QUERY

```text
value           = INCONCLUSIVE on F24150BD C9 exam
method          = axi_read_bytes_o exists in ab_core and is CDC’d 19 bits to 100 MHz,
                  but is not in CFRAME and is not printed under UART_SLIM=1.
                  Boot FSM pulses start_q **once** after boot_done then QS_DONE (no per-exam SOA).
                  C9 exam is learned_prior_graph K=8 / 32-slot BRAM, not a 64-rec feeder query.
evidence_class  = INCONCLUSIVE          (this bit BOARD)
artifact_sha    = top 00613B8A…  (start_q / UART_SLIM)
                  CUE SOURCE_SHA 1721C298400EFEA7D705E507E5288ABC8BFDECB85BE0393D96DAFCC71E99A7D4
box_tick        = OPEN
```

Do **not** write `0 B/query` as BOARD. That would be an inference from the boot FSM, not a
counted `axi_read_bytes` delta around HOLD_A.

Historical feeder (NOT this exam):

```text
MIG_XSIM axi_read_bytes / 64 rec = 1024 B   →  16 B/record (NodeRecordV1)
cells (1,1) and (4,8) both 1024 B per-run after metric_clear
artifact_sha = MIG_METRIC_ROW 13D52730…
```

---

## M10_SCALE_800K

```text
bytes_per_query       = not_proven at 800k
candidates_per_query  = not_proven at 800k
                        Native V1 shipped path (NOT 800k): K=8
                          RTL  a7ng_learned_prior_graph topk_id_o [8] / minheap K=8
                          BOARD exam_HOLD_A C9 ids = 8382238122802120  (8 packed id bytes)
scaling_method        = none measured; no 800k ladder on this bit or this UART
status                = not_proven
evidence_class        = INCONCLUSIVE for 800k scale
                        BOARD for Native V1 K=8 pack only (M8 already PASS_NARROW)
box_tick              = OPEN
silent_NA             = REFUSED
checklist_amended     = NO
```

See `AUTHORITY_AMENDMENT_PROPOSAL.md`. Human must choose KEEP_OPEN vs AMEND_CHECKLIST.
This gate does not pick for them.

HS-13 remains: do not advertise 800k sparse retrieval without those two numbers at 800k.

---

## C5_CEILING_VS_THROUGHPUT

```text
physical_ceiling (POST_ROUTE this bit, F24150BD)
  PART           = xc7a100tcsg324-1
  PHYS           = 4                 (synth generic; concurrent lane *capacity*)
  K_candidates   = 8                 (RTL + BOARD C9 pack)
  RAMB36         = 104 / 135
  RAMB18         = 1
  DSP48E1        = 19 / 240
  Slice          = 15589 / 15850     (98.35%, free=261)
  LUT            = 35993 / 63400
  FF             = 44163 / 126800
  WNS            = +0.708 ns
  TNS            = 0
  BRAM working set = 32 slots (M4; not a throughput)

ideal_score_ceiling (ENGINEERING_ESTIMATE, II=1, NOT throughput)
  4 lanes × 100 MHz = 400e6 candidate-scores/s  if every lane scores every cycle
  Must not be quoted as system throughput (blueprint §11.6 / HS-09).

sustained_measured = NOT_MEASURED on F24150BD
  no time/query, no recs/cycle, no axi_read_bytes delta on UART CFRAME

bottleneck       = NOT_MEASURED
  Fit ceiling is slice (98.35%), not a measured DDR vs compute split.
  Do not convert RAMB36=104 or DSP=19 into recs/s.

evidence_class   = POST_ROUTE (ceilings) + INCONCLUSIVE (sustained)
artifact_sha     = e2r_metrics 4DBCC1D1CB59AFEB29F6C2B12ADE5E5A9C3FE5210F24FA3744CA111D3A7E58A5
                   util_route  89F77B9C1636686C4A0C4078251BB58374BFD3CBFE3B780A1560D9FF9257EF86
                   BIT         F24150BD…
box_tick         = PASS   (the checkbox is *report ceilings separately from sustained*;
                           sustained is reported as NOT_MEASURED, not invented)
```

---

## Box ticks this gate

| Box | Checklist text | Tick | Why |
|-----|----------------|------|-----|
| P3 | Lane utilization measured | **OPEN** | No util number on this UART |
| P4 | DDR stalls measured | **OPEN** | No PE stall on this UART; C7 busy ≠ stall |
| M7 | DDR bytes/query measured | **OPEN** | `axi_bytes` not BOARD-visible; no per-exam delta |
| M10 | 800k scale reports bytes/query and candidates/query | **OPEN** | 800k not run; refused silent N/A |
| C5 | on-chip ceilings reported separately from sustained E2E throughput | **PASS** | Ceilings archived; sustained explicitly NOT_MEASURED |

```text
OPEN_METRIC_BEFORE = 5
OPEN_METRIC_AFTER  = 4
UNSUPPORTED_CLAIMS = BOARD lane_util of F24150BD;
                     BOARD PE DDR stall of F24150BD C9 exam;
                     BOARD DDR bytes/query of F24150BD C9 exam;
                     800k-scale bytes/query;
                     800k-scale candidates/query;
                     800k runtime;
                     sustained E2E throughput from PHYS=4 / RAMB36 / DSP;
                     feeder recs/cyc 0.444444 as this SoC query rate;
                     16-lane 1.6 Gscore/s on this bit
PROGRAM            = NO
GATE14_PASS        = NO
NATIVE_V1_MINI_AI_BOARD_PASS = NO
```

## Fault tree (after this gate)

```text
LAW_GAPS       = 0     (no law opened)
XSIM_GAPS      = 0     (no XSim law gap opened)
BOARD_GAPS     = 0     (HS-02 named flags closed on F24150BD prior gate; not re-opened)
METRIC_GAPS    = 4     (P3 P4 M7 M10)
FAIL           = 0
```

56-checkbox final reconciliation is **DEFERRED**. User condition was METRIC_GAPS=0 first.
Do not tick `NATIVE_V1_MINI_AI_BOARD_PASS`. Do not build another bit for these four boxes
unless a later authority decision requires a counter bit (forbidden on F24150BD lane).

# A7-NATIVE-GRAPH â€” Resource Budget

**Device:** `xc7a100t` â€” 63,400 LUT / 126,800 FF / 135 BRAM / 240 DSP  
**Clock target:** 100 MHz for NG-01 scorer lane

## Frozen subsystem baselines (separate bitstreams â€” do not sum as one SoC)

| Subsystem | LUT | FF | BRAM | DSP | Source |
|-----------|----:|---:|-----:|----:|--------|
| A0.3 signed-h | 8,107 | 7,154 | 3 | 0 | `results/A7-EAM-03E/A03_SIGNED/a7eam03e_a03_utilization_route.rpt` |
| 01R | 1,252 | 1,322 | 56 | 0 | blueprint README / frozen lane |
| 02M | 1,704 | 2,332 | 52 | 0 | blueprint README / frozen lane |
| LM-06 | 37,555 | 35,864 | 132 | 154 | blueprint README / LM06-Q0 audit |
| **Naive sum** | **48,618** | **46,672** | **243** | **154** | BRAM = **180%** â†’ integration FAIL if unchanged |

## Integration implication (HS-11)

Naive glue of four frozen bits is **architecturally illegal** on BRAM. Budget levers (ordered):

1. DDR-back 01R/02M cold tables (primary BRAM save)  
2. LM06 low-bit / smaller staging buffer (secondary; see LM06-Q0)  
3. Graph PE uses LUT/FF + small BRAM hotset â€” must fit residual after (1)(2)

## NG-01 16-lane scorer budget (first target)

| Resource | Soft ceiling | Rationale |
|----------|-------------:|-----------|
| LUT | â‰¤ 8,000 | leave room for Top-K + frontier |
| FF | â‰¤ 10,000 | pipeline registers |
| BRAM | â‰¤ 8 | local query/candidate feature only â€” no DDR graph yet |
| DSP | 0 preferred | integer saturating adders first |
| Fmax | â‰¥ 100 MHz | WNS â‰¥ 0, TNS = 0 |
| Physical lanes | **16** | claim only after post-route instantiation count |
| Logical contexts | 0 in NG-01 | time-multiplex starts NG-06 |

## Theoretical compute ceiling (not end-to-end)

At 100 MHz, II=1 candidate/lane/cycle after fill:

```text
16 lanes â†’ 1.6e9 candidate-scores/s (compute ceiling)
```

DDR bandwidth will dominate after NG-03. Record candidates/query and DDR bytes/query.

## Parameter accounting (never mix)

```text
P_LM              = 802816
P_encoder         = 9216   (if both E and Wh trainable)
N_graph_nodes     = measured
N_edges           = measured
N_episodes        = measured
```

## RESET-00 logical path (measured XSim â€” not post-route)

| Metric | Value | Source |
|--------|------:|--------|
| cycles / QUERY_RESET | 5 | `results/A7-NATIVE-GRAPH/RESET-00/xsim_reset00.log` |
| cycles / TRAIN generation bump | 5 | same |
| WM DEPTH (authority bank) | 32 | `a7ng_wm_authority.sv` |
| Learned DEPTH (gen view) | 64 | `a7ng_learned_gen_view.sv` |
| Physical BRAM scrub this gate | 0 (not required) | logical invalidation only |
| LM-06 BRAM touched | 0 | frozen SHA MATCH |

Logical reset does **not** add a BRAM tile claim; HARD scrub + util remeasure deferred.

## Estimator

Editable tool from blueprint: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/tools/capacity_estimator.py`  
Assumptions JSON: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/configs/resource_assumptions.json`

## MEM_SCHEMA_V1 (DDR record strides â€” host/RTL/TB shared)

| Record | Bytes | Endian | Version | Source |
|--------|------:|--------|--------:|--------|
| NodeRecordV1 | 16 | LE | 1 | `rtl/native_graph/memory/a7ng_mem_schema_v1.sv` |
| EdgeRecordV1 | 32 | LE | 1 | same |
| EpisodeRecordV1 | 32 | LE | 1 | same |

Golden pytest: `tests/native_graph/test_mem_schema_v1.py`  
SV golden: `tests/xsim/run_a7ng_mem_schema_v1.tcl`  
Archive: `results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/`  
No BRAM tile delta from schema freeze alone (layout law, not new memories).

## A7-BRAM-WM-00 (no LM-06 â€” measured XSim; OOC util if archived)

| Metric | Value | Source |
|--------|------:|--------|
| Candidate depth | 256 | `a7ng_wm00_cand_buf.sv` |
| Frontier depth | 64 | `a7ng_wm00_frontier.sv` |
| Top evidence K | 8 | `a7ng_wm00_evidence.sv` |
| Learn update depth | 32 | `a7ng_wm00_learn_upd.sv` |
| Physical PE iface | 16 | `a7ng_wm00_pe_iface.sv` |
| FILL256 DROP | 0 | `BRAM-WM-00/xsim_wm00.log` |
| DDR rd bytes (FILL256) | 4096 (=256Ã—16) | same |
| DDR wr bytes (LEARN drain) | 512 | same |
| PE grants (16PE bag) | 16 | same |
| lm_grant | 0 | same |
| LM-06 / schema control | MATCH | `BRAM-WM-00/frozen_sha_control.txt` |
| Archive | `results/A7-NATIVE-GRAPH/BRAM-WM-00/` | â€” |

WM-00 prefers LUT/FF (distributed intent) over BRAM tiles so the working set does not compete with LM-06â€™s 132/135.

**Control (pre-pipeline OOC):** LUT=10238 FF=7359 BRAM=0 DSP=0; WNS@100MHz=âˆ’290.499 (FAIL). See parent `util_route.rpt` / `timing_route.rpt` and `timing/CONTROL_*`.

**wm00_timing (systolic Top-8 pipeline OOC):** LUT=2990 FF=7493 BRAM=0 DSP=0; WNS@100MHz=+0.069 TNS=0.000 (constraints met). Archive: `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/`. XSim lossless re-PASS. Not BOARD_PASS; not Â§45 ARCH_PASS; OOC WM-only.

## A7-BRAM-WM-01 / ddr_feed (ping-pong + burst + outstanding â€” XSim)

Synthetic LATENCY=24 (not MIG). N_PE=16 frozen. No 100 MHz timing claim.

| Metric | Value | Source |
|--------|------:|--------|
| Baseline stall_frac (burst=1,out=1) | 0.961544 | `DDR-FEED/xsim_ddr_feed.log` |
| Best stall_frac (burst=4,out=8) | 0.475410 | same |
| Baseline recs/cycle | 0.038456 | same |
| Best recs/cycle | 0.524590 | same |
| DROP (32 cells) | 0 | same |
| DDR rd bytes / cell | 4096 | same |
| Bank depth | 32Ã—2 ping-pong | `a7ng_ddr_feed_pp.sv` |
| WM-00 / schema / LM control | MATCH | `DDR-FEED/frozen_sha_control.txt` |
| Archive | `results/A7-NATIVE-GRAPH/DDR-FEED/` | â€” |

H_RIVAL OPEN: numbers are synthetic-latency, not board MIG GB/s.

## mig_h_rival (Digilent AXI MIG_XSIM â€” PASS_NARROW; H_RIVAL FALSIFIED)

Official Digilent `mig.prj` PortInterface=AXI; hand_edit=NO; SHA `870FA6EEâ€¦`. N_PE=16 frozen. TOTAL=64. No BOARD_PASS. No HS-02.  
xelab requires `-mt off -O0` on Vivado 2026.1.

| Metric | Value | Source |
|--------|------:|--------|
| mig.prj SHA | 870FA6EEâ€¦ MATCH | `MIG-RIVAL/mig_prj_sha256.txt` |
| xvlog MIG+feed | PASS | `MIG-RIVAL/xvlog_repair.log` |
| xelab MIG+feed (`-O0`) | PASS | `MIG-RIVAL/xelab_repair_O0.log` |
| MIG stall_frac (1,1) | 0.958710 | `MIG-RIVAL/MIG_SWEEP_ROW.md` |
| MIG stall_frac (4,8) | 0.549296 | same |
| MIG recs/cycle (1,1)/(4,8) | 0.041290 / 0.450704 | same |
| DROP | 0 | same |
| ddr_rd_bytes (1,1)/(4,8) | 1024 / 2048 | same (cumulative — see MIG-METRIC-00 for per-run) |
| Synthetic CONTROL stall | 0.961544â†’0.475410 | `DDR-FEED/` retained |
| Frozen LM-06/01R/02M/A0.3 | MATCH | `MIG-RIVAL/frozen_sha_control.txt` |
| Archive | `results/A7-NATIVE-GRAPH/MIG-RIVAL/` | â€” |

H_RIVAL FALSIFIED (synthetic no longer sole stall evidence). MIG_XSIM ≠ board silicon. Do not equate synthetic best 0.475410 with MIG 0.549296.

## mig_metric_00 (per-run AXI deltas + integrity — MIG_XSIM PASS)

Official Digilent `mig.prj` unchanged (SHA `870FA6EEâ€¦`). TOTAL=64. No COM12. No BOARD_PASS.

| Metric | Value | Source |
|--------|------:|--------|
| axi_read_bytes/bursts (1,1) delta | **1024 / 64** | `MIG-METRIC-00/MIG_METRIC_ROW.md` |
| axi_read_bytes/bursts (4,8) delta | **1024 / 16** | same |
| data/rresp/rlast / records | 0/0/0 / 64=64=64 | same |
| r_backpressure_cycles | 0 (not lost-data DROP) | same |
| CONTROL cumulative (4,8) | 2048 B / 80 bursts | `MIG-RIVAL/MIG_SWEEP_ROW.md` |
| Archive | `results/A7-NATIVE-GRAPH/MIG-METRIC-00/` | â€” |

## ddr_wavefront_00 (bounded cue working set → 16-wide wave — MIG_XSIM_WAVEFRONT PASS_NARROW)

**Gate:** `ddr_wavefront_00` · **BOARD_PASS:** false · **Evidence:** simulation-class only (no synthesis, no post-route util, no timing)

Official Digilent `mig.prj` unchanged (SHA `870FA6EE…`, AXI). `a7ng_ddr_feed_pp` + `a7ng_ddr_feed_axi_bridge` byte-identical to MIG-METRIC-00. UNIT = 1 query = 64 candidates; 4 traffic patterns.

| Metric | Value | Source |
|--------|------:|--------|
| DDR-delivery working set — declared bound | **3 KiB** (2 KiB cue banks 16×16×8 B + 1 KiB ping/pong 2×32×16 B) | `DDR-WAVEFRONT-00/CLOSEOUT.md` |
| Cue-bank peak occupancy — **measured** | **176 B** (22 of 256 entries, throttled P3) | `DDR-WAVEFRONT-00/RESULTS.md` |
| Cue-bank occupancy unthrottled | 128 B (16 entries) | same |
| RAMB18 cost if forced to BRAM | ≤ 2 tiles (18 Kib = 2.25 KiB/tile); ~0 as LUTRAM | derived from 3 KiB |
| Recommended size for LM06-WM-00 | 4 entries/bank = 64 entries = **512 B** compact | 4× margin on measured peak |
| `ddr_bytes_per_candidate` | **16.0000 B** (no cache → worst case) | `RESULTS.md` §2 |
| `ddr_bytes_per_query` / `beats_per_query` | 1024 B / 64 beats (all 4 patterns) | same |
| axi_read_bursts (1,1)/(4,8)/(16,8) | 64 / 16 / 4 — **exact CONTROL match** | vs `MIG-METRIC-00` |
| `jobs_per_emit_cycle` (16-wide proof) | **16.0000** (4/4 full waves, min width 16) | `RESULTS.md` §2 |
| `jobs_per_cycle_during_wave` (sustained) | 0.039776 / 0.441379 / 0.423841 / 0.444444 | same |
| `memory_wait_fraction` | 0.9975 / 0.9724 / 0.8146 / 0.9722 | same |
| `wavefront_fill_cycles` per wave | 401.25 / 35.25 / 30.75 / 35.00 | same |
| `candidate_conservation` / `data_mismatch` | **1 / 0** in 4/4 patterns | `RESULTS.md` §3 |
| `swap_count` (burst 1 / ≥4) | 64 / 2 | `RESULTS.md` §4 |
| `buffer_empty_stall` (burst 1 / ≥4) | 1544 / ~80 | same |
| `buffer_full_stall` / `bank_full_stall` | 0 / 0 — buffer never saturated (LIMIT L2) | same |
| lane utilisation (NON-GATE diagnostic) | 0.0025–0.0278 | `RESULTS.md` §5 |
| Archive | `results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/` | — |

**Budget reading:** candidate delivery is **not** what competes with LM-06's ~132 tiles — it is a
sub-2-tile (LUTRAM-class) cost. Sustained candidate rate stays DDR-bound at ~0.44/cycle, unchanged
from the one-per-cycle service; widening the wave did not buy throughput. DDR starvation is measured,
not solved. Do not choose burst/outstanding depth from these 3 cells — `mig_sweep_full` is still QUEUED.

## mig_board (Digilent AXI MIG silicon — PASS_NARROW)

**Gate:** `mig_board` · **Board:** Arty A7-100T `210319BE776EA` · **BOARD_PASS Native V1:** false · **HS-02:** false  

Official Digilent `mig.prj` PortInterface=AXI; hand_edit=NO; SHA `870FA6EE…`. WNS=+1.068. Integer UART counters only (no invent GB/s).

| Metric | Value | Source |
|--------|------:|--------|
| mig.prj SHA | 870FA6EE… MATCH | `MIG-BOARD/SHA256.txt` |
| Bit SHA | EF94BA6B…08B2EF1 | `MIG-BOARD/arty_a7_ng_mig_board.bit` |
| BOARD stall_frac (1,1) | 0.923261 | `MIG-BOARD/BOARD_MIG_SWEEP_ROW.md` |
| BOARD stall_frac (4,8) | 0.585366 | same |
| BOARD recs/cycle (1,1)/(4,8) | 0.076739 / 0.414634 | same |
| DROP | 0 | same |
| MIG_XSIM CONTROL (1,1)/(4,8) | 0.958710 / 0.549296 | `MIG-RIVAL/MIG_SWEEP_ROW.md` |
| WNS | +1.068 ns | `MIG-BOARD` vivado r3 |
| Frozen LM-06/01R/02M/A0.3 | MATCH | `MIG-BOARD/frozen_sha_verify.txt` |
| Archive | `results/A7-NATIVE-GRAPH/MIG-BOARD/` | — |

BOARD ≠ XSim equality. No Native V1 BOARD_PASS from this gate alone.

## MIG-BOARD-R2 (metric_clear 4×4 silicon grid — trusted per-run deltas)

**Gate:** `mig_board_r2` · **Evidence_class:** BOARD_MIG · **Bit:** `C08AE863…957CC` · WNS **+1.060 ns**

Supersedes quarantined `MIG-BOARD` cumulative rows. Full grid `BOARD_MIG_R2_SWEEP.md`.

| Metric | Value | Source |
|--------|------:|--------|
| BOARD stall_frac (1,1) | 0.960248 | `MIG-BOARD-R2/board_uart_capture.uart.txt` |
| BOARD stall_frac (4,8) | 0.555556 | same |
| axi_read_bytes (all 16 cells) | 1024 | per-run delta |
| axi_read_beats (all 16 cells) | 64 | per-run delta |
| Integrity data/rresp/rlast | 0 / 0 / 0 | all cells |
| CONTROL (1,1) bytes/bursts/beats | 1024 / 64 / 64 | matches MIG-METRIC-00 XSim |
| CONTROL (4,8) bytes/bursts/beats | 1024 / 16 / 64 | matches MIG-METRIC-00 XSim |
| Archive | `results/A7-NATIVE-GRAPH/MIG-BOARD-R2/` | — |

## bram_consolidate (WM phase-share wt+act — measured post-route proxy)

**Gate:** `bram_consolidate` Â· **Board:** Arty A7-100T Â· **BOARD_PASS:** false Â· **HS-22:** OPEN  

ONE lever: WM phase-share of weight **and** act banks into a TinyGPT-sized shared pool (132 tiles). Digilent `mig.prj` untouched (AXI MATCH). Not a full TinyGPT+UA answer-path SoC.

| Metric | Value | Source |
|--------|------:|--------|
| Consol BRAM tiles | **132 / 135** (97.78%) | `BRAM-CONSOL/consol_util.rpt` |
| WNS / TNS @100 MHz | **+0.586 / 0.000** | `BRAM-CONSOL/consol_timing.rpt` |
| WHS / THS | +0.069 / 0.000 | same |
| LUT / FF / DSP (proxy) | 153 / 23 / 0 | util |
| CONTROL UA BRAM / headroom | 128 / 7 | TinyGPT-SOC CONTROL |
| CONTROL TinyGPT LM-06 BRAM | 132 | frozen util |
| Additive (no consol) | **260 > 135** | HS-11 LIMIT retained |
| Co-fit projection (WM share) | **132 â‰¤ 135** | max(128,132); frees 128 double-count tiles |
| Prefer â‰¤130 soft | not met (132) | device hard â‰¤135 OK |
| Consol bit SHA256 | `83A438B5342446C9E79A537196777B1BCF2468FC57F9379EA2CB8EFE0A7D3AEF` | `BRAM-CONSOL/arty_a7_ng_bram_consol.bit` |
| Frozen UA / LM-06 / mig.prj | MATCH | `BRAM-CONSOL/frozen_sha_control.txt` |
| Verdict | **PASS_NARROW** | capacity co-fit; HS-22 OPEN |
| Archive | `results/A7-NATIVE-GRAPH/BRAM-CONSOL/` | â€” |

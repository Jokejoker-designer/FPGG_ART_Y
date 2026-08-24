# GATE: mig_metric_00

**Agent:** `a7-ng-memory-arch`  
**Evidence class:** **MIG_XSIM** (Digilent AXI MIG + ddr3_model) — **not BOARD**  
**Date:** 2026-08-22  
**Marker:** `A7NG_MIG_METRIC_XSIM_PASS`  
**Session override:** STOP after CLOSEOUT — no COM12; no `mig_board` dispatch

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Bridge telemetry reset only on rst_n; TB (1,1) then (4,8) without reset → cumulative 2048B/80; RVALID&&!RREADY was mislabeled DROP; NodeRecord/rresp/RID unchecked |
| UNKNOWN | can MIG_XSIM report trustworthy per-run deltas + integrity (bytes/bursts/beats + data/rresp/rlast/records) for N=64 without changing feed/search law? |
| H_CANDIDATE | XSim PASS: burst=1 → 1024B/64 bursts; burst=4 → 1024B/16 bursts (deltas); integrity clean |
| H_RIVAL | cumulative counters sold as per-cell; DROP as lost data |
| FALSIFIER | invent GB/s; COM12 program; change feed/search law; frozen overwrite |
| UNIT | sweep cell (burst × outstanding), TOTAL=64 |
| CONTROL | MIG-RIVAL cumulative (4,8)=2048B/80 documented; mig.prj MATCH PortInterface=AXI |
| METRICS | axi_read_{bytes,bursts,beats}; data/rresp/rlast; expected/received/consumed; rid; r_backpressure |

## Verdict

**PASS.** H_CANDIDATE **SUPPORTED**. H_RIVAL **FALSIFIED** for this unknown.

- Per-run `metric_clear_i` on cell start → second cell **1024 B / 16 bursts** (not cumulative 2048/80).
- Integrity: data_mismatch=0, rresp=0, rlast=0, records 64/64/64 both cells; pe_data_mismatch=0.
- `r_backpressure_cycles` reported; **not** called lost-data DROP.
- Digilent `mig.prj` **unchanged** (SHA `870FA6EE…`, PortInterface=AXI).
- AR-pipe accept refresh fixed so remain==burst does not queue one extra burst (measurement integrity; burst/outstanding/search law unchanged).
- **No COM12. No BOARD_PASS. No invented GB/s.**

## Headline

| Cell | axi_read_bytes | axi_read_bursts | axi_read_beats | integrity |
|------|---------------:|----------------:|---------------:|-----------|
| (1,1) | **1024** | **64** | **64** | CLEAN |
| (4,8) | **1024** | **16** | **64** | CLEAN |

## CHANGED

| Path | Role |
|------|------|
| `rtl/native_graph/memory/a7ng_ddr_feed_axi_bridge.sv` | per-run clear + integrity/diagnostic counters |
| `rtl/native_graph/memory/a7ng_ddr_feed_mig_top.sv` | wire metrics; PE NodeRecordV1.node_id check |
| `rtl/native_graph/memory/a7ng_ddr_feed_pp.sv` | AR-pipe post-accept recompute (no extra burst) |
| `tests/xsim/tb_a7ng_ddr_feed_mig.sv` | MIG-METRIC checks / marker |
| `tests/xsim/run_a7ng_ddr_feed_mig_metric.tcl` | archive under MIG-METRIC-00 |
| `results/A7-NATIVE-GRAPH/MIG-METRIC-00/**` | logs + CLOSEOUT |
| `docs/native_graph/RESOURCE_BUDGET.md` | measured delta rows |

**NOT changed:** mig.prj; 01R/02M/LM06/encoder/TermGen/Top-K/learning/HNSW/NTDE; no board program.

## TESTS

| ID | Result |
|----|--------|
| xvlog MIG+feed | PASS (`xvlog_mig_metric.log`) |
| xelab `-mt off -O0` | PASS (`xelab_mig_metric.log`) |
| xsim runall | PASS — `A7NG_MIG_METRIC_XSIM_PASS` |
| Cell (1,1)/(4,8) deltas + integrity | PASS |
| mig.prj hand-edit | PASS (no edit; SHA MATCH) |
| COM12 / BOARD_PASS | REFUSED |

## SHA256 (primary)

`D07A9742BD61E6D1DAC34F7017B6B817697A2C98CD4A825EFA54F77275F48454  a7ng_ddr_feed_axi_bridge.sv`  
`870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D  mig.prj`  
(full: `SHA256.txt`)

## NEXT

**STOP** — parent closeout only. Do **not** dispatch `mig_board`. No COM12.

# VERIFY_ONLY: mig_metric_00 (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** **PASS**  
**Marker:** `A7NG_MIG_METRIC_XSIM_PASS` — **PRESENT**  
**Evidence class:** **MIG_XSIM** (Digilent AXI MIG + ddr3_model) — **not BOARD**, **not HS-02**  
**Gate:** mig_metric_00  
**Verified_at_utc:** 2026-08-22T04:05:00Z  
**Implementer:** a7-ng-memory-arch / PASS / CLOSEOUT  
**Actions refused:** RTL edit; COM12 program; mig_board start

## Scientific frame (VERIFY)

| Slot | Value |
|------|-------|
| OBSERVATION | Archive claims per-run deltas (1,1)=1024B/64 (4,8)=1024B/16; integrity clean; marker PASS |
| UNKNOWN | Independent log parse: deltas + integrity + marker real vs cumulative spoof? |
| H_CANDIDATE | xsim_mig_metric.log confirms per-run deltas and integrity |
| H_RIVAL | sell run_console.txt FAIL or MIG-RIVAL cumulative 2048/80 as current PASS |
| FALSIFIER | Marker ABSENT; deltas ≠ expect; integrity nonzero; Evidence_class≠MIG_XSIM |
| UNIT | Gate archive (xsim log cells) — not clock cycle |
| CONTROL | run_console.txt prior FAIL; MIG-RIVAL cumulative (4,8)=2048/80 |
| METRICS | MIG_DELTA bytes/bursts/beats; MIG_INTEGRITY; CELL_PASS; marker |

## Checks

| Check | Result |
|-------|--------|
| xvlog_mig_metric.log ERROR/FATAL | **PASS** — none (MIG WARN only) |
| xelab_mig_metric.log `-mt off -O0` | **PASS** — snapshot `tb_a7ng_ddr_feed_mig_metric` built |
| xsim_mig_metric.log marker | **PASS** — `A7NG_MIG_METRIC_XSIM_PASS` L4238 |
| Cell burst=1 out=1 MIG_DELTA | **PASS** — bytes=**1024** bursts=**64** beats=**64** |
| Cell burst=4 out=8 MIG_DELTA | **PASS** — bytes=**1024** bursts=**16** beats=**64** |
| MIG_INTEGRITY both cells | **PASS** — data_mm=0 rresp=0 rlast=0 exp/rcv/cons=64/64/64 pe_mm=0 |
| MIG_DIAG rid_order / r_backpressure | **PASS** — rid_order_error=0; r_backpressure_cycles=0 (not DROP) |
| CELL_PASS both cells | **PASS** — deltas_ok integrity_ok |
| Evidence_class | **MIG_XSIM** — NOTE in log + GATE/CLOSEOUT |
| mig.prj | **MATCH** 870FA6EE… PortInterface=AXI hand_edit=NO |
| Prior run_console.txt FAIL | **CONTROL** — superseded; not authority |
| COM12 / mig_board / BOARD_PASS | **REFUSED** / not claimed |

## Headline (file-backed: `xsim_mig_metric.log`)

| Cell | axi_read_bytes | axi_read_bursts | axi_read_beats | integrity |
|------|---------------:|----------------:|---------------:|-----------|
| (1,1) | 1024 | 64 | 64 | CLEAN |
| (4,8) | 1024 | 16 | 64 | CLEAN |

## Note (MINOR observational)

`PE_MISMATCH_DBG` lines appear mid-cell (L4098, L4232) but official `pe_data_mismatch=0` and `CELL_PASS` — not sold as integrity fail. Authority = MIG_INTEGRITY + CELL_PASS + marker.

## Artifacts

- `results/A7-NATIVE-GRAPH/MIG-METRIC-00/xsim_mig_metric.log` (authority)
- `results/A7-NATIVE-GRAPH/MIG-METRIC-00/xvlog_mig_metric.log`
- `results/A7-NATIVE-GRAPH/MIG-METRIC-00/xelab_mig_metric.log`
- `results/A7-NATIVE-GRAPH/MIG-METRIC-00/MIG_METRIC_ROW.md`
- `results/A7-NATIVE-GRAPH/MIG-METRIC-00/GATE_mig_metric_00.md`
- `results/A7-NATIVE-GRAPH/MIG-METRIC-00/CLOSEOUT.md`
- `results/A7-NATIVE-GRAPH/MIG-METRIC-00/run_console2.txt` (corroborates PASS)
- `results/A7-NATIVE-GRAPH/MIG-METRIC-00/run_console.txt` (prior FAIL CONTROL)

## Verdict

**PASS.** H_CANDIDATE supported. H_RIVAL (cumulative-as-per-cell / stale FAIL log) falsified for this verify. No RTL change. No COM12. No mig_board. No BOARD_PASS.

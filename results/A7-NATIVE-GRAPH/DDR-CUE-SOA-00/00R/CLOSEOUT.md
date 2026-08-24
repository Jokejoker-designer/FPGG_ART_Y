# CLOSEOUT — ddr_cue_soa_00r_axi_liveness (ATTEMPT 7)

**Result:** **FAIL**  
**Evidence_class:** `MIG_XSIM` only (§14 — no board)  
**Agent:** `a7-ng-memory-arch`  
**Marker:** `A7NG_DDR_CUE_SOA_XSIM_PASS` — **not observed**  
**Log:** `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/xsim_ddr_cue_soa.log`  
**Failure class:** `B_RREADY_DEADLOCK` + **phantom PRIOR-first** (unchanged signature)

## ONE UNKNOWN (unchanged)

> Can the frozen 104b lawful candidate descriptor be delivered using exactly **832 DDR bytes / 64-candidate query**?

**Not answered.** Transport/liveness FAIL only — **SOA not falsified.**

## Scientific frame (attempt 7)

| Field | Value |
|-------|-------|
| OBSERVATION | Unit **5/5 PASS**; MIG first post-preload query read still PRIOR bank1 col `018` before ID bank0 |
| H_CANDIDATE | Clone `a7ng_cue_wavefront` AR/R into `a7ng_soa_plane_engine`; bypass `axi_read_stream` layering; TB `owner_ready` + AR order monitor |
| H_RIVAL | Orchestrator-only patches fix MIG — **FALSIFIED** (attempts 5–7) |
| FALSIFIER | No PASS marker; first query DDR read ≠ ID bank0 before PRIOR `0x03000030` |
| CONTROL | Frozen 104b descriptor; bridge 4-deep distributed R FIFO (UG953-equivalent, no new XPM instance) |
| METRICS | 832 B / 52 beats / 4 AR / top1 id=57 score=165 |

## Attempt 7 RTL/TB changes (transport only)

| File | Change |
|------|--------|
| `a7ng_soa_plane_engine.sv` | **NEW** — byte-addressed AR/R engine cloned from `a7ng_cue_wavefront` (pending credit `r_ready`, tail_drain, `issued<target` guard) |
| `a7ng_soa_plane_fetch.sv` | Thin wrapper → `plane_engine` (unit path preserved) |
| `a7ng_cue_soa_wavefront.sv` | Direct `plane_engine` inst (drops `axi_read_stream` from MIG path); `ar_plane_ok` retained |
| `a7ng_cue_soa_mig_top.sv` | Export `owner_ready_o` for TB handoff |
| `a7ng_ddr_soa_axi_bridge.sv` | Unchanged (4-entry distributed R FIFO retained) |
| `tb_a7ng_ddr_cue_soa.sv` | Wait `owner_ready` after `feed_en`; first-4 `m_axi_araddr` order check; `SOA_AR_MON` |
| `run_a7ng_ddr_cue_soa.tcl` | Add `plane_engine.sv`; snapshot **v11** |

**Not applied (optional per §3.2):** Xilinx FIFO Generator / XPM_FIFO_ASYNC (existing hand-rolled depth-4 FIFO kept); AXI register slice at MIG boundary.

## Tests

| Test | Result |
|------|--------|
| Unit `run_a7ng_axi_read_stream.tcl` | **5/5 PASS** (`A7NG_AXI_READ_STREAM_UNIT_PASS`) |
| MIG `run_a7ng_ddr_cue_soa.tcl` v11 | **FAIL** — hang past 900 ms sim; marker absent; process killed |

## MIG probe (first query after preload)

| Time (ps) | DDR | Observation |
|-----------|-----|-------------|
| 126085966 | Read bank1 col `018` | **First query-class read = PRIOR** (wrong order) |
| 126097966 | duplicate Read col `018` | `B_RREADY_DEADLOCK` retry pair |
| 126457966 | Read bank0 row `2000` col `000` | ID-plane reads **372 µs later** |

`SOA_OWNER_READY ok cycles=0` — owner idle at `feed_en` assert (expected post-reset).

## SHA256 (attempt 7 RTL/TB)

| File | SHA256 |
|------|--------|
| `a7ng_soa_plane_engine.sv` | `52568EC41969D1BE59AE037B8FE1689E36CAF2FEEDF2218FF25B8BA82B088765` |
| `a7ng_soa_plane_fetch.sv` | `795202E3B04EF28DBBB4D3A35B9E9530688A524315AEB7BE829FD8540F7F036A` |
| `a7ng_cue_soa_wavefront.sv` | `4A3AD64EB8C7F3363485F4FCD8A06D54A7C2372BA87FA1C8E24668915BC5327C` |
| `a7ng_cue_soa_mig_top.sv` | `3AB07751A5B13531B6943D4E7E67EB93A061AC8B66874306BAC41B17C63937E1` |
| `tb_a7ng_ddr_cue_soa.sv` | `0C5DEE138718B2B4794E7AAB17065EB7BF73AB9813E32B93896E3000FF047136` |

## STOP

Per gate §15: attempt 7 closed. SOA descriptor law not falsified. **Next:** isolate why `plane_engine` + `ar_plane_ok` still issues PRIOR-class traffic before ID on MIG (wavefront FSM phase / stale `pf_base` / bridge `r_drain_hold` interaction).

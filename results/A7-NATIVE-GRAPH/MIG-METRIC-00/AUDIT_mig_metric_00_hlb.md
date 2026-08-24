# AUDIT — mig_metric_00 (HLB)

**Gate:** `mig_metric_00`  
**Agent:** `a7-hlb-auditor`  
**Mode:** `VERIFY_ONLY`  
**Evidence_class:** `MIG_XSIM` — **not BOARD**  
**COM12 / program:** **REFUSED** (this audit did not program; archive claims no COM12)  
**Result:** **HLB PASS**  
**BOARD_PASS:** **not declared**

```text
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=STOP (session override after mig_metric_00).
MUST_READ_UNBLOCK_H5: read (encoder lane parked; not this gate).
```

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | MIG-METRIC archive: per-run deltas (1,1)=1024B/64, (4,8)=1024B/16; integrity clean; marker `A7NG_MIG_METRIC_XSIM_PASS` |
| UNKNOWN | does metric repair introduce host gradient/winner/address/answer on EVAL, change feed/search law, or overwrite frozen 01R/02M/LM06/encoder/TermGen/Top-K/learning/HNSW/NTDE? |
| H_CANDIDATE | HLB CLEAN: telemetry/integrity + AR-pipe stale-refresh only; no EVAL host answer path; frozen MATCH |
| H_RIVAL | host computes FPGA-credited deltas; law knobs changed; frozen overwrite |
| FALSIFIER | host→board cue/addr/winner/grad/answer; burst/outstanding/N_PE/Top-K law change; frozen SHA mismatch; COM12 program as evidence |
| CONTROL | MIG-RIVAL cumulative (4,8)=2048/80; mig.prj SHA `870FA6EE…` PortInterface=AXI |
| UNIT | sweep cell (burst × outstanding), TOTAL=64 |
| Verdict on UNKNOWN | **CLOSED — HLB PASS / CLEAN** |

## HLB: CLEAN

Single question: if host code for this gate were deleted, would the claim still be true?

**Yes.** Claim is MIG_XSIM measurement integrity from RTL + TB + Digilent MIG model. No host Python EVAL path. Telemetry counters and integrity checks live in `a7ng_ddr_feed_axi_bridge.sv` / `mig_top`; TB only preloads NodeRecords, drives burst/outstanding, and reads counters (METRIC-EVAL-ONLY).

No CRITICAL/MAJOR HLB violations.

## Violations

**None (HLB CLEAN).**

## EVAL path

| Check | Result |
|-------|--------|
| Host EVAL / teacher-off run | **ABSENT** (this gate) |
| `teacher=0` / `external_LLM=0` / `learn=0` / `freeze=1` | **N/A** — no EVAL claim |
| Host gradient / weight delta | **ABSENT** |
| Host winner / way / cue / next-token | **ABSENT** |
| Host prompt→answer map | **ABSENT** |
| Host chooses BRAM/DDR record address for FPGA credit | **ABSENT** — AR addr issued by `ddr_feed_pp`; TB preload is fixture SUPERVISION |

## Feed / search law

| Knob | Status |
|------|--------|
| `burst_i` / `outstanding_i` | Unchanged API; TB still sweeps (1,1) and (4,8) |
| `N_PE=16` | Frozen in `a7ng_ddr_feed_mig_top.sv` |
| Top-K / TermGen / learning / HNSW / NTDE | **Not in CHANGED set**; TermGen lane + Top-K SHA **MATCH** TERMGEN/NG-02R-TOPK archives |
| AR-pipe post-accept recompute | Measurement integrity bugfix (no extra burst at remain==burst) — **not** a change of allowed burst/outstanding/search law |

## Frozen overwrite

| Artifact | Expected SHA256 | Live | Verdict |
|----------|-----------------|------|---------|
| `build/out/arty_a7_lm06.bit` | `67C37DD5…4282E3BA` | MATCH | OK |
| `build/out/arty_a7_eam01r.bit` | `57D1DF1B…0E9EF6CF` | MATCH | OK |
| `build/out/arty_a7_eam02m.bit` | `DB3BC58A…84CFE696` | MATCH | OK |
| `arty_a7_eam03e_a03.bit` (A0.3) | `05E478FF…142BEC09` | MATCH | OK |
| `vivado/.../mig.prj` | `870FA6EE…88152190D` | MATCH; `<PortInterface>AXI</PortInterface>`; hand_edit=NO | OK |
| `a7ng_termgen_lane.sv` | TERMGEN archive | `DD637EDA…` MATCH | OK |
| `a7ng_topk.sv` | NG-02R-TOPK archive | `F671FCB1…` MATCH | OK |

Encoder / HNSW / NTDE: not modified by this gate's CHANGED list; no overwrite evidence.

## Host→DUT surface (TB / XSim only)

| Field / action | Classification |
|----------------|----------------|
| NodeRecord DDR preload (`axi_write_beat` addr+data) | SUPERVISION (fixture) |
| `burst_i`, `outstanding_i`, `total_recs`, `start` | MODE / sweep params |
| `pe_req` all-1s | MODE |
| Read `axi_read_*`, integrity, stall counters | TELEMETRY-READ / METRIC-EVAL-ONLY |
| TB PE `node_id` scoreboard vs expect | METRIC-EVAL-ONLY (not host answer) |
| Cue / winner / gradient / weight / next-token payload | **ABSENT** |

## Parameter accounting (separate; never summed)

| Symbol | Value | Note |
|--------|-------|------|
| `P_LM` | 802816 | LM backbone params — **not** this gate |
| `P_encoder` | 9216 | Encoder — **not** this gate |
| `P_total_trainable` | (LM+encoder only if co-trained; **not summed with episodes**) | N/A here |
| `N_episodes` | n/a | Episodes ≠ parameters |
| `episode_storage` | n/a | |
| `index_storage` | n/a | |

No archive text in MIG-METRIC-00 adds episodes into parameter counts.

## Limits (honest)

- Evidence_class remains **MIG_XSIM**, not BOARD / Native V1.
- No invent GB/s; no BOARD_PASS.
- Session STOP: do not auto-dispatch `mig_board` from this HLB PASS alone.

## Files reviewed

- `results/A7-NATIVE-GRAPH/MIG-METRIC-00/{CLOSEOUT,GATE,PREREGISTER,MIG_METRIC_ROW,SHA256,xsim_mig_metric.log}`
- `rtl/native_graph/memory/a7ng_ddr_feed_{axi_bridge,mig_top,pp}.sv`
- `tests/xsim/tb_a7ng_ddr_feed_mig.sv`
- Frozen bits + mig.prj + TermGen/Top-K SHA cross-check

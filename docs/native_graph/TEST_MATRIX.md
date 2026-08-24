# A7-NATIVE-GRAPH — Test Matrix

## NG-00 — Contracts & teacher boundary

| ID | Test | Command / method | PASS |
|----|------|------------------|------|
| NG00-T1 | lesson schema validates | `pytest tests/native_graph/test_ng00_anti_leak.py -q` | valid TRAIN packet accepted |
| NG00-T2 | forbidden fields rejected | same | gradient/ΔW/winner/address/hash/next_token/final_answer rejected |
| NG00-T3 | BLIND_EXAM rejects attention hints | same | entity/intent/ranking rejected |
| NG00-T4 | telemetry schema validates | same | required fields present |
| NG00-T5 | train≠eval entity split rule documented | doc audit | no shared exam strings in TRAIN corpus |

## NG-01 — 16-lane scorer

| ID | Test | PASS |
|----|------|------|
| NG01-X1 | XSim deterministic score bag | exact integers |
| NG01-X2 | 16 lane instances in hierarchy | `get_cells` count = 16 |
| NG01-T1 | post-route WNS ≥ 0, TNS = 0 @ 100 MHz | Vivado MCP report |
| NG01-U1 | LUT/FF/BRAM/DSP archived | under `results/A7-NATIVE-GRAPH/NG-01/` |
| NG01-H1 | DSP = 0 unless contract amended | measured |

## NG-02 — Top-K / frontier

| ID | Test | PASS |
|----|------|------|
| NG02-X1 | deterministic tie (lower node id) | XSim |
| NG02-X2 | no dropped candidate under fill | XSim |
| NG02-X3 | overflow behavior bounded | documented + XSim |

## NG-03 — DDR shard + BRAM hotset

| ID | Test | PASS |
|----|------|------|
| NG03-B1 | no full-graph scan | candidates/query logged |
| NG03-B2 | DDR bytes/query measured | telemetry |
| NG03-B3 | cache hit ratio measured | telemetry |

## NG-06 — Multi-agent share / wide dispatch

| ID | Test | Command / method | PASS |
|----|------|------------------|------|
| NG06-X1 | 16 phys / 256 log; RR; isolated fail | `tests/xsim/run_a7ng06_share.tcl` | `A7NG06_SHARE_XSIM_PASS` |
| NG06R-W1 | Ladder 1→4→8→16-way; measure util via `lane_grant_o` | `tests/xsim/run_a7ng06_wide.tcl` | `A7NG06R_WIDE_XSIM_PASS` |
| NG06R-W2 | N_WAY=16 avg lane util ≥80% over ≥100k cyc (BAG_ALWAYS_READY control) | same | util16≥80; starve=0 |
| NG06R-W2b | BAG_SPARSE_READY (Bernoulli p=0.5 seed) + BAG_BURSTY_READY | same | starve=0; max_jpc ladder; jobs_acc>0 |
| NG06R-W3 | Telemetry present | same / RTL ports | lane_busy, jobs_per_cycle, idle/conflict, occ/full, starvation_count |
| NG06R-E1 | query_epoch/path_epoch on queue+grant; DROP_STALE when entry≠active | `tests/xsim/run_a7ng06_epoch.tcl` | `A7NG06R_EPOCH_XSIM_PASS` |
| NG06R-E2 | Mixed-epoch share bags ≥100k cyc ×≥3 seeds; DROP_STALE>0; alive=256; priors intact | same | no HS-07 wipe |
| NG06R-E3 | Prune fire_epoch≠active → DROP_STALE; node_alive=1; path not permanently banned | same + `run_a7ng04_prune.tcl` | HS-06 contextual |

## PERFMON — instrumentation only (feedback §21 / PLAN B2)

| ID | Test | Command / method | PASS |
|----|------|------------------|------|
| PM-X1 | PERFMON-lite counters increment under known share+frontier+topk traffic | `tests/xsim/run_a7ng_perfmon.tcl` | `A7NG_PERFMON_XSIM_PASS` |
| PM-X2 | Dump includes §21 subset: lane_busy, jobs, queue_occ, starve, stale_drop, scheduler idle/conflict | same | non-zero where traffic requires; dump logged |
| PM-C1 | Share law untouched (control SHA) | `Get-FileHash` vs NG-06R-EPOCH | `a7ng_multi_agent_share.sv` = `4413C74B…` |
| PM-C2 | No search/learn law_id change; observer only | RTL review | no dispatch/grant semantics edit |

## RESET-00 — logical QUERY / TRAIN (A7-NATIVE-RESET-00)

| ID | Test | Command / method | PASS |
|----|------|------------------|------|
| RST-01 | QUERY_RESET: auth_valid=0, workset=0, physical remnant>0, learned survives, LM intact | `tests/xsim/run_a7ng_reset00.tcl` | `A7NG_RESET00_XSIM_PASS` |
| RST-03 | TRAIN bump: learned_visible=0, old_phys>0 (no scrub), new gen writable, LM intact | same | old gen not authoritative |
| RST-HARD | HARD level rejected this gate (no fake scrub PASS) | same | `reset_error` sticky |
| RST-C1 | Frozen LM-06/01R/02M/A0.3 SHA unchanged | `RESET-00/frozen_sha_control.txt` | MATCH |

## BRAM-WM-00 — working memory without LM-06 (spec §33)

| ID | Test | Command / method | PASS |
|----|------|------------------|------|
| WM00-X1 | 256 cand fill DROP=0; mem_schema NodeRecordV1 | `tests/xsim/run_a7ng_wm00.tcl` | `A7NG_BRAM_WM00_XSIM_PASS` |
| WM00-X2 | Overflow DROP counted (not silent); frontier 64 | same | DROP>0 only on overfill |
| WM00-X3 | Exact Top-8; learn coalesce+DDR writeback | same | nodes 31..24; wr bytes>0 |
| WM00-X4 | 16 PE grants; lm_grant=0; dual-owner err | same | grants=16; dual sticky |
| WM00-C1 | Frozen LM-06/01R/02M/A0.3 + schema SHA | `BRAM-WM-00/frozen_sha_control.txt` | MATCH |

## DDR-FEED / A7-BRAM-WM-01 — ping-pong burst×outstanding (spec §34)

| ID | Test | Command / method | PASS |
|----|------|------------------|------|
| DF-X1 | Sweep burst{1,4,8,16}×out{1,2,4,8}×seed{0,1}; DROP=0 | `tests/xsim/run_a7ng_ddr_feed.tcl` | `A7NG_DDR_FEED_XSIM_PASS` |
| DF-X2 | PE stall_frac reduced vs baseline (1,1) | same | 0.961544→0.475410 |
| DF-X3 | Effective recs/cycle improves | same | 0.038→0.525 |
| DF-C1 | WM-00 + schema + frozen LM SHA unchanged | `DDR-FEED/frozen_sha_control.txt` | MATCH |

## TERMGEN — full candidate feature generation (feedback R3 / P1)

| ID | Test | Command / method | PASS |
|----|------|------------------|------|
| TG-P1 | Python oracle 32-vector bag; all 4 families present | `python tests/xsim/termgen_oracle.py` | `TERMGEN_PY_PASS` |
| TG-X1 | XSim exact bag vs golden (Hamming+bind+intent/context+path) | `tests/xsim/run_a7ng_termgen.tcl` | `A7NG_TERMGEN_XSIM_PASS` |
| TG-X2 | 16 `keep_hierarchy` TermGen lanes | OOC synth hierarchy | 16/16 |
| TG-C1 | Top-8 / frontier bucket control SHA unchanged | `TERMGEN/SHA256.txt` | MATCH |
| TG-U1 | DSP=0 preferred (OOC cell usage) | `TERMGEN/ooc_util.rpt` | DSP=0 |

## TRAIN-V2 (harness PASS; board exam still open)

See `docs/contracts/native_graph/A7-NATIVE-GRAPH-TRAIN-V2.md`. Same 20/40 facts vs frozen control. Two from-zero mappings. Blind: query only.  
Evidence: `results/A7-NATIVE-GRAPH/TRAIN-V2/` + `pytest tests/native_graph/test_train_v2.py`. Marker `A7NG_TRAIN_V2_HARNESS_PASS`.

| ID | Test | PASS |
|----|------|------|
| V2-C1 | old model files/SHA still present | no delete |
| V2-C2 | learned graph/confidence/edges cleared; RTL bit not wiped | dump vs control |
| V2-S20 | 20-fact teacher-off | preregistered bag |
| V2-S40 | 40-fact teacher-off | after S20 |
| V2-AB | Run A then RESET then Run B | B ≠ A; A forgotten |
| V2-BLIND | no entity/intent/winner/address/answer from host | schema reject |

## Evidence classes

Every closeout must label claims:

```text
EVIDENCE | ENGINEERING_INFERENCE | NEEDS_EXPERIMENT | FALSE_OR_OVERCLAIM
```

Template: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/templates/EXPERIMENT_CLOSEOUT_TEMPLATE.md`

# 10 — Validation and Evidence Plan

## 1. Evidence labels

Every result is one of:

```text
BOARD
POST_ROUTE
OOC
MIG_XSIM
XSIM
TWIN
DERIVED
ENGINEERING_ESTIMATE
HISTORICAL_ESTIMATE
```

Sub-classes used by the A7-NATIVE-GRAPH archives: `BOARD_MIG`, `POST_ROUTE_SOC`,
`POST_ROUTE_PROXY`, `POST_ROUTE_FIT_LIMIT`, `OOC_POST_ROUTE`, `BOARD_UART_STUB`,
`BOARD_UART_LM_PATH_PROBE`, `BOARD_UART_SEMANTIC_LIMIT`, `HARNESS`, `CHECKLIST_MAP`, `DOC`,
`ABSENT` / `LIMIT`.

Never merge them:

```text
XSIM != BOARD
MIG_XSIM != BOARD_MIG
POST_ROUTE != FUNCTIONAL_INTEGRATION
HARNESS != HS-02
```

## 1b. Evidence lineage — board evidence is scoped to its RTL revision

**Board evidence belongs to the bitstream and RTL revision it was captured on. A later RTL revision
does not inherit it.**

Worked example from this project. `MIG-METRIC-00` changed DDR feeder RTL **after** the `mig_board`
bitstream (`EF94BA6B…08B2EF1`) was captured. Therefore:

| artifact | belongs to | evidence class |
|---|---|---|
| `mig_board` stall rows (1,1) 0.923261 / (4,8) 0.585366, WNS +1.068 | the archived `mig_board` bit / RTL revision | `BOARD_MIG` |
| `MIG-METRIC-00` per-run deltas 1024 B / 64 bursts and 1024 B / 16 bursts | the **revised** feeder RTL | `MIG_XSIM` |

Never imply "the revised feeder is BOARD_PASS". That requires a new bitstream, a new SHA and a new
silicon run. Scoping the old board evidence does not weaken it — it remains valid for its own
revision.

Separately, the `mig_board` rows are **quarantined for measurement**: they were captured with
pre-repair cumulative counters, and the old `DROP` counter measured `RVALID && !RREADY`, which is
**R-channel backpressure**, not data loss. Conservation authority is record/data equality
(`expected = received = consumed`).
Source: `results/A7-NATIVE-GRAPH/STATUS/QUARANTINE_MIG_BOARD_PREMETRIC.md`.

## 1c. Measurement integrity precedes optimization

A cumulative counter read as a per-run delta makes every downstream decision unfalsifiable. The
`2048 bytes / 80 bursts` reading was **CUMULATIVE CONTROL — NOT A PER-RUN METRIC**, and the per-run
interpretation of it is **FALSIFIED**
(`results/A7-NATIVE-GRAPH/MIG-METRIC-00/MIG_METRIC_ROW.md`).

Fix measurement integrity before optimizing against a metric.

## 1d. DDR-WAVEFRONT-00 — `MIG_XSIM_WAVEFRONT`, not BOARD

After metric integrity, wavefront characterization closed as **DONE_ENG PASS_NARROW**
(`Evidence_class=MIG_XSIM_WAVEFRONT`, marker `A7NG_DDR_WAVEFRONT_XSIM_PASS`).
Canonical: `results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_ddr_wavefront_00.md`.

It does **not** inherit `mig_board` BOARD class. It does **not** prove 16-PE DDR feed on silicon.
Throughput was **not** improved vs 1-wide service (0.441 vs 0.444 cand/cycle). `lane_util ≥ 80%` is
not this gate's hard criterion.

## 2. Arithmetic proof

Existing A0.3 5,000/5,000 exact trace is strong evidence for that PAIR RTL/twin arithmetic path only.

New graph/triplet/low-bit laws require their own RTL/XSim/board proof.

## 3. Teacher curriculum split

Use at least:

```text
development lessons
development evaluation
frozen confirmation set
blind final exam
```

## 4. Query classes

Test:

- exact wording;
- paraphrase;
- reordered syntax;
- same entity/new intent;
- unrelated query;
- contradiction;
- multi-topic query;
- distractor-heavy query.

## 5. Graph metrics

Per query:

```text
anchor accuracy
candidate count
path count
prune count
bomb count
top-K evidence precision
relation accuracy
retrieval hit/miss
false hit
coverage
DDR bytes
latency
```

## 6. Learning metrics

```text
edge/node updates
weight rail count
confidence distribution
forgotten facts
new-fact acquisition
teacher-off retention
reset/retrain
```

## 7. Parallel engine metrics

```text
physical lane utilization
logical contexts active
frontier occupancy
queue overflow
stall cycles
DDR stall cycles
BRAM cache hit
updates merged
write conflicts
```

## 8. Final answer metrics

Separate:

```text
retrieval correctness
LM composition correctness
```

If retrieval is right but LM says it wrong, the graph did not fail.

## 9. Blind exam rule

No teacher relevance score, entity label, intent label or answer key reaches FPGA in final exam.

## 10. Board gates

For each promoted RTL milestone:

```text
XSim exact
post-route WNS >= 0
TNS = 0
bit SHA frozen
board functional test
```

## 11. Provenance

Archive:

```text
RTL/twin/tool SHA
exact command
seed set
corpus SHA
teacher model ID/version
teacher prompt template version
lesson log
metrics
bit SHA
utilization report
timing report
PASS/FAIL
corrections
```

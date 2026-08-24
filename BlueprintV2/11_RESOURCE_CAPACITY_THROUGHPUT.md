# 11 — Resource Capacity and Theoretical Throughput

> **Evidence labelling is mandatory in this file.** Every number carries exactly one of:
>
> ```text
> BOARD | POST_ROUTE | OOC | MIG_XSIM | XSIM | ENGINEERING_ESTIMATE | HISTORICAL_ESTIMATE
> ```
>
> A number without a label is not usable. Current status table:
> [`00_CURRENT_AUTHORITY.md`](00_CURRENT_AUTHORITY.md) §20.

## 1. Device resources

`xc7a100t` project values:

```text
63,400 LUT
126,800 FF
135 BRAM tiles
240 DSP
```

## 2. Current four-block routed sum — `POST_ROUTE`

```text
LUT  = 48,618  (76.7%)
FF   = 46,672  (36.8%)
BRAM = 243      (180.0%)  FAIL
DSP  = 154      (64.2%)
```

**NAIVE STACKING = FALSIFIED**, not an open estimate. Two later SoC compositions reproduce the same
architectural FAIL:

| composition | BRAM | evidence class | artifact |
|---|---:|---|---|
| UA SoC 128 + frozen LM-06 132 | 260 / 135 | `POST_ROUTE_FIT_LIMIT` | `results/A7-NATIVE-GRAPH/TINYGPT-SOC/LIMIT_tinygpt_bram_fit.md` |
| consol 132 + TinyGPT-class LM-06 132 | 264 / 135 | `FIT_LIMIT` | `results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/LIMIT_tinygpt_consol.md` |

A measured capacity co-fit exists — shared pool = max(128, 132) = 132 tiles, WNS +0.586, TNS 0 —
but its own audit classes it `POST_ROUTE_PROXY` with the soft ≤130 objective not met and HS-22 open
(`results/A7-NATIVE-GRAPH/BRAM-CONSOL/METRICS.json`).

## 3. Maximum number of full Native AI model copies — `POST_ROUTE` (derived)

A single current LM-06 alone uses:

```text
59.2% LUT
97.8% BRAM
64.2% DSP
```

Two current LM-06 copies would require approximately:

```text
75,110 LUT  > 63,400
264 BRAM    > 135
308 DSP     > 240
```

Therefore:

> **Maximum current full LM-06-based Native AI instances on one Arty A7-100T = 1.**

This does not limit the number of internal logical search agents.

## 4. Physical agent lanes — MEASURED

PE lanes have been routed. The statement "no PE has been routed yet" is **stale and removed**.

### 4.1 Measured routed scorer cost

| context | lanes | scorer LUT | scorer FF | BRAM | DSP | WNS | evidence class | artifact |
|---------|------:|-----------:|----------:|-----:|----:|----:|----------------|----------|
| NG-01 standalone 16-lane scorer top | 16 | 618 | 411 | 0 | 0 | +2.400 ns | `POST_ROUTE` | `results/A7-NATIVE-GRAPH/NG-01/closeout.md` |
| Integrate SoC, `u_sc` = `a7ng_scorer_array` | 16 | 1,046 | 1,856 | 0 | 0 | SoC +0.952 ns | `POST_ROUTE_SOC` | `results/A7-NATIVE-GRAPH/INTEGRATE/fit_soc_util_hier.rpt` line 80 |
| LM06-SOC cut, `u_sc` | 16 | 1,048 | — | — | 0 | +0.365 ns | `POST_ROUTE_SOC` | `results/A7-NATIVE-GRAPH/LM06-SOC/FIT_BUDGET_LM06_SOC.json` |
| LM06-UA cut, `u_sc` | 16 | 1,047 | — | — | 0 | +0.257 ns | `POST_ROUTE_SOC` | `results/A7-NATIVE-GRAPH/LM06-UA/FIT_BUDGET_LM06_UA.json` |

Per-lane arithmetic from the SoC rows: 1,046 LUT / 16 lanes ≈ **65 LUT per routed lane**
(`POST_ROUTE_SOC`, derived). The NG-01 standalone top is lower still.

Whole-SoC context for the integrate bit: LUT 5,695, FF 5,903, BRAM 0, DSP 0, WNS +0.952, TNS 0,
PE lanes measured = 16 (`POST_ROUTE_SOC`,
`results/A7-NATIVE-GRAPH/INTEGRATE/FIT_BUDGET_SOC.json`).

### 4.2 HISTORICAL PLANNING ESTIMATE — superseded, retained for provenance only

The following are `HISTORICAL_ESTIMATE` values from the pre-implementation package. They are **not**
current physical cost and must never be cited as such:

```text
lean lane:      ~180 LUT      HISTORICAL_ESTIMATE
standard lane:  ~260 LUT      HISTORICAL_ESTIMATE
rich lane:      ~400 LUT      HISTORICAL_ESTIMATE
```

The derived lane-count tables built on them (`48,618 + 2,000 + 16×260` etc., and the same arithmetic
in `RESOURCE_ESTIMATE_SNAPSHOT.txt`) are likewise `HISTORICAL_ESTIMATE`. Measured lane cost is about
4× cheaper than the "standard lane" assumption, so those tables understate lane headroom — but LUT
headroom is not the binding constraint. **BRAM is.**

### 4.3 What still limits lane count

Lane arithmetic is cheap; delivery is not. Adding lanes without measured DDR delivery multiplies
idle hardware. Scale physical lanes only from post-route evidence **and** measured feed capability
(see §7 and `00_CURRENT_AUTHORITY.md` §9).

## 5. Logical agent count

A logical agent is only a context record, not a physical PE.

At 16 bytes/context:

```text
32 KiB  → 2,048 agents
64 KiB  → 4,096 agents
72 KiB  → 4,608 agents
128 KiB → 8,192 agents
144 KiB → 9,216 agents
```

If cold logical contexts are stored in DDR:

```text
16 MiB → 1,048,576 contexts
64 MiB → 4,194,304 contexts
```

Only the contexts scheduled onto physical lanes are computing simultaneously.

## 6. Core compute ceiling at 100 MHz — `ENGINEERING_ESTIMATE`

Assume one scored candidate per lane per cycle after pipeline fill:

```text
16 lanes → 1.6 billion candidate-scores/s
32 lanes → 3.2 billion candidate-scores/s
64 lanes → 6.4 billion candidate-scores/s
```

**Claim hygiene (mandatory).**

```text
on-chip candidate-score ceiling  !=  sustained end-to-end graph throughput
```

`16 × 100 MHz = 1.6 G` is a **local ideal compute ceiling under II = 1 assumptions**. It must never
be reported as system throughput. Real system reporting must account for DDR delivery, candidate
production (TermGen), bank conflicts, queue occupancy, frontier behaviour, Top-K and LM phase
sharing.

If lane initiation interval is 2 cycles, divide by 2.

## 7. DDR ceiling and measured DDR facts

### 7.1 Link-level arithmetic — `ENGINEERING_ESTIMATE`

Arty A7 DDR3 link is ~16-bit @ 667 MT/s ≈ **1.33 GB/s theoretical raw**. Theoretical link bandwidth
is not measured graph throughput.

Sixteen fresh 16-byte NodeRecords per cycle at 100 MHz would demand 25.6 GB/s — roughly 19× the
theoretical raw link. **16 physical lanes therefore do not imply DDR can feed 16 fresh records per
cycle.**

### 7.2 Older mixed-throughput figure — `HISTORICAL_ESTIMATE`

An earlier project measurement of roughly 1.159 GB/s mixed throughput was used as the planning input
for the candidate ceilings below. Treat all four numbers as `HISTORICAL_ESTIMATE`:

```text
1.159 GB/s assumed
16 bytes/candidate → ~72.4 million candidates/s
32 bytes/candidate → ~36.2 million candidates/s
64 bytes/candidate → ~18.1 million candidates/s
```

These predate the current MIG feeder and its measurement-integrity repair. Do not cite them as
current DDR capability.

### 7.3 Current measured DDR facts — integers only, no GB/s

Per-run AXI deltas at N = 64 (`MIG_XSIM`,
`results/A7-NATIVE-GRAPH/MIG-METRIC-00/MIG_METRIC_ROW.md`):

| burst | outstanding | read bytes | bursts | beats | data mismatch | exp/rcv/cons |
|------:|------------:|-----------:|-------:|------:|--------------:|-------------:|
| 1 | 1 | 1024 | 64 | 64 | 0 | 64/64/64 |
| 4 | 8 | 1024 | 16 | 64 | 0 | 64/64/64 |

Silicon stall fractions (`BOARD_MIG`, `results/A7-NATIVE-GRAPH/MIG-BOARD/GATE_mig_board.md`):
(1,1) = 0.923261, (4,8) = 0.585366, WNS +1.068 ns. **These rows are quarantined** — they were
captured with pre-repair cumulative counters and belong to their own archived bit/RTL revision. Do
not derive GB/s from them, and do not treat the revised feeder as inheriting board evidence
(`results/A7-NATIVE-GRAPH/STATUS/QUARANTINE_MIG_BOARD_PREMETRIC.md`).

The older `2048 bytes / 80 bursts` reading is **CUMULATIVE CONTROL — NOT A PER-RUN METRIC**; the
per-run interpretation of it is **FALSIFIED**. `RVALID && !RREADY` is **R-channel backpressure**,
not data drop.

### 7.4 Reading

A naive DDR-per-candidate engine is **memory-bound**, not PE-bound. DDR **capacity** is not the
primary problem; DDR **delivery and locality** is.

## 8. Why BRAM hotsets matter

If a topic shard is loaded once into BRAM and reused many times, the PE swarm can operate much closer to the 100 MHz compute ceiling.

The architecture should therefore maximize:

```text
DDR burst locality
BRAM reuse
compact candidate records
adjacency fetch only after prune gate
```

## 9. Graph-search latency examples — `HISTORICAL_ESTIMATE`

Pure-transfer lower bounds at the historical 1.159 GB/s assumption (see §7.2 — not a current
measurement):

```text
4,096 candidates × 16 B ≈ 65.5 KiB
→ ~56 microseconds of ideal DDR transfer

65,536 candidates × 16 B ≈ 1 MiB
→ ~0.90 ms ideal DDR transfer
```

Actual latency is higher because of arbitration, adjacency reads, random access and LM sharing.

## 10. 800k episode storage

```text
32 B/episode → 25.6 MB
64 B/episode → 51.2 MB
96 B/episode → 76.8 MB
```

DDR capacity is likely adequate; index efficiency and bandwidth are the key risks.

## 11. Training throughput — `HISTORICAL_ESTIMATE` (harness, not core)

Training traffic has a different shape from inference and must never be estimated from read-only
bandwidth:

```text
INFERENCE  DDR read -> tile -> compute
TRAINING   DDR read weights -> tile -> compute/update -> dirty tile -> coalesced DDR writeback
```

Dirty tracking, coalesced writeback and burst writeback are future work — planning, not PASS
evidence.

The existing board UART harness demonstrated about:

```text
5,000 transactions / 240 s ≈ 20.8 transactions/s
```

This is **host↔UART end-to-end harness throughput**, not FPGA core training throughput.

The new architecture should amortize teacher traffic:

```text
one lesson packet
→ many on-FPGA agent expansions/updates
→ compact telemetry response
```

so UART is not in the inner learning loop.

## 12. Practical capacity recommendation

For Native V1 planning:

```text
1 full Native AI system
16 physical graph/search lanes initially
256–4,096 active logical agents initially
thousands to millions of cold logical contexts possible in DDR if ever useful
```

Scale physical lanes only from routed evidence. Scale logical agents only if frontier statistics show that more contexts improve retrieval.

## 13. Final bottleneck prediction — partially confirmed

Original predicted order:

```text
1. BRAM architecture
2. DDR bandwidth/locality
3. LUT routing/timing at high PE counts
4. LM token generation latency
```

Current standing, with evidence class:

| rank | bottleneck | standing |
|-----:|------------|----------|
| 1 | BRAM working-set architecture | **CONFIRMED.** Naive stacking FALSIFIED at 243 / 260 / 264 vs 135 (`POST_ROUTE`, `POST_ROUTE_FIT_LIMIT`, `FIT_LIMIT`). |
| 2 | DDR delivery and locality | **CONFIRMED as the active research front** (`ddr_wavefront_00`; read `LOOP_STATE.json` for its live status). Capacity is not the issue; delivery is. |
| 3 | LUT routing/timing at high PE counts | **DOWNGRADED.** Measured lane cost ≈ 65 LUT (`POST_ROUTE_SOC`), far below the historical 260 LUT assumption. LUT is not currently binding. |
| 4 | LM token generation latency | **NOT REACHED.** The LM-06 answer path is a LIMIT (TinyGPT/DSP core absent), so latency has not been measurable. |

Raw arithmetic capability remains the least constrained resource.

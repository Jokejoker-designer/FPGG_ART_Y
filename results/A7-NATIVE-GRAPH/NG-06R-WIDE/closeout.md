# NG-06R-WIDE closeout (REPAIR / VALID)

**Gate:** `ng06_wide_dispatch`  
**Branch:** `NG-06R-WIDE`  
**Agent:** `a7-ng-scientific`  
**Marker:** `NG06R_WIDE_ENGINEERING_PASS`  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**

Human audit 2026-08-22 00:37 invalidated prior closeout (implementation incomplete). This file replaces it.

## Unknown closed (HS-25)

Replace 1-job/cycle dispatch with parameterized **N_WAY** multi-grant so 16 physical lanes are fed.  
ONE timing unknown after nested allocator hung synth / failed 100 MHz: **compact exact allocator**  
(`ready_lane_mask→compact N_WAY`, `nonempty_bank_mask→compact N_WAY`, pair `lane[k]↔bank[k]`),  
then **2-stage pipeline** on the OOC timing vehicle to close WNS≥0 @ 100 MHz.  
No PE count reduction. Law id **`a7ng-share-v1`** unchanged.

## STEP 0 — TB repair (FACT)

- Removed runtime-sized packed-array stubs (`logic [WAY-1:0]` with task-arg WAY).  
- Preferred harness: `a7ng_wide_rung` + `tb_a7ng_wide_dispatch_top` / per-way tops.  
- **Separate XSim** per N_WAY (and ready-sparsity bags).  
- Free-running ungated clock only (`always #5 clk = ~clk`).  
- Metrics authority = registered `lane_grant_o` (not `pop_valid_o`).

## STEP 1 — XSim ladder (FACT — EVIDENCE)

Horizon ≥100 000 cycles / rung; SERVICE=1; hotset-local continuous feed; **no DDR**.

| Bag | N_WAY | util % | jobs/cyc | max_jpc | starve | Gate |
|-----|------:|-------:|---------:|--------:|-------:|------|
| ALWAYS_READY | 1 | 6.25 | 1.0000 | 1 | 0 | max≤1 |
| ALWAYS_READY | 4 | 25.00 | 4.0000 | 4 | 0 | max≥2 |
| ALWAYS_READY | 8 | 50.00 | 8.0000 | 8 | 0 | max≥4 |
| ALWAYS_READY | **16** | **100.00** | **16.0000** | **16** | **0** | max≥8, util≥80% |
| SPARSE_READY | 1..16 | (see logs) | — | pass | 0 | sparsity bags |
| BURSTY_READY | 1..16 | (see logs) | — | pass | 0 | duty windows |

Dev gates on saturated ALWAYS_READY @ N_WAY=16: **PASS**.  
HS-09: 16 **physical** lanes; logical contexts are time-multiplexed — not claimed as physical cores.

```text
A7NG06R_WIDE_LADDER_PASS
NG06R_WIDE_ENGINEERING_PASS
```

Logs: `results/A7-NATIVE-GRAPH/NG-06R-WIDE/xsim_*_way*.log`, `run_wide_final.log`.

## STEP 2 — Wide interface authority (FACT)

In `rtl/native_graph/share/a7ng_multi_agent_share.sv`:

| Port | Role |
|------|------|
| `lane_grant_o`, `grant_*_o[]`, `jobs_per_cycle_o` | **AUTHORITATIVE** wide dispatch |
| `pop_valid_o` / `pop_log_o` / `pop_score_o` / `pop_node_o` | **DEBUG / COMPATIBILITY ONLY** — first grant/cycle |

No downstream may infer total wide width from `pop_valid_o`. Law `a7ng-share-v1` kept.

## STEP 3 — Post-route (FACT — EVIDENCE, not BOARD_PASS)

Full multi-port share queues hang Vivado Cross-Boundary opt (10k+ mux cloud).  
OOC timing vehicle = **`a7ng_wide_alloc_ooc`** (same compact pair-k semantics; 2-stage pipeline)  
in `a7ng_wide_dispatch_ooc_top.sv` @ 100 MHz on `xc7a100tcsg324-1`.

| Metric | Value |
|--------|------:|
| Slice LUTs | 1359 |
| Slice Registers | 175 |
| LUT as Memory | 0 |
| Block RAM Tile | 0 |
| DSPs | 0 |
| **WNS** | **+0.215 ns** |
| **TNS** | **0.0 ns** |

```text
NG06R_WIDE_POSTROUTE_PASS WNS=0.215 TNS=0.0
```

Reports: `util_post_route.rpt`, `timing_post_route.rpt`, `post_route_summary.txt`, `vivado_ooc_pipe.log`.

## Claim labels

| Claim | Class |
|-------|--------|
| Ladder 1→4→8→16 XSim, util16≥80%, starve=0 | **EVIDENCE** |
| Compact pair-k allocator + OOC WNS≥0 @ 100 MHz | **EVIDENCE** |
| 16 physical lanes (not 256 cores) | **EVIDENCE** / HS-09 |
| BOARD_PASS / silicon / bitstream program | **NOT claimed** |
| Epochs / TermGen / BRAM-WM / integrate_fit | **NOT this gate** (HOLD) |

## Explicit non-claims

- Not BOARD_PASS  
- Did not add PEs  
- Did not start epochs / TermGen / BRAM-WM / reset / integrate_fit  
- Did not overwrite frozen 01R / 02M / LM-06 / A0.3 bits  
- Full share deep-queue OOC synth remains tool-limited; allocator timing vehicle is the post-route evidence for this repair

## SHA256

See `SHA256.txt`. Primary share RTL:

```text
4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6  rtl/native_graph/share/a7ng_multi_agent_share.sv
5FF281D279A51D79706555A3A0E25367E1D8206C5DE893593F87EC91F4D5B00E  rtl/native_graph/share/a7ng_wide_dispatch_ooc_top.sv
F969FF73D5A07E1B92A3CF85913D5D936A7EF8C24A1FEE16D816BAB66667B762  tests/xsim/tb_a7ng_wide_dispatch.sv
```

## Marker

```text
NG06R_WIDE_ENGINEERING_PASS
```

## NEXT

**STOP** per `HOLD_NG06_WIDE_ONLY.md`. Do not auto-dispatch epochs/TermGen/BRAM-WM/reset/integrate_fit.

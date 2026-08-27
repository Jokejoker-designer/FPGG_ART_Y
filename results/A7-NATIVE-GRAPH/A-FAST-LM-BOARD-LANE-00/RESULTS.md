# RESULTS — A-FAST-LM-BOARD-LANE-00

## Command

```powershell
$env:Path = "C:\2026.1\Vivado\bin;C:\2026.1\Vivado\bin\unwrapped\win64.o;" + $env:Path
cd D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board\tests\xsim
vivado -mode batch -notrace -source run_a7ng_native_v1_ab_fast.tcl
```

## Outcome

**PASS** — `A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664` (exit 0)

## Evidence (2026-08-24)

| Check | Result |
|-------|--------|
| SOA bytes/beats/bursts | **PASS** 832 / 52 / 4 |
| SOA planes / delivered / waves | **PASS** 16/32/4 / 64 / 4 |
| `SOA_DATA_MISMATCH` | **PASS** 0 |
| Global Top-8 | **PASS** `9,11,25,27,41,43,57,59` @ score 165 |
| CAPTURE pack | **PASS** `3b392b291b190b09` |
| `pred` | **PASS** 664 |
| `dual_ticks` / `mem_we_exam` | **PASS** 0 / 0 |
| `start_fwd_beats` | **PASS** 1 |

## Fixes applied (one unknown each)

1. **AXI mux undeclared nets** — `tb_a7ng_native_v1_ab_fast.sv` AR mux outputs declared (prior session).
2. **rec0 wave-bank ID lag** — `a7ng_cue_soa_wavefront.sv`: split `rec0`/`rec1` 128b distributed RAM into per-field registers (`r0_nid/cue/prior`, `r1_*`). Root cause: XSim distributed-RAM pack left `rec0[k].id = pi-1` while cue/prior correct (Codex `BOARD_LANE_SCORE_DATA_DIAG_CODEX.md`).
3. **LM bind timeout** — TB bind wait 5M→200M cycles, wall 50ms→2500ms (HS22-aligned; TinyGPT forward ~18M cycles).

## Marker

```text
A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664
```

## Artifacts

- `tests/xsim/xsim.log`
- `rtl/native_graph/memory/a7ng_cue_soa_wavefront.sv`
- `tests/xsim/tb_a7ng_native_v1_ab_fast.sv`

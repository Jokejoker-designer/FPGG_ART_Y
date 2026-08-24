# GATE: lm06_soc_path — PASS_NARROW — 2026-08-22

```text
GATE: lm06_soc_path
UNKNOWN: lm06_weight_fabric_on_soc_response_path
TESTS: vivado/tcl/native_graph/measure_lm06_soc_path.tcl (post-route)
EXPECTED: LM-06 weight modules present; WNS>=0; TNS=0; BRAM<=135; lm_path wire from weight evidence; frozen LM-06 SHA MATCH
ACTUAL: BRAM=64 WNS=+0.365 TNS=0 WHS=+0.015 THS=0; wt BRAM=64 (u_lm06_wtile=32 + u_lm06_wpp=32); PE u_sc LUT=1048 FF=1856 lanes=16; SHA=D61BA6D4…
PASS/FAIL: PASS_NARROW
ARTIFACT: results/A7-NATIVE-GRAPH/LM06-SOC/GATE_lm06_soc_path.md
SHA256: D61BA6D454F4AC1B4980D3869866A6742E12C02C9D08C2ECD45897CCD9053FA3
```

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | SoC D65F3524… had lm_path=0 / LM-06 weights ABSENT |
| UNKNOWN | can integrated design include LM-06 weight fabric with WNS≥0 TNS=0 BRAM≤device and lm_path≠0 path? |
| H_CANDIDATE | new SoC archive with real weight modules; frozen LM-06 SHA MATCH |
| H_RIVAL | fake lm_path=1; host answers; overwrite frozen LM-06 |
| FALSIFIER | frozen SHA change; BOARD_PASS; HS-02 semantic without retrieval |
| CONTROL | SoC D65F3524…; frozen LM-06/01R/02M/A0.3 |
| UNIT | one post-route SoC composition |

## Measured (post-route)

| Metric | Value | Provenance | Gate |
|--------|------:|------------|------|
| WNS / TNS | +0.365 / 0.000 | `lm06_soc_timing.rpt` Design Timing Summary | **PASS** |
| WHS / THS | +0.015 / 0.000 | same | **PASS** |
| LUT / FF / DSP | 7202 / 8060 / 0 | `lm06_soc_util.rpt` | **PASS** (DSP=0 this cut) |
| Block RAM Tile | 64 / 135 | util | **PASS** (≤135; ≤prefer 130) |
| Weight fabric | PRESENT | hier `u_lm06_wtile` RAMB36=32 + `u_lm06_wpp` RAMB36=32 | **PASS** |
| PE lanes | 16 fabric | hier `u_sc` LUT=1048 FF=1856; 16×`g_lane` | **PASS** |
| MIG | present | hier `u_mig` LUT=4313 | **PASS** |
| lm_path RTL | sticky from weight BRAM readback (not hardwired 1) | `arty_a7_ng_lm06_soc_top.sv` | **PASS_NARROW** (not board-probed this run) |
| New SoC bit SHA | D61BA6D4…053FA3 | live SHA256 | ≠ CONTROL SoC |
| CONTROL SoC | D65F3524…A4DF | INTEGRATE retained MATCH | **PASS** |
| Frozen LM-06 | 67C37DD5…E3BA MATCH | `frozen_sha.txt` | **PASS** (HS-20) |
| Frozen 01R/02M/A0.3 | MATCH | same | **PASS** |

## LIMIT (honest)

1. **Weight cut only:** `weight_tile803k` + `tile_weight_pingpong` (64 BRAM). Full frozen LM-06 act `u_a` (~64) + GPT core + DSP **ABSENT** this cut.
2. **lm_path:** RTL sticky from weight readback wired to UART bit5 — **not** re-probed on COM12 this gate (teacher_off still had lm_path=0 on ABSENT vehicle).
3. **Not** semantic HS-02 / retrieval answers / BOARD_PASS.
4. New bit **does not** replace frozen `arty_a7_lm06.bit` (HS-20).

## H_RIVAL checks

| Rival | Outcome |
|-------|---------|
| Fake lm_path=1 with BRAM=0 | **Did not fire** — 64 weight BRAM post-route |
| Overwrite frozen LM-06 | **Did not fire** — SHA MATCH |
| Host answers claimed | **Did not fire** — no BOARD_PASS / no exam claim |

## Explicit non-claims

- Not `NATIVE_V1_MINI_AI_BOARD_PASS`
- Not full LM-06 law bitstream glued into SoC
- Not silicon teacher-off retrieval / HS-02 semantic
- Not WM-00 timing bankable

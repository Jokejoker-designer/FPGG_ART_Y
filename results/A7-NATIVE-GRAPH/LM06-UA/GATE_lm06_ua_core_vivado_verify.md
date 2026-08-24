# VERIFY_ONLY: lm06_ua_core (a7-vivado-gate)

```text
GATE: lm06_ua_core
MODE: VERIFY_ONLY (no re-impl; re-derive from archived post-route)
AGENT: a7-vivado-gate
DATE: 2026-08-22
BOARD: Arty A7-100T xc7a100tcsg324-1
EVIDENCE_CLASS: POST_ROUTE_SOC
BOARD_PASS: false
```

## Re-derived numbers (provenance = post-route reports on disk)

| Metric | Value | Source | Gate |
|--------|------:|--------|------|
| BRAM tiles | **128** / 135 | `lm06_ua_util.rpt` Block RAM Tile | **PASS** (≤135) |
| RAMB36 / RAMB18 | 128 / 0 | same | OK |
| WNS | **0.257** ns | `lm06_ua_timing.rpt` Design Timing Summary L141 | **PASS** (≥0) |
| TNS | **0.000** ns | same | **PASS** (=0) |
| WHS | **0.024** ns | same | hold OK |
| THS | **0.000** ns | same | hold OK |
| LUT / FF / DSP | 7209 / 8075 / **0** | `lm06_ua_util.rpt` | DSP=0 **PASS** |
| Weight fabric | **PRESENT** | hier `u_lm06_wtile` RAMB36=32 + `u_lm06_wpp` RAMB36=32 (=64) | **PASS** |
| Act `u_a` | **PRESENT** | timing paths `u_a/mem_reg_*` → RAMB36E1; BRAM 128−64wt = **64** implied | **PASS** |
| TinyGPT / mac_array / gemv / DSP core | **ABSENT** | hier no TinyGPT/mac/gemv; DSP=0; RTL comments + LIMIT | **LIMIT** |
| PE lanes fabric | **16** | hier `u_sc` × `g_lane[0..15].u_lane`; LUT=1047 FF=1856 | **PASS** |
| New SoC bit SHA256 | `D2C6CF4B28706B24CE513E2B7A09A4018EB9BB01EBB864FA3A5375B11DB9A92C` | live `Get-FileHash` | **MATCH** archive |
| CONTROL weight-cut SHA | `D61BA6D454F4AC1B4980D3869866A6742E12C02C9D08C2ECD45897CCD9053FA3` | live hash LM06-SOC | **RETAINED MATCH**; NEW≠CTRL |
| Frozen LM06/01R/02M/A0.3 | MATCH | live hash `build/out/*.bit` vs expect | **PASS** |
| BOARD_PASS | false | — | not declared |

## Explicit checks

1. **Post-route WNS/TNS:** Design Timing Summary `0.257 / 0.000`; all user constraints met — PASS  
2. **BRAM128 = wt64 + ua64:** util Block RAM Tile=128; hier wt 32+32=64; remainder + named `u_a` timing sinks — PASS  
3. **`u_a` PRESENT:** RTL `act_ram128k16 u_a`; post-route timing destinations under `u_a/mem_reg_*` — PASS  
4. **TinyGPT ABSENT LIMIT:** DSP=0; no TinyGPT/mac_array/gemv in hier util; LIMIT doc retained — LIMIT (not FAIL)  
5. **Frozen MATCH:** LM06/01R/02M/A0.3 + CONTROL weight-cut live SHA MATCH; NEW UA ≠ CONTROL — PASS (HS-20)  
6. **No BOARD_PASS / no silicon program this verify**

## Verdict

**PASS_NARROW** — post-route SoC+weight+act `u_a` numeric gates (BRAM128 / WNS+0.257 / TNS0 / DSP0 / PE16 / `u_a` PRESENT / TinyGPT ABSENT LIMIT / frozen MATCH) re-confirmed; **no BOARD_PASS**.

Artifact: `results/A7-NATIVE-GRAPH/LM06-UA/GATE_lm06_ua_core_vivado_verify.md`  
Implementer gate: `GATE_lm06_ua_core.md` / `FIT_BUDGET_LM06_UA.json` / `LIMIT_ua_core.md`  
Frozen verify: `frozen_sha_verify.txt`

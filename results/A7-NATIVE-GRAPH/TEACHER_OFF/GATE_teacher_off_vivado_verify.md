# GATE teacher_off_exam — a7-vivado-gate VERIFY_ONLY

**Gate:** `teacher_off_exam`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY` (no synth / no re-program)  
**Result:** **PASS_NARROW**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** BIT_SHA + FROZEN_CONTROL + LIMIT (post-route SoC util for LM-06 ABSENT)

## Scope

Confirm programmed-claim SoC bit `D65F3524…` vs disk SHA; frozen LM-06/01R/02M/A0.3 MATCH; LM-06 weight fabric ABSENT LIMIT stands. Does **not** re-score UART framing (HLB owns that) and does **not** declare BOARD_PASS.

## TESTS (measured this session)

| Test | Provenance | Verdict |
|------|------------|---------|
| SoC bit live SHA == claim `D65F3524…A4DF` | `Get-FileHash` `arty_a7_ng_integrate_fit_soc.bit` | **PASS** (MATCH) |
| SoC ≠ proxy CONTROL | live SoC vs `D2FC41A7…23CA3` | **PASS** (`SOC_NE_PROXY=True`) |
| Proxy CONTROL retained | live hash own_cut bit | **PASS** (MATCH) |
| Frozen LM-06 / 01R / 02M / A0.3 | live `build/out/*.bit` vs expect | **PASS** (MATCH) |
| LM-06 weight fabric ABSENT | post-route `fit_soc_util.rpt` BRAM Tile=**0**; DSP=**0** | **LIMIT stands** |
| New bit under `TEACHER_OFF/` | recursive `*.bit` count | **0** (OK) |
| Synth / impl / JTAG this verify | — | **N/A** (VERIFY_ONLY; no re-program) |

SHA dump: `results/A7-NATIVE-GRAPH/TEACHER_OFF/vivado_verify_sha.txt`

## Programmed claim vs disk

| Item | Value | Verdict |
|------|-------|---------|
| Claimed programmed path | `results/A7-NATIVE-GRAPH/INTEGRATE/arty_a7_ng_integrate_fit_soc.bit` | path exists |
| Claimed SHA (`board_probe.json` / HLB) | `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF` | — |
| Disk SHA (this verify) | `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF` | **MATCH** |
| Bytes | 3826008 | — |
| FIT_SOC_SHA256.txt | same digest | **MATCH** |

## Frozen bit integrity (live)

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| Proxy CONTROL | `INTEGRATE/arty_a7_ng_integrate_fit_own_cut.bit` | `D2FC41A7869E7C4FF9B2E852C0E6E3A328E8C87EE518ACC03091BD29A3D23CA3` | MATCH |

**frozen_bits:** **MATCH**

## LM-06 weights ABSENT LIMIT

| Check | Value | Source | Verdict |
|-------|------:|--------|---------|
| Block RAM Tile | **0** / 135 | `INTEGRATE/fit_soc_util.rpt` | ABSENT on SoC vehicle |
| DSPs | **0** | same | PASS (DSP gate) |
| LIMIT doc | retained | `TEACHER_OFF/LIMIT_lm06_absent.md` | stands |
| Semantic retrieval / HS-22 | not claimed | vivado-gate | LIMIT not closed |

Frozen LM-06 bit is **untouched** (MATCH above). Weight fabric absence on the SoC vehicle is a **LIMIT**, not a golden edit.

## Explicit non-claims

- Not BOARD_PASS / not Native V1  
- Not re-run of UART blind exam (HLB archive owns framing)  
- Not re-impl / not new bitstream  
- Not LM-06 weight fabric present / not HS-22 closed  
- Not upgrade PASS_NARROW stub framing to full semantic HS-02  

## Verdict

**PASS_NARROW** — programmed-claim SoC SHA `D65F3524…` **MATCH** disk; frozen LM/01R/02M/A0.3 **MATCH**; proxy CONTROL retained and ≠ SoC; LM-06 weight fabric **ABSENT LIMIT** stands (BRAM=0). **No BOARD_PASS.**

Artifact: `results/A7-NATIVE-GRAPH/TEACHER_OFF/GATE_teacher_off_vivado_verify.md`

# GATE train_v2 — a7-vivado-gate VERIFY_ONLY

**Gate:** `train_v2`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** HARNESS (frozen-bit integrity only) — not post-route / not silicon  

## TESTS (measured this session)

| Test | Provenance | Verdict |
|------|------------|---------|
| Frozen LM-06 / 01R / 02M / A0.3 SHA == expect | live `Get-FileHash` SHA256 | **PASS** (MATCH) |
| A0.3 signed archive == build/out A0.3 | live SHA256 | **PASS** (MATCH) |
| integrate_fit proxy bit untouched | live vs expect `D2FC41A7…23CA3` | **PASS** (MATCH) |
| Control dump file SHA vs `SHA256.txt` | live vs `6539605C…` | **PASS** |
| Control dump canonical JSON SHA | live vs `9E746E3F…` | **PASS** |
| New bitstream under `TRAIN-V2/` | recursive `*.bit` count = **0** | **PASS** (HARNESS-only OK) |
| Synth / impl / WNS / TNS / JTAG | — | **N/A** (no new bit; SILICON_DEFERRED) |

SHA dump: `results/A7-NATIVE-GRAPH/TRAIN-V2/vivado_verify_sha_frozen.txt`

## Frozen bit integrity (live)

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| A0.3 signed | `results/A7-EAM-03E/A03_SIGNED/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| integrate_fit proxy | `results/A7-NATIVE-GRAPH/INTEGRATE/arty_a7_ng_integrate_fit_own_cut.bit` | `D2FC41A7869E7C4FF9B2E852C0E6E3A328E8C87EE518ACC03091BD29A3D23CA3` | MATCH |

## Control dump (harness archive; not a bitstream)

| Check | SHA256 | Verdict |
|-------|--------|---------|
| File (`SHA256.txt`) | `6539605C5BB07C090A0483176A80018066F893A66FFF93F4A9743E29DC363923` | MATCH |
| Canonical JSON (`control_sha`) | `9E746E3F6DD5F488F4266C274019D85F2E9C8AF764492066060B36BA2AD97F64` | MATCH |
| `EXPERIMENT_SUMMARY.json` | `32A91009099A33350E8D8A7AD14A5BD21C8DCCB8FE8B026A6060C58FC836A8AE` | MATCH |

## New bitstream

**None.** `TRAIN_V2_NEW_BITSTREAM_COUNT=0`. Gate is HARNESS-only; no Vivado synth/impl/bitstream run required or performed this VERIFY.

## Explicit non-claims

- Not BOARD_PASS  
- Not §14 Integrated SoC / HS-02 silicon  
- Not re-run of teacher harness / pytest  
- Not WNS/TNS/util for a train_v2 design (no design bit produced)  
- `integrate_fit` PASS_NARROW remains POST_ROUTE_PROXY ≠ section14 SoC  
- SILICON_DEFERRED  

## NEXT

Orchestrator may continue VERIFY trio / STATUS. No BOARD_PASS.

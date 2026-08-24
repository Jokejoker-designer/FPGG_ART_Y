# TERMGEN closeout — full candidate feature generation

**Gate:** `termgen`  
**Agent:** `a7-ng-rtl-scorer`  
**Result:** PASS (engineering — not BOARD_PASS)  
**Date:** 2026-08-22  
**Board:** Arty A7-100T (XSim + OOC synth; no silicon)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | candidates/s needs TermGen, not composer-only |
| UNKNOWN | RTL HDC/VSA four families exact + DSP=0? |
| H_CANDIDATE | TermGen emits all families bit-exact vs oracle |
| H_RIVAL | host-composed / partial terms |
| FALSIFIER | missing family; golden miss; Top-8/frozen regress |
| UNIT | 32 candidate vectors (seed `0xA7622201`) |
| CONTROL | Top-8 + bucket + LM-06/01R/02M SHA |
| METRICS | exact golden; 16 lanes; DSP; OOC WNS |

## Result

Marker `A7NG_TERMGEN_XSIM_PASS` on 16 lanes × 32 vectors.  
OOC: **DSP=0**, LUT=12610, FF=8112, **WNS=+2.617 ns**, TNS=0 @ 100 MHz (OOC estimate).

Rival dual-side BIND cancelled relation (dead ports in first OOC) — **falsified and fixed** before PASS archive.

## Controls

| Artifact | SHA256 | Status |
|----------|--------|--------|
| `a7ng_topk.sv` | `F671FCB1…AA197636` | MATCH |
| `a7ng_frontier_buckets.sv` | `CE38FEC3…ACDD2C565` | MATCH |
| `arty_a7_lm06.bit` | `67C37DD5…4282E3BA` | MATCH |
| `arty_a7_eam01r.bit` | `57D1DF1B…0E9EF6CF` | MATCH |
| `arty_a7_eam02m.bit` | `DB3BC58A…84CFE696` | MATCH |

Primary RTL SHA: `DD637EDA…22DF5218  a7ng_termgen_lane.sv` (see `SHA256.txt`).

## Explicit non-claims

No BOARD_PASS. No 1.6G candidates/s. No integrate_fit / TRAIN-V2 / frozen overwrite.

## NEXT

Orchestrator `--dispatch` next OPEN after auditor.

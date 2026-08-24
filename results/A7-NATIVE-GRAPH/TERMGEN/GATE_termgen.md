# GATE: termgen (feedback R3 / P1 TermGen)

**Agent:** `a7-ng-rtl-scorer`  
**Evidence class:** PYTEST_BEHAVIORAL + XSIM + OOC_SYNTH (not BOARD)  
**Marker:** `A7NG_TERMGEN_XSIM_PASS`  
**Law:** `a7ng-termgen-v0`  
**Date:** 2026-08-22  
**Board:** Digilent Arty A7-100T `xc7a100tcsg324-1` @ 100 MHz (OOC)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | end-to-end candidates/s claims need full feature generation, not score-composer alone |
| UNKNOWN | can RTL emit Hamming + relation binding + intent/context + path features (HDC/VSA-friendly) with exact golden and DSP=0 preferred? |
| H_CANDIDATE | TermGen microarchitecture produces all four feature families bit-exact vs oracle |
| H_RIVAL | partial terms / host-composed features masquerading as TermGen |
| FALSIFIER | missing term family; golden mismatch; Top-8/frontier/frozen bit SHA regress |
| UNIT | candidate vector / query bag (N=32), not cycles-as-queries alone |
| CONTROL | frozen LM-06/01R/02M/A0.3; `a7ng-topk-global-v1` SHA; frontier bucket SHA; scorer lane/array untouched |
| METRICS | exact match vs golden; 16 lanes; DSP count; OOC WNS; no BOARD_PASS; no candidates/s claim |

## Verdict

**PASS (engineering).** H_CANDIDATE held for this bag. H_RIVAL falsified: all four families emitted from cues in RTL (not host `score_terms_t` feed). Dual-side BIND that cancelled `relation_cue` was caught in OOC (Synth 8-7129) and fixed to `sim(query ⊕ ROTL1(rel), node)`.

## CHANGED

| Path | Role |
|------|------|
| `rtl/native_graph/pkg/a7ng_pkg.sv` | cue_t + HDC helpers + `ng_termgen_compose` |
| `rtl/native_graph/scorer/a7ng_termgen_lane.sv` | NEW 2-stage TermGen PE |
| `rtl/native_graph/scorer/a7ng_termgen_array.sv` | NEW 16-lane array |
| `rtl/native_graph/scorer/a7ng_termgen_ooc_top.sv` | NEW OOC shell |
| `tests/xsim/termgen_oracle.py` | golden oracle |
| `tests/xsim/tb_a7ng_termgen.sv` + `.svh` + `run_a7ng_termgen.tcl` | XSim bag |
| `docs/native_graph/TEST_MATRIX.md` | TG-* rows |

**NOT changed:** scorer compose RTL (NG-01), Top-K, frontier, DDR, integrate_fit, TRAIN-V2, frozen bits.

## TESTS

| ID | Result |
|----|--------|
| TG-P1 `termgen_oracle.py` | PASS `TERMGEN_PY_PASS` n=32 |
| TG-X1 `run_a7ng_termgen.tcl` | PASS `A7NG_TERMGEN_XSIM_PASS` |
| NG-01 scorer regress | PASS `A7NG01_XSIM_PASS` |
| TG-X2 hierarchy | 16/16 `g_tg[*].u_tg` |
| TG-U1 OOC | LUT=12610 FF=8112 **DSP=0** WNS=+2.617 ns TNS=0 |
| TG-C1 Top-8 SHA | MATCH `F671FCB1…AA197636` |
| TG-C1 bucket SHA | MATCH `CE38FEC3…ACDD2C565` |
| Frozen LM-06/01R/02M | MATCH prior FRONTIER controls |

## Law (observable families)

```text
entity_match     = sim8(query, node)                 # Hamming
relation_match   = sim8(query ⊕ ROTL1(rel), node)    # BIND
intent_match     = sim8(intent, ROTL16(node))
context_match    = sim8(context, ROTL32(node))
path_confidence  = sim8(path, ROTL8(query ⊕ node))
learned_prior    = passthrough memory term
contradiction    = pop64((query⊕node) & path) >> 1
```

II=1 after fill; latency=2 cycles.

## Explicit non-claims

- Not BOARD_PASS  
- Not end-to-end candidates/s (TermGen+scorer+pipeline not yet routed as throughput claim)  
- No integrate_fit / TRAIN-V2 / WM wipe / frozen overwrite  
- Evidence_class ≠ silicon

## NEXT

Parent `--dispatch` after auditor; queue next OPEN. No self BOARD_PASS.

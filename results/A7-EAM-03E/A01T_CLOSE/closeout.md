# A7-EAM-03E-A0.1-T — closeout (2026-08-20)

Timing-only rung. Learning law `eam03e-a0-signsgd-v1` unchanged.

## Verdict

| Gate | Required | Actual | Result |
|------|----------|--------|--------|
| XSim golden, 32 steps | exact | exact, all 7 values | PASS |
| WNS | >= 0 | +0.637 ns | PASS |
| TNS | = 0 | 0.000 ns | PASS |
| DSP | = 0 | 0 | PASS |
| Silicon golden vs XSim | exact | exact, all 7 values | PASS |

All five A0.1-T gates are met.

**BOARD_PASS is not declared here.** `AGENTS.md` states "AI cannot declare
BOARD_PASS". This document records that the gate set defined in the task
mandate section 7 is satisfied; the milestone declaration itself is reserved
for the human board. See "Authority conflict" below.

## What changed

`rtl/eam/eam03e_core.sv` only, relative to the frozen T snapshot
`results/A7-EAM-03E/a01t_eupd/eam03e_core.sv`
(`717025A88F12C22B356DD626651CC359E2D5533083ACC9FADF3086F7815B04EE`):

1. `S_DIST` no longer computes and accumulates in one state. It now registers
   `ad <= e3_abs16(hA[i] - hB[i]) >> 5` and hands off to a new `S_DADD`, which
   performs the saturating accumulate into `d1_acc` and advances `i`.
2. Entry into DIST with an empty B buffer clears `d1_acc`, `dH_acc` and `pbi`,
   removing stale accumulator carry-over.

Term order `i = 0..31`, the `>> 5` shift, and the `16'hFFFF` saturation clamp
are untouched, so the change is arithmetically transparent. That was an
inference when the patch was written; the XSim and silicon goldens below make
it evidence.

Cost: one extra cycle per element, 32 extra cycles per distance evaluation.

## Timing lineage

| Attempt | Datapath change | WNS (ns) | TNS (ns) | LUT |
|---------|-----------------|---------:|---------:|----:|
| A0 | 64-wide pacc | -1.891 | -990.600 | 11010 |
| pacc | serialised projection + MAC | -0.563 | -5.218 | 7692 |
| eupd | register `sgn_r` / `wdelta_r` | -0.119 | -0.407 | 7653 |
| **A01T_CLOSE** | **S_DIST → S_DADD split** | **+0.637** | **0.000** | 7713 |

Full route summary: WNS +0.637, TNS 0.000 (0/18857 failing), WHS +0.037,
THS 0.000 (0/18857 failing), WPWS +3.750, TPWS 0.000.
Report states "All user specified timing constraints are met."

Utilisation: LUT 7713 (12.17%), FF 7173 (5.66%), BRAM tile 3 (2.22%),
DSP 0, IOB 8, BUFGCTRL 1.

## Evidence classification

| Claim | Class | Source |
|-------|-------|--------|
| S_DADD preserves arithmetic | EVIDENCE | XSim exact + silicon exact |
| 100 MHz closes with margin | EVIDENCE | post-route report, this bit only |
| Board reproduces XSim bit-exactly | EVIDENCE | `board_ladder_a01t_close.json` |
| Seed `0x22222222` still inverts | EVIDENCE | same board run, M_L1 = -1258 |
| Encoder produces useful geometry | NOT ESTABLISHED | out of scope for T |

XSim and board evidence are recorded separately and were not mixed.

## Golden authority (unchanged, not edited)

Seed `0x11111111`, strings `ALPHA` / `BETA.` / `OMEGA`, 32 steps:

| Phase | d1(AB) | d1(AC) | XSim | Board |
|-------|-------:|-------:|------|-------|
| after seed + prime | 3930 | 5362 | match | match |
| after 32× BETA=SAME | 1093 | 2012 | match | match |
| after RESEED | 3930 | — | match | match |
| after 32× OMEGA=SAME | 1574 | 451 | match | match |

## Known failure reproduced, not hidden

Seed `0x22222222` on the same silicon run:

```
SAME  2135 -> 1487
DIFF  1679 ->  229
M_L1 = 229 - 1487 = -1258
```

This is the documented discriminative inversion. It reproduces exactly, which
increases confidence that it is a property of the learning law rather than of
the timing patch. It belongs to A0.2-L. It is **not** a T regression and was
**not** used to justify touching `E3_MARG` or the margin.

## Artifacts

| Item | Value |
|------|-------|
| Bit | `arty_a7_eam03e_a01t_close.bit` |
| Bit SHA256 | `80F2ED9E0C1A1679F87D5362F2D953258DEF640C6C2079E41B7BFBD7BCD12F41` |
| Core source SHA256 | `F8221477803E74DCFF1F801B38FEF839A1B0586397F73DAFE2989451A89ADEA5` |
| Board | Digilent Arty A7-100T, JTAG `210319BE776EA`, UART COM12 @115200 |
| Vivado | 2026.1, `C:\2026.1\Vivado` |

Per-file source hashes are in `manifest.json`.

`build/out/arty_a7_eam03e.bit` now holds this same bit. The previous `eupd`
bit (`ADD9E462…951C2262`) was verified byte-identical to its archive copy at
`results/A7-EAM-03E/a01t_eupd/` before `build/out` was overwritten, so nothing
was lost. No frozen 01R / 02M / LM artifact was touched.

## Authority conflict to resolve

The task mandate (section 7, step T4) says the milestone "may be called
BOARD_PASS" once these five gates pass. `AGENTS.md` says "AI cannot declare
BOARD_PASS". Both cannot be satisfied by an agent-written document, so the
declaration is deliberately left open rather than silently resolved either way.
Everything the declaration would depend on is recorded above.

## Next gate

Phase S — long-horizon stability. Do not start A0.2-L before it. The known
collapse dynamic (recurrent scale runaway, effective-rank collapse, AUC → 0.5)
must be reproduced and measured against update count before any repulsion
change is attempted.

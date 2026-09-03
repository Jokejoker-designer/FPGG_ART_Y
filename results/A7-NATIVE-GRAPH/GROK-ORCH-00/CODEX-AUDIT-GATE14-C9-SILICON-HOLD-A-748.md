# Codex audit branch — Gate14 C9 silicon HOLD_A mismatch

**Branch:** `codex-audit/gate14-c9-silicon-hold-a-748`  
**Repo:** https://github.com/Jokejoker-designer/FPGG_ART_Y  
**PROGRAM:** one shot of IO-SAFE bit. Do not auto-reprogram. Do not retarget oracle.  
**GATE14_PASS / BOARD_PASS:** not claimed.

## Frozen oracle (do not edit)

SHA `062932B3853144526B1C9A42C2076966C45EF108C707546C68C9BC89754C912B`

| Query | C9 pack | OUT |
|-------|---------|-----|
| HOLD_A | `8382238122802120` | 653 |
| UNREL | `8786858483828180` | 689 |
| CONTRA | `2322832182208180` | 237 |
| HOLD_B | `8382438142804140` | 60 |

## What passed (XSim / full-chip)

- C9-03 graph, C9-05 handshake, C9-06 SoC glue XSim: 20/20 A+B, packs+OUT match oracle.
- C9-07: removed Pmod `ja[7:0]`. NSTD-1=0 UCIO-1=0. Unique bit SHA `3A7EF2044CD92730F048032ABF9E9CC914461EE7CE767745089CD082CC31A00B`.

## Silicon first divergence

Programmed `3A7EF204` once. COM12 armed first. Distinct tokens `0x10..0x23`. C5 0→20, C6 txn 1→20.

HOLD_A teacher-off:

- observed OUT **748**
- observed C9 pack **`2322838281802120`**
- want 653 / `8382238122802120`

Stopped. B not run.

Evidence: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-GATE14-C9-SOC-IO-SAFE-BIT-07/BOARD/`

## Ask Codex

Why silicon C9/OUT ≠ XSim learned Top-8 on the same RTL path. Candidates: UART dump C9 field, persist GEN `0xFFFFFFFF`, bind pack on board, TRESET-before-A `afor=1`. Do not change oracle. Do not program a second bit unless a new unique SHA is built.

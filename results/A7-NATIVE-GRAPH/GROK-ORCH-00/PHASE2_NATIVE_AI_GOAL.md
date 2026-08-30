# Phase 2 — Native AI GOAL (min-heap architecture)

```text
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS.
```

**GOAL không đổi** (blueprint tổng quát, human stamp only):

```text
NATIVE_V1_MINI_AI_BOARD_PASS
```

Authority: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md`  
Loop: `15_CURSOR_BLUEPRINT_LOOP.md`  
Live queue: `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` (`goal` field already this string).

AI **không** tự stamp BOARD_PASS / MINI_AI_BOARD_PASS.

## Architecture adaptation (same goal, real silicon)

Blueprint §5 originally said comparator **tree**. Fabric on Arty A7-100T could not place the bitonic global Top-8 (slice 100%). Product global reducer is:

```text
G_0 = empty
G_(t+1) = TopK( G_t ∪ TopK(W_t) )     # unchanged law
local 16→8 : frozen a7ng_topk (bitonic, a7ng-topk-global-v1)
cross-wave : a7ng_topk_wavefront_minheap HEAP_CMP_LANES=1
producer   : stall while busy (serial / Cursor serial family)
tie        : lower node_id, then lower lane — same beats() as a7ng_topk
golden A-FAST pack : 64'h3B392B291B190B09 → pred=664
```

Do **not** reuse 1–2 cycle bitonic handshake. Do **not** mix LM-06 `pred=744`.

## Phase 2 silicon evidence pack (toward human BOARD_PASS)

| Box | Need | Status 2026-08-31 |
|-----|------|-------------------|
| Existence UART | `NATIVE_V1_EXIST_ROW,pred=664` | CONFIRMED BIT-01 `439CC42D` and SLICE-OPT `2C1D58CE` |
| POISON | `POISON=0` | CONFIRMED |
| H2 PACK/TOPK | `PACK=TOPK=3B392B291B190B09` | **FAIL on UART_SLIM** (`PACK=TOPK=0`) — 64-bit CDC was inside `if (!UART_SLIM)` |
| Fit | WNS≥0 TNS=0 xc7a100t | SLICE-OPT WNS=+0.802 |
| Mini-AI §14 | every checklist box + human stamp | NOT_EVIDENCED |

Next unknown (this bag): UART_SLIM prints TOPK/PACK after 4 min-heap commits + bind, with module-scope 64-bit CDC.

CONTROL file `439CC42D` never overwritten.

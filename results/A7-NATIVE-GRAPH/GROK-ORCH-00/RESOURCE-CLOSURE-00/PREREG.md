# RESOURCE-CLOSURE-00 — preregister

**PROGRAM=NO.** No board. No overwrite of `B0F42C11` / `439CC42D`.

## One unknown

Does constant-folding `UART_SLIM=1` so that existence-dead sticky/CDC/DONT_TOUCH debug
is **not elaborated** recover **≥1000 free slices** (target 1000–1500) with WNS≥0,
without changing the causal markers:

```text
TOPK=3B392B291B190B09
PACK=3B392B291B190B09
POISON=0
NATIVE_V1_EXIST_ROW,pred=664
```

## Keep (frozen law)

- 16 scorer lanes, `a7ng_topk` beats(), min-heap `G_(t+1)=TopK(G_t ∪ TopK(W_t))`
- poison_i=0, UART_SLIM existence messages, 64-bit PACK/TOPK CDC, 4-commit handshake
- TinyGPT SHA `29D230FC…`, bind `C5F57AD1…`, heap `C197E419…`

## Cut (existence-dead when UART_SLIM=1)

F1/D3/E1/E3 sticky FF, ui DONT_TOUCH CDC probes, atom mailbox, RID/AR-FIFO/W_STALL/TILE latches.
Do **not** migrate FIFO BRAM→LUTRAM. Do **not** add learner.

## Pass / fail

| Result | Meaning |
|--------|---------|
| Slice used ≤ 14850 (≥1000 free) + WNS≥0 + A-FAST XSim pred=664 | PASS_NARROW, **still PROGRAM=NO** |
| Slice save < 1000 | FAIL packing hypothesis; next = control-set merge / mailbox, not LUTRAM |
| A-FAST pred ≠ 664 | FAIL; revert |

Board run of a successor requires a **new** named token. This prereg is not that token.

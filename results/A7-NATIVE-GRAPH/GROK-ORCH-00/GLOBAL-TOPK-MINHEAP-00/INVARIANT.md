# GLOBAL-TOPK-MINHEAP-00 — heap invariant freeze

**Gate:** research-only in grok-orch-00. **PROGRAM=NO.**
**Control:** frozen `a7ng_topk.sv` + `a7ng_topk_wavefront_global.sv` (do not edit).
**Candidate:** `rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv` (new file only).

## Recurrence (unchanged)

```text
G_0 = empty (all slots invalid)
G_(t+1) = TopK( G_t ∪ TopK(W_t) )
```

Process only eight local winners per wave: `TopK(G ∪ W) = TopK(G ∪ TopK(W))` under the same total order.

## Comparator = frozen `beats()` (copy; do not invent)

From `a7ng_topk.sv` `cand_t {v, s, id, lane}`:

1. If `a.v != b.v` → valid wins.
2. If both valid: higher signed score wins; if equal, lower `node_id`; if equal, lower `lane`.
3. If both invalid: lower `id` then lower `lane`.
4. `valid_mask=0` never preferred under fill.

Heap **root = worst retained** among the current K valid (or invalid-padded) entries: the candidate that **loses** `beats()` to the other retained entries. A new wave candidate **enters** iff it `beats(root)`.

## Algorithm (HEAP_CMP_LANES=1)

```text
CLEAR: G empty, merge_count=0, busy=0
WAVE_VALID && !busy:
  latch wave[0..wave_scored-1]
  busy=1
  for each valid wave slot i in 0..n-1:
    if G underfilled: insert into first invalid slot, heapify
    else if beats(wave[i], root): replace root, heapify-down
    else drop
  ORDERED_COMMIT: sort retained 8 by beats() into slot0=best .. slot7=eighth
  pulse global_valid_o one cycle
  merge_count++
  busy=0
```

Exact duplicates: retain a stable rank tag (`lane` = original merge-lane 0..15 mapping, or wave index + 8 like frozen slot map 8..15 for W). Must match frozen bitonic when the same 16-slot concatenation is used as the mental model.

## Pin-compatible interface

Same ports as `a7ng_topk_wavefront_global`:
`clk, rst_n, clear_i, wave_valid_i, wave_scored_i[4:0], wave_score_i[K], wave_id_i[K], global_valid_o, global_score_o[K], global_id_o[K], busy_o, merge_count_o`

Output after every wave: **best → eighth-best** in slots 0..7. Invalid pads at the tail.

`busy_o` must reject/ignore `wave_valid_i` until commit (backpressure like `merge_armed`).

## Cycles/wave bound (lanes=1)

Worst case: 8 inserts × O(log K) heapify + O(K log K) or O(K²) ordered commit. Bound **≤ 256 cycles/wave** (audit 64 compare-scan serial is the rival; heap may use more for commit). Prefer shallow FF; **BRAM=0, DSP=0**.

## Falsifiers (any ⇒ REJECT_SEMANTICS)

| ID | Fail if |
|----|---------|
| F1 | W2 `0xDEADBEEF` score 135 does not displace W1 8th (130) |
| F2 | Last-wave-only equals G_final on that counterexample |
| F3 | Comparator differs from `beats()` |
| F4 | `a7ng_topk.sv` edited |
| F5 | BOARD_PASS / silicon / hardcoded E0 9,11,25… |
| F6 | Equal-score, lower id loses |
| F7 | Underfill (<8) pads wrongly (valid preferred) |
| F8 | `clear_i` does not empty; or `wave_valid` while busy commits a second wave |

## MUST NOT

Hardcode E0. Last-wave shortcut. Touch soc_top, bind, LM, DDR, UART. Edit frozen bitonic control. Merge into product. PROGRAM.

Evidence class: **XSIM** then **OOC**. Not BOARD.

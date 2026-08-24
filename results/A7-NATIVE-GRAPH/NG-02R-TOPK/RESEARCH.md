# NG-02R-TOPK — research comparison (FANNS-aligned K-selection)

**Gate:** `ng02` SEV-0 reopen / research branch `NG-02R-TOPK`  
**Law:** `a7ng-topk-global-v1`  
**Date:** 2026-08-21

## Options compared

| # | Primitive | Comparators (N=16,K=8) | Registered cycles | Ordered Top-8 | Verdict |
|---|-----------|------------------------|-------------------|---------------|---------|
| 1 | Full bitonic sorting network 16→8 | 80 CAS / depth ~10 | 1 | Yes (take ranked[15:8] reversed) | **SELECTED** |
| 2 | Exact partial-selection network | ~60–72 + ~19 K-sort | 1 | Only after extra K-sort | Defer — small LUT save, harder oracle audit |
| 3 | Systolic priority queue (multi-input) | ~8 per insert × 16 | ≥16 (or folded) | Yes | Reject for this gate — fights II=1 batch of 16 scorer lanes |

## Selection reason

At N=16 the bitonic net is small, one-cycle registered, and bit-identical to a Python total-order oracle. Partial nets do not buy enough at this size; systolic PQ is the wrong latency shape for a 16-wide scorer fire.

## Silicon path

`rtl/native_graph/topk/a7ng_topk.sv` — bitonic 16, ascending, Top-8 = `s10[15]…s10[8]`.

## Contract (hard stop)

- Tie: lower `node_id`; then lower lane index  
- `valid_mask_i=0` loses to any valid; pad underfill by (id, lane)  
- 100_000 random vectors + ties + signed scores + masks: RTL == Python oracle every case  
- Counterexample `{100,99}/{10,9}/…` must keep 100 **and** 99 (pair-winner TB retired)

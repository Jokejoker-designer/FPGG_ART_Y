# NG-02R-FLOW closeout

**Gate:** `ng02r_flow`  
**Branch:** `NG-02R-FLOW`  
**Agent:** `a7-ng-topk-frontier`  
**Result:** PASS (XSim flow / conservation — not BOARD_PASS)  
**Date:** 2026-08-22

## Unknown closed

Complete backpressure so a new 16-lane batch cannot overwrite/interrupt an in-flight Top-8→frontier push.

## Defect (pre-fix)

`topk_fire = &sc_valid` with 8-cycle hold push and no busy gate → concurrent scored batch reloaded `hold_*` / reset `push_idx`, silently dropping unpushed winners. Sparse board smoke hid it.

## Fix

| Piece | Change |
|-------|--------|
| `a7ng_ng02_core.sv` | FSM `IDLE→WAIT_SCORE→WAIT_TOPK→PUSH`; `batch_ready_o` only in IDLE; gate scorer input on handshake; single Top-K fire; never reload hold in PUSH; stall push on `frontier_ready` |
| `a7ng_frontier_buckets.sv` | `ready_o`; same-cycle pop+push; overflow remains intentional prune flag |
| `a7ng_topk.sv` | **unchanged** — law `a7ng-topk-global-v1` intact |
| TB | `tb_a7ng_ng02_flow.sv` ≥100k cycles random ready/valid + busy overwrite-attack |

## Tests

```text
xvlog/xelab/xsim tb_a7ng_ng02_flow   → A7NG02R_FLOW_XSIM_PASS
xvlog/xelab/xsim tb_a7ng_frontier    → A7NG02_FRONTIER_XSIM_PASS (regress)
```

### Actual (100_000 cycles)

```text
batches=7047 accepted=56376 popped=56376 ovf=0
DROP=0 DUPLICATE=0 UNEXPLAINED_REORDER=0 CONS_FAIL=0 READY_BUSY_FAIL=0
```

Conservation (every cycle after NBA):

```text
accepted_winners = frontier_count + popped + overflow_pruned + still_in_hold
still_in_hold = (ST_PUSH ? 8 - push_idx : 0)
```

## SHA256

See `SHA256.txt`. Primary RTL:

| File | SHA256 |
|------|--------|
| `rtl/native_graph/topk/a7ng_ng02_core.sv` | `241AB11FD2CE008C84B9C9FBB9C6B70145825050FE1835C1489233823AD7B009` |
| `rtl/native_graph/frontier/a7ng_frontier_buckets.sv` | `CE38FEC3562343C64AB718243CE5F4B815A128524EBA2903BE20CD5ACDD2C565` |
| `rtl/native_graph/topk/a7ng_topk.sv` (untouched law) | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` |

## Explicit non-claims

- Not BOARD_PASS  
- Did not overwrite NG-02 / NG-02R-TOPK archives or frozen 01R/02M/LM-06/A0.3 bits  
- Did not implement wide-dispatch / epoch / TermGen  

## NEXT

Per `STATUS/P0_P1_BACKLOG.md`: P1 `ng06_wide_dispatch` (or pipeline `LOOP_STATE` next OPEN after orchestrator `--dispatch`).

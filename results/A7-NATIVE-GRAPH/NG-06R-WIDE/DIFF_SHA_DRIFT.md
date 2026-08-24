# DIFF — share.sv SHA drift (3D394158 → 4C604278)

**Gate:** `ng06_wide_dispatch`  
**Unknown:** `SHA_FREEZE_MATCH`  
**Date:** 2026-08-22  

## Timeline (FACT)

| Event | Time | SHA |
|-------|------|-----|
| Bag ladder (prior repair) | 02:12:02 | elaborated live RTL then = `3D394158…` |
| SHA256.txt freeze (UTF-16) | 02:12:38 | archive listed `3D394158…` |
| Live `a7ng_multi_agent_share.sv` rewrite | **02:13:19** | live → `4C604278…` |
| Auditor r2 | after | PASS_NARROW; allow_loop_done_eng=false |

## Diff availability

- No git repo in workspace; no Cursor History snapshot of `3D394158…`.
- Byte-level 3D39↔4C60 diff: **NOT RECOVERABLE** (UNKNOWN as to exact hunk).
- Live file (4C60) still declares law `a7ng-share-v1`; compact exact allocator + banked queues present.
- Visible port comment block on `pop_valid_o` (“DEBUG / COMPATIBILITY ONLY”) — **INFERENCE**: post-freeze rewrite was comment/doc drift, not law_id change. Allocator body not proven identical to 3D39 without bytes.

## Decision

**Accept live `4C604278…`** (cannot revert to 3D39).  
Re-run full ALWAYS/SPARSE/BURSTY × N_WAY {1,4,8,16} on frozen live tree; re-freeze SHA256.txt UTF-8 to that run.  
Law id unchanged. No epochs.

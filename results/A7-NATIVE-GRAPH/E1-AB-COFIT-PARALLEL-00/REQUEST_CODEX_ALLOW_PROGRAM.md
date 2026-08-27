# REQUEST — ALLOW_PROGRAM (E2 board existence)

**Date:** 2026-08-25T02:10:00+07:00  
**Gate:** `native_v1_existence_board_parallel_00`  
**Requestor:** Cursor board lane  
**Authority:** Grok DECIDE Option A + E1-CLOCK80 PASS

## Preconditions (file-backed)

| # | Requirement | Evidence |
|---|-------------|----------|
| 1 | Stage A XSim causal | `A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664` |
| 2 | VERIFY trio | AUDIT_EVIDENCE/XSIM/HLB PASS |
| 3 | E1 BRAM co-fit | 96 RAMB36 ≤ 135 PASS |
| 4 | E1 timing @ existence clock | CLOCK80 WNS +3.648 ns, TNS 0 |
| 5 | DCP lineage | `E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_post_route.dcp` SHA `92A27DF7…358EA` |
| 6 | Human program scope | `BRIDGE.board.com12_authorized_gate` = this gate |

## Requested action

Issue **`ALLOW_PROGRAM`** for E2 only:

- Worktree: `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`
- Clock: **12.5 MHz** (80 ns) — graph domain
- Scope: existence board run (pred/token, host authority zero)
- **Not:** BOARD_PASS, HS-02, 800k, full NATIVE_V1 closure

## Codex-off proxy

See `ALLOW_PROGRAM_GROK.md` in same directory tree (Grok standing proxy).

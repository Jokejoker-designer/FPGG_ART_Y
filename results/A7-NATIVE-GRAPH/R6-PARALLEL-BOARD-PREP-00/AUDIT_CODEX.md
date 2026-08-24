# Codex audit — R6-PARALLEL-BOARD-PREP-00

**Verdict:** `ACCEPT / PLANNING_READ_ONLY_COMPLETE`  
**Engineering/route/board verdict:** none  
**R6:** uninterrupted; Grok lock retained

## Accepted

- All six required planning artifacts exist under the sole allowed result directory.
- R6 manifest records HEAD/dirty state, active PIDs, immutable key hashes and the live log as `APPEND_ONLY / FINAL_SHA_PENDING`.
- Verification A/B/C explicitly does not weaken or replace the in-flight R6 acceptance.
- E1 uses future collision-safe build/result directories and forbids launching P&R in this prep task.
- E2 retains `com12_authorized_gate=null` as a hard STOP and does not claim BOARD authority.
- Collision map protects R6 source, `xsim.dir`, build/result paths, processes, Git state and board.
- Mailbox Result exists; `lock.owner=grok`; active `xsimk` PID 177056 remains alive.

## Required corrections before execution — not blockers for planning close

1. The final R6 freeze ledger must hash every transitive compiled source named by `native_v1_ab_mig_xsim.prj`, plus tool/MIG provenance—not only runner, TB, integration core, `.prj`, xelab and preregistration.
2. E2 board lineage must treat the E1 post-route DCP and its SHA as mandatory once E1 exists; it must not remain `optional` in the actual board gate manifest.
3. Class A must preregister one exact memory mode (`SIM_FULL=1` fast substitution or a bounded no-MIG `SIM_FULL=0` service). The planning phrase `SIM_FULL=0 or fixture-weight path` is not itself an executable control.

## Artifact hashes

| Artifact | SHA256 |
|---|---|
| `CURRENT_WORKTREE_COLLISION_MAP.md` | `3AAAD6B153EE357F76C8BD90922330C8C4B3C052283A9BF45006A0D63BF0908C` |
| `E1_POSTROUTE_PREP.md` | `18BBC3882ACD12B09004162595A6A97158460E9CF6C0F5F94835B391CFFB1E4C` |
| `E2_BOARD_PREP.md` | `407AA835FEA5D604827FF06B3533F9442BD41F26A879A448181BB19A38F4A863` |
| `R6_FREEZE_MANIFEST_DRAFT.md` | `46D9AEA79F67C8B876B7CA0DC15009A3CDBD2CA1C0F758943346E1EEB658D09E` |
| `RESULTS.md` | `1048E5FC61AC8B0ECFF2D5344BBE1DD9FE2B5B4BCEA809434F8645E34F69B53C` |
| `VERIFICATION_DECOMPOSITION_V0.md` | `93A3CBD96A4D63AFDB20CC93B158653070A9D53B051F6724CBD1E55545E337E6` |

## Boundary

Planning lane is closed and Cursor stops. R6 remains the only active product/evidence run. This audit does not authorize Git mutation, E1 execution, hardware-manager access, COM12, JTAG, bitstream or BOARD_PASS.


# Current worktree collision map — R6 active

**Date:** 2026-08-24T20:35:00+07:00  
**Rule:** Grok owns product + live R6; Cursor prep lane writes **only** `R6-PARALLEL-BOARD-PREP-00/**` + mailbox  

---

## Live R6 footprint

| Item | Value |
|------|-------|
| PIDs | vivado **62640**, xsim **176860**, xsimk **177056** |
| Runner | `tests/xsim/run_a7ng_native_v1_ab_mig.tcl` |
| Snapshot | `tests/xsim/xsim.dir/tb_a7ng_native_v1_ab_mig_sim/` |
| Log | `results/.../NATIVE-V1-AB-INTEGRATE-ACCEPT-00/xsim_ab_mig.log` (APPEND_ONLY) |

---

## FORBIDDEN while xsimk 177056 alive

### Source / product

| Operation | Paths |
|-----------|-------|
| Edit RTL | `rtl/**` |
| Edit TB / XSim | `tests/**` especially `tb_a7ng_native_v1_ab_mig.sv`, `run_a7ng_native_v1_ab_mig.tcl` |
| Edit Vivado Tcl | `vivado/**` |
| Edit MIG IP | `vivado/ip/mig_7series_0/**` |
| Touch R6 artifacts | `results/.../NATIVE-V1-AB-INTEGRATE-ACCEPT-00/*` except new FAIL archive by Grok |
| Regenerate `.prj` | `native_v1_ab_mig_xsim.prj` |
| IP regen / `xci` edit | any |

### Git

| Operation | Reason |
|-----------|--------|
| `git checkout` / `switch` / `reset` | May revert live TB |
| `git stash` | Hides dirty R6 state |
| `git clean` | Deletes `xsim.dir` |
| `git add` / `commit` / `worktree` | Out of scope for prep lane |
| Merge/rebase | — |

### Simulation / P&R tools

| Operation | Collision |
|-----------|-----------|
| `xvlog` / `xelab` / `xsim` | Rebuilds `xsim.dir`, kills snapshot |
| Re-run `run_a7ng_native_v1_ab_mig.tcl` | **Deletes `xsim.dir`** (line 7) |
| Vivado synth/impl on shared `build/native_v1_ab_integrate_00/` | Lock/contention |
| `build_native_v1_ab_postroute.tcl` → ACCEPT-00 outdir | Overwrites `ab_*` reports |
| Second Vivado GUI on same project | — |

### Snapshot / build dirs — hands off

```text
tests/xsim/xsim.dir/
tests/xsim/xsim.dir/tb_a7ng_native_v1_ab_mig_sim/
build/native_v1_ab_integrate_00/
results/A7-NATIVE-GRAPH/NATIVE-V1-AB-INTEGRATE-ACCEPT-00/
```

### Process

| Operation | FORBIDDEN |
|-----------|-----------|
| `Stop-Process` / `taskkill` on 62640/176860/177056 | |
| Suspend / priority change / debugger attach | |
| Delete `xsim.dir` or `*.wdb` | |

### Board

| Operation | FORBIDDEN |
|-----------|-----------|
| Open COM12 | |
| JTAG / Hardware Manager program | |
| `com12_authorized_gate` set without human | |
| Any `BOARD_PASS` claim | |

---

## ALLOWED (Cursor prep lane)

| Operation | Target |
|-----------|--------|
| Write planning pack | `results/A7-NATIVE-GRAPH/R6-PARALLEL-BOARD-PREP-00/**` |
| Read-only git status / hash | |
| Read-only log tail / `rg` markers | |
| Read-only process list | |
| Mailbox ACK | `.agents/handoff/TURN.md`, `log.jsonl` |
| Read contracts / STATUS / closeouts | |

---

## Safe parallel work (others)

| Actor | Safe task |
|-------|-----------|
| Grok | R6 until terminal; CLOSEOUT; lock release |
| Codex | Audit planning pack; no product edit |
| Cursor | This pack only |
| Human | Observe; authorize gates when ready |

---

## E1/E2 future isolation

When E1 opens, use **new** dirs only:

- `build/native_v1_ab_e1_cofit_00/`  
- `results/A7-NATIVE-GRAPH/E1-AB-COFIT-00/`  

Never share ACCEPT-00 report filenames while R6 log remains authoritative.

# LM06-NTOK8-KNOWNNESS-DIFF-00 — preregister (before data)

**PROGRAM=NO.** Core-only. No graph / MIG / COM12 / JTAG / bit / full-chip / Gate14.  
Do not close G5 Teacher-Off. G5 remains FAIL_LM_ORACLE_MISMATCH + FAIL_LM_KNOWNNESS.

## One unknown

What is the **first cycle / address / state** that (a) consumes an act-ram read of X, and (b) the **first deterministic stage** where RTL `tiny_gpt803k_core` SIM_FULL ntok=8 diverges from `a7lm06_fixed_ref` on the same WMEM `C204E559…3001E0` and exact ctx tokens `[2,0,1,3,4,5,6,7]`?

## Lock

| Item | Value |
|------|--------|
| WMEM | `tests/xsim/a7lm06_wmem.hex` SHA `C204E55909D99370387C479C74E28C15F285FDDEE20239459D7C0EC3373001E0` |
| Law | `lm06-signsgd-v1` — do not edit |
| Core | `rtl/lm/tiny_gpt803k_core.sv` SHA `29D230FC…290C9E` **unedited** |
| UNIT tokens | ntok=8 `[2,0,1,3,4,5,6,7]` (G5 HOLD_A pack) |
| CONTROL | ntok=1 `[1]` golden pred **744** (proves image+TB) |
| Init | rst_n + `mem_we` W load + `ctx_we` + `start_fwd` only. No arbitrary act-ram zero. |

## Allowed edit

Wrapper/TB init only. If first divergence proves a core invariant break, **STOP** with exact line; do not patch core in this gate.

## Pass / fail

**PASS:** `x_unknown_consumed=0` and CONTROL pred=744 and UNIT every frozen checkpoint + OUT bit-exact vs oracle.  
**FAIL:** first non-vacuous divergence (consumed-X address/phase and/or first checkpoint mismatch) with raw log + SHA.

Oracle/checkpoints SHA frozen **before** XSim.

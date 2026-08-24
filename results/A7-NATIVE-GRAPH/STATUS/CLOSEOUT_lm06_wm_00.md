# STATUS closeout — lm06_wm_00

**RESULT:** DONE_ENG **PASS_NARROW**
**Evidence_class:** `LM06_WM_XSIM`
**Binding:** `results/A7-NATIVE-GRAPH/STATUS/VERDICT_lm06_wm_00_BINDING.md`
**allow_loop_done_eng:** true (`a7-evidence-auditor`, 9 findings, 0 CRITICAL)

## What was proved

Bit-exact equivalence of the restructured working-set LM-06 candidate against the **recorded**
frozen CONTROL over 9 sequences, 11 preregistered axes MATCH:

- 802,816-byte image SHA-identical (Arm A and Arm B n=1 vs their controls)
- Tier-1 goldens transcribed from `ladder.json` / board recording — not computed at compare time (HLB R2 MET)
- `wr_w[EVAL]=0` from per-phase counters with non-zero `wr_act`/`wr_snp` in same bucket (HLB R3 MET)
- Mutant negative-controls discriminate (MUTANT-2: 4-axis fail; MUTANT-1: UNDETECTED → LIMIT L4)

## What was NOT proved (NARROW limits)

- No synthesis / BRAM / WNS / TNS — simulation only
- No silicon behaviour of the restructure (XSIM ≠ BOARD)
- Only one board-recorded recipe (Tier-1); 8 other sequences not silicon-validated
- Arm A = retile + accounting, **not** a BRAM bound
- Arm B = functional zero-latency n=1, **not** timed RTL
- Port-demand count (≤2 tiles/cycle) is **not** a working-set or ping-pong correctness proof (struck)
- Traffic/reuse-distance belongs to the **ladder**, not this gate

## Verify trio + HLB

| Agent | Verdict |
|-------|---------|
| `a7-ng-xsim-verify` | PASS_NARROW (struck-inference check PASS) |
| `a7-vivado-gate` | PASS (frozen 9/9 MATCH; RESOURCE_BUDGET reverted, 01R=1252) |
| `a7-evidence-auditor` | PASS_NARROW, `allow_loop_done_eng=true`, 9 findings |
| `a7-hlb-auditor` | PASS / HLB CLEAN (R2 MET, R3 MET + R3a carry-forward) |

## Ladder

**BLOCKED** — bit-exact precondition is met (`candidate == frozen CONTROL`), but the binding verdict
and auditor both keep `lm06_wm_ladder` BLOCKED until human/parent re-opens with explicit Pareto scope.
No auto-chain.

## Next gate (human-authorized)

`mig_board_r2` — COM12 authorized for that gate only.

GOAL = **NOT EVIDENCED**.

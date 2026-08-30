# HLB / evidence audit — GLOBAL-TOPK-MINHEAP-00

Read-only audit. **PROGRAM=NO.** No BOARD_PASS. No existence claim.

| Check | Result |
|-------|--------|
| Host winner/address/next-token | none |
| E0 hardcoded 9,11,25… | none in minheap RTL |
| Last-wave shortcut | no; four-wave + W2 DEADBEEF in TB |
| `a7ng_topk.sv` law edited | no |
| Cursor worktree edited | no |
| COM12 / program | no |
| XSim mismatch | **0** `GLOBAL_TOPK_MINHEAP_XSIM_PASS` |
| Preferred LUT ≤1000 | **not met** (OOC 2958) |
| DSP/BRAM | 0 / 0 |
| WNS≥0 TNS=0 @12.5 MHz | yes (heap +49.2 ns; bitonic +0.636 ns) |
| Full-chip integrate | **not done** (prompt STOP) |

```text
ADOPT_CANDIDATE
```

Research-only: exact vs frozen bitonic; OOC LUT −66.8% vs same-run bitonic. Preferred 1000 LUT missed. Full-chip fit is **ENGINEERING_INFERENCE** only. Codex Pareto vs Cursor serial OOC; **do not merge** into product from this gate.

# AUDIT — ng02 / NG-02R-TOPK (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY  
**Verdict:** `AUDIT: CLEAN` → gate **PASS**

## Dispatch law

| Check | Result |
|-------|--------|
| `LOOP_STATE` first OPEN | `ng02` |
| Last implementer line | `gate=ng02`, `agent=a7-ng-topk-frontier`, `result=PASS` |
| `pipeline.json` `character_id` | `a7-ng-topk-frontier` |

## File-backed checks

| Check | Class | Result |
|-------|-------|--------|
| `RESEARCH.md` 3-way comparison | FACT (file present) | PASS |
| Law `a7ng-topk-global-v1` in RTL/closeout/manifest/SHA256 | FACT | PASS |
| 100k vectors `vectors/topk_100k.txt` header+SHA | FACT `n=100000`, SHA `9B4E496E…60276FE4` | PASS |
| `xsim_topk.log` marker | FACT `A7NG02R_TOPK_XSIM_PASS nvec=100000` | PASS |
| RTL/TB/oracle SHA vs `SHA256.txt` | FACT (recomputed match) | PASS |
| Oracle regen seed `0xA7020201` vs vector file | FACT `regen_mismatches=0` | PASS |
| Counterexample keeps 99 | FACT (Python oracle + TB contract) | PASS |
| `results/.../NG-02/` not rewritten as global Top-8 | FACT (still `a7ng-topk-v0`; separate branch dir) | PASS |
| No BOARD_PASS / no silicon global Top-8 claim | FACT (closeout + manifest `not_claimed`) | PASS |

## Scope honesty (not overclaim)

- XSim + host oracle = **EVIDENCE** for global Top-8 RTL law only.
- Archived NG-02 bit remains **pair-winner** historical silicon — not proof under `a7ng-topk-global-v1`.
- `ng02r_flow`, integrate_fit, teacher-off, §14 / BOARD_PASS remain out of scope.

## NOT VERIFIED

- Vivado re-run this audit session (relied on archived `xsim_topk.log`).
- Post-route / board silicon for the new bitonic RTL.

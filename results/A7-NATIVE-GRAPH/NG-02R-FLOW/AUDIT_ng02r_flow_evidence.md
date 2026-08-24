# AUDIT — ng02r_flow / NG-02R-FLOW (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY  
**Verdict:** `AUDIT: 2 FINDINGS` (both MINOR) → gate **PASS**  
**Not claimed:** BOARD_PASS / silicon

## Dispatch law

| Check | Result |
|-------|--------|
| `LOOP_STATE.next` / first OPEN | `ng02r_flow` (OPEN) |
| Implementer `DISPATCH_LOG` | `gate=ng02r_flow`, `agent=a7-ng-topk-frontier`, `result=PASS` (present; duplicated line) |
| `run_blueprint_loop.py` map | `ng02r_flow` → `a7-ng-topk-frontier` |

## File-backed checks

| Check | Class | Result |
|-------|-------|--------|
| `xsim_flow.log` marker | FACT | `A7NG02R_FLOW_XSIM_PASS`; cycles=100000; DROP=DUP=REORDER=CONS=READY_BUSY=0 |
| Headline arithmetic | FACT | `7047 * 8 = 56376 = accepted = popped` (re-derived) |
| `SHA256.txt` vs live RTL/TB | FACT | core/frontier/topk/TB/tcl/log hashes match recomputed |
| `a7ng_topk.sv` law SHA vs NG-02R-TOPK | FACT | `F671FCB1…AA197636` unchanged |
| NG-02 / NG-02R-TOPK archives | FACT | no file mtimes ≥ FLOW window 00:15 |
| Frontier regress | FACT | `xsim_frontier_regress_run.log` → `A7NG02_FRONTIER_XSIM_PASS` |
| Closeout / manifest `board_pass` | FACT | explicit non-claim / `board_pass_claimed: false` |
| Conservation equation vs TB | ENGINEERING_INFERENCE | TB `check_conservation` still enforced for PASS; registered beat documents NBA race fix |
| Intermediate `vivado_batch.log` | FACT | earlier run `CONS_FAIL=119958` / `A7NG02R_FLOW_XSIM_FAIL` at 00:15; not cited in closeout |

## Findings

### [MINOR] Intermediate CONS_FAIL run omitted from closeout
  where     : `results/A7-NATIVE-GRAPH/NG-02R-FLOW/vivado_batch.log` vs `closeout.md`
  claim      : closeout presents only the clean 100k PASS
  evidence   : same headline counts on FAIL log; `CONS_FAIL=119958` then later `xsim_flow.log` PASS after TB/RTL probe fix
  why it matters: reader cannot see the checker/race iteration path without opening the batch log
  fix        : one sentence in closeout pointing at the archived FAIL and the registered-beat fix

### [MINOR] Quantitative claims unlabeled
  where     : `closeout.md` §Actual / conservation
  claim      : batches/accepted/CONS_FAIL=0 stated without FACT/INFERENCE tags
  evidence   : numbers match `xsim_flow.log` (FACT) but document does not classify
  why it matters: auditor rule requires evidence class on assertions
  fix        : tag log-backed counts as FACT; FSM intent as ENGINEERING_INFERENCE

## Scope honesty

- XSim flow/conservation only — **not** board, **not** integrate_fit, **not** Native V1.
- `a7ng_ng02_core.sv` / frontier SHA differ from NG-02R-TOPK archive (expected for FLOW); Top-K law file untouched.
- Phrase “Sparse board smoke hid it” is defect narrative only — not silicon evidence for this gate.

## NOT VERIFIED

- Independent re-run of XSim this session (relied on archived `xsim_flow.log` + matching SHA).
- Post-route / board / bitstream for FLOW RTL.
- Whether parent chat (vs Task) authored the RTL (no Task transcript in this VERIFY_ONLY scope).

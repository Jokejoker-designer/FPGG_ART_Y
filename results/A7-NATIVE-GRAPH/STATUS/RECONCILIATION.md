# A7-NATIVE-GRAPH — Status Reconciliation (2026-08-21 late)

> **SUPERSEDED for live status** by:
>
> - `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md` (feedback + SPEC ↔ Masterplan V2 ↔ evidence)
> - `BRAM_WORKING_MEMORY_SPEC_COMPLIANCE.md` (SPEC §-by-§ matrix)
> - `LOOP_STATE.json` + `00_CURRENT_AUTHORITY.md` §20 status table
>
> Retained as historical snapshot only.

| Milestone | Expected | Actual | Verdict | Next |
|-----------|----------|--------|---------|------|
| Blueprint + crew + pipeline | installed | yes | PASS | — |
| NG-00 schemas + anti-leak | pytest green | **8/8** (+ additionalProperties/freeze/external_LLM) | **PASS** | curriculum corpus |
| NG-01 16-lane scorer | XSim + WNS≥0 + 16 lanes | XSim PASS; **WNS +2.400**; TNS 0; **16 lanes**; DSP 0; LUT 618 | **PASS (eng.)** | silicon optional |
| NG-02 Top-K + frontier | XSim + impl | **XSim PASS**; **WNS +0.408**; 16 lanes; bit archived; **JTAG programmed (smoke)** | **PASS (eng.)** | — |
| NG-03 DDR hotset | measured bytes/query | **XSim PASS**; **WNS +1.166**; bit+SHA archived; **JTAG programmed** | **PASS (eng.)** | human BOARD_PASS only |
| NG-04 path prune | bomb path-local | **A7NG04_PRUNE_PASS** | **PASS (eng.)** | integrate into expand |
| NG-05 local learn | freeze/forget/retrain | **A7NG05_LEARN_XSIM_PASS** | **PASS (eng.)** | DDR-persist prior |
| §14 Native V1 checklist | all boxes | audit: **2 PASS / 22 PARTIAL / 20 NOT_STARTED** (~80–85% left) | **OPEN** | NG-06 → teacher-off → LM compose |
| HLB | no host learning leak | **HLB_PASS** scoped; MAJOR schema gaps **patched** | **PASS (scoped)** | teacher-off HS-02 after DDR prior |
| Frozen A0.3/01R/02M/LM-06 | untouched | untouched | PASS | — |

Audits: `STATUS/SECTION14_AUDIT.md`, `STATUS/HLB_AUDIT_NG.md`. Pipeline runner: `.agents/workflows/native-graph/run_pipeline.py`.

AI does not declare BOARD_PASS.

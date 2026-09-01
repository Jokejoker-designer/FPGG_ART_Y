# P2-G1G5-FULLCHIP-COFIT-00 — preregistration (before data)

**PROGRAM=NO.** No COM12 / JTAG / board / Gate14 close / Teacher-Off.  
Preserve GRAPH-PAYLOAD-NORESET bit `9B2D67C3…` and all G1–G5 / LN-FIX / AFAST bags.

Codex: **PROCEED_PATCHED_CORE**. Historical `pred=664` stays on old core `29D230FC`.  
Gate-14 candidate uses LN-FIX core `75706E2C`. A-FAST exact acceptance **pred=249 / logit0=1623245** (Python). Do **not** force 664.

## One unknown

Can G1 resolver + G2 delta + G4 persist **backend** (1 RAMB18) + G5 live MODE/ANCH/CFRAME be wired into the accepted GRAPH-PAYLOAD-NORESET **Minheap** SoC that already owns graph scorer + stream-minheap TopK + **one** TinyGPT LN-FIX, meeting route0 / clean timing / BRAM36≤135 / DSP≤240, without duplicating FAST TopK / scorer / LM, without editing MIG generated RTL / law / WMEM?

## Must not

- Instantiate `a7ng_teacher_off_soc_xsim` (second TinyGPT).
- Instantiate `a7ng_causal_learn_fast` (second FAST TopK).
- Instantiate bitonic `a7ng_topk` as a second global TopK.
- Edit `a7ng_feedback_resolver.sv` / `a7ng_context_delta.sv` / `a7ng_persist_gen_fast.sv` / `a7ng_teacher_off_glue.sv` (G1–G5 SHA stay).
- Edit MIG generated `.v` / law / `a7lm06_wmem.hex`.

## Before P&R

Exact regressions into **this** bag (do not overwrite parent logs):

| Check | Marker / oracle |
|-------|-----------------|
| AFAST patched | pack `3b392b291b190b09` pred **249** logit0 **1623245** |
| G1 | `FEEDBACK_RESOLVER_UNIT_XSIM_PASS` |
| G2 | `CONTEXT_DELTA_UNIT_XSIM_PASS` |
| G3 | `CAUSAL_LEARN_FAST_XSIM_PASS` (unit only, **not** in SoC) |
| G4 | `PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS` |
| G5 R1 | `TEACHER_OFF_SOC_XSIM_PASS fails=0 CELLS=9 LM_KNOWN` OUT 549/861/549/237 |

## Physical gates (post-route)

route errors **0**. WNS≥0 TNS=0 WHS≥0 THS=0. BRAM36-equivalent ≤135. DSP ≤240.  
Report slices / free / control sets / CDC. **free <256 → RISK**. **free <64 → FAIL**.  
Bit written **only if** regressions + physical PASS. Unique name. PROGRAM=NO.

## Base

GRAPH-PAYLOAD-NORESET-BIT-00 `9B2D67C3…` PHYS=4 LABEL=MINHEAP free=691 WNS=+1.276 BRAM36=103 DSP=19.

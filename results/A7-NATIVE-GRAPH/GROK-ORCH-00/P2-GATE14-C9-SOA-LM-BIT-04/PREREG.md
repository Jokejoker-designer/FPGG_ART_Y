# P2-GATE14-C9-SOA-LM-BIT-04 — preregistration (before data)

**PROGRAM=NO. No COM12. No JTAG. No 40 facts.** Goal = Gate14, not a standalone C9 demo.

Parent `P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03` = **PASS_NARROW** (XSim 20 facts, OOC WNS+51.656, LM_RTL not run, no unique bit).

Frozen oracle (do not retarget):

```text
ORACLE.json SHA256=062932B3853144526B1C9A42C2076966C45EF108C707546C68C9BC89754C912B
HOLD_A OUT=653 pack=8382238122802120
UNREL  OUT=689 pack=8786858483828180
CONTRA OUT=237 pack=2322832182208180
HOLD_B OUT=60  pack=8382438142804140
```

Preserve resident bit `A0B338E0…` and FAIL bag `P2-GATE14-20FACT-RESIDENT-02`. G5 549 unused.

## Unknown (one)

If the **single** C9-03 learned-prior store feeds the Gate14 exam candidate stream **before** the existing min-heap, and persist-FAST-ID bind preemption is **removed** (no second scorer/TopK/LM), does RTL TinyGPT emit the frozen OUTs 653/689/237/60?

## H_CANDIDATE

Exam C9 pack = learned graph TopK (same packs as C9-03). Bind uses that pack, not persist FAST IDs `07060504…`. TinyGPT SIM_FULL matches frozen Python.

## H_RIVAL

1. FAST-ID mux left in place → OUT 549/861/237 (G5).
2. Bind leftover SoA existence pack `3B392B29…` → OUT ≠ 653.
3. RTL ntok=8 ≠ Python (G5 FAIL_LM_ORACLE) → OUT mismatch, do not retarget.
4. 20× A1 surrogate instead of 0x10..0x23.

## Must not

Program. COM12/JTAG. 40 facts. Edit ORACLE.json. Unique bit if XSim or full-chip fails. Self BOARD_PASS / GATE14_PASS.

## Unique bit

Only if: C9 packs match frozen hex, RTL OUT matches 653/689/237/60, parent G4 + C9-03 XSim still PASS, full-chip synth/route WNS>0 TNS=0 DSP legal CDC classed, then **one** unique bit and stop `BIT_READY_FOR_CODEX`.

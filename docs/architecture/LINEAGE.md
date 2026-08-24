# Lineage lock

Program roadmap: `Revised Arty A7 Program Master.md` (A7-LM-00…04 BOARD_PASS / FROZEN; **A7-LM-05 OPEN**).

Two research lines. Never mix claims.

```text
A) 8-Agent Neuromorphic Fabric  — Basys 3, 64 spatial synapses
   BOARD PASS  (M8-HW-01 … 06B). Frozen evidence. Do not edit claims.

B) Basys Tiny Transformer       — 3.2K, LM-05 BOARD PASS
        │
        ▼  A7-LM-00 bit-exact port (this repo)
   Arty A7 Transformer Family   — tiled tensor + DDR + online training
```

EAM (parallel, not LM-07): 00G/01R **BOARD_PASS / FROZEN** router. 02H `Q1P_NOGO` (LM-06 hidden is not a semantic cue). **02M FROZEN / BOARD_PASS** multi-cue exact bind (not semantic). **03E-A0** encoder-only: `XSIM_PASS` + silicon integers match, but `TIMING_FAIL` + `SEED_ROBUSTNESS_FAIL` (`M=−1258` on seed `0x22222222`). **A1 CLOSED.** Next: A0.1-T timing then A0.1-L `M>0`. Do not glue LM-06 into EAM. Do not mix SNN claims.

Forbidden:

- calling the Transformer a continuation of the 8-agent SNN
- conversation / LLM / open-domain chat claims
- host gradient, host weight update, or host next-token in an evidence run

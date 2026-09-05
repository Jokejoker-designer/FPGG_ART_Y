# CLOSEOUT — U6-UNIFIED-RETRIEVAL-00

```text
GATE                     = U6-UNIFIED-RETRIEVAL-00
BASE                     = 5aa8285533b0f4a571dac5328b28a1f8a5ef5fc1
SOURCE_COMMIT            = 5aa8285533b0f4a571dac5328b28a1f8a5ef5fc1
RTL_EDIT                 = YES (new U6 top + 20-bit record LUT; walker/qse/scorer/heap unchanged)
FILES_CHANGED            = rtl/native_graph/integrate/a7ng_unified_retrieval.sv
                           rtl/native_graph/memory/a7ng_u6_record_lut.sv
                           results/A7-NATIVE-GRAPH/GROK-ORCH-00/U6-UNIFIED-RETRIEVAL-00/*
PRIMARY_UNKNOWN          = one AXI sparse stream feed production scorer/Top-K bit-exact?
CANDIDATE_OWNER          = a7ng_sparse_dir_axi
LEGACY_PATH_STATUS       = DISCONNECTED (learned_prior_graph cand_* not in U6 top)
RESULT                   = PASS
EVIDENCE_CLASS           = HOST_MODEL + XSIM
FIRST_DIVERGENCE         = none (final)
VIOLATED_INVARIANT       = n/a
HOST_SEMANTIC_COUNTERS   = 0
OVERFLOW_PROPAGATION     = walker q_overflow_o / n_trunc_o latched (Q8 trunc=16 ovf=1)
BIT_BUILD                = NO
PROGRAM                  = NO
GATE14_PASS              = NO
COM12                    = UNTOUCHED
U7A                      = CLOSED (NEXT after this publish)
U7                       = CLOSED
U8                       = CLOSED
C7_ADDR                  = OBSERVE_ONLY residual OPEN
NEXT                     = U7A-ROOT-B-REACHABILITY-REAUDIT-00
```

Claim only:

> The FPGA-owned sparse retrieval candidate stream is the single
> authoritative source feeding the production scorer and exact Top-K path,
> with bit-exact candidate/evidence/score identity in XSim.

Not claimed: natural-language understanding, 800k semantic quality,
contextual learning PASS, LM generation PASS, board PASS, Gate14 PASS.

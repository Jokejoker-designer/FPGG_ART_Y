# CLOSEOUT — U6-TYPECLASS-UNIFIED-RETRIEVAL-00

```text
GATE                     = U6-TYPECLASS-UNIFIED-RETRIEVAL-00
BASE                     = 6728637056c8c5e646f5d0e8ed191b32718ea7a7
SOURCE_COMMIT            = (set at publish)
RTL_EDIT                 = YES
FILES_CHANGED            = rtl/native_graph/integrate/a7ng_u6_typeclass_retrieval.sv
                           rtl/native_graph/integrate/a7ng_u6_typeclass_ooc_top.sv
                           rtl/native_graph/memory/a7ng_typeclass_materialize.sv
                           rtl/native_graph/memory/typeclass_table.svh
                           results/A7-NATIVE-GRAPH/GROK-ORCH-00/U6-TYPECLASS-UNIFIED-RETRIEVAL-00/*

MASTER_RETRIEVAL_OBJECT  = TYPE_CLASS
QUERY_LAW                = qse-v1-lexicon-hdc-00 UNCHANGED
RETRIEVAL_LAW            = masked conjunctive (T2 frozen)

TYPECLASS_TABLE_SHA256   = B5958D4ADBE96F1D4432915E767BA2C4806594DBB291BBFFBEC95FE588E436C2
CLASS_ID_MAPPING_SHA256  = CEA2B9710D4D5F229BC341DF790E557B20F023F98161464C6C79BEADAE6BD68B

CANDIDATE_OWNER          = a7ng_typeclass_scan
LEGACY_NID_STATUS        = DISCONNECTED (not in U6 typeclass top; TB decoy only)
LEGACY_SYNTHETIC_STATUS  = DISCONNECTED

PRIMARY_UNKNOWN          = TYPE_CLASS scanner as ONE candidate owner into scorer/Top-K?
RESULT                   = PASS
EVIDENCE_CLASS           = HOST_MODEL + XSIM + OOC_SYNTH
FIRST_DIVERGENCE         = none
VIOLATED_INVARIANT       = n/a

N_QUERIES                = 12 confirmation + protocol (empty, exact-K, stall, reset, poison, cap8)
N_CLASS_SCANNED          = 443
MAX_REAL_CANDIDATES      = 47 (leak check)
MAX_CLASS_ID             = 443 catalog; Top-K observed >255 (duct 256+, exact8 427)
OVERFLOW_PROPAGATION     = cap8 leak_check ovf=1 emit=8 trunc=39 latched
HOST_SEMANTIC_COUNTERS   = 0

TOPK_ID_SEMANTICS        = CLASS_ID  (heap_id[15:0]=CLASS_ID; [31:16]=0)

OOC_LUT                  = 5916
OOC_FF                   = 1134
OOC_BRAM                 = 0
OOC_DSP                  = 0
OOC_WNS                  = -4.103 ns @10 ns estimate (heap path)
OOC_TNS                  = -3561.980 ns
OOC_NOTE                 = not full-chip fit; HD.CLK_SRC unset; do not conclude SoC timing

CLAIM_ALLOWED            = The FPGA-owned TYPE_CLASS masked-conjunctive retrieval path is the
                           single authoritative candidate source feeding the production scorer
                           and exact Top-K path, with bit-exact class/materialization/score
                           identity in XSim.
CLAIM_NOT_ALLOWED        = NLU, general semantic reasoning, learning PASS, Q-head PASS,
                           LM generation, U6 silicon TYPE_CLASS retrieval, board PASS,
                           Gate14 PASS, full-chip co-fit, OOC timing closure

BIT_BUILD                = NO
PROGRAM                  = NO
REPROGRAM_AGAIN          = NO
GATE14_PASS              = NO
U5Q_RAW                  = FAIL immutable
U6_OLD_NID_PROFILE       = historical XSim only
U7A                      = CLOSED until this publish, then NEXT
U7                       = CLOSED
U8                       = CLOSED
NEXT                     = U7A-ROOT-B-REACHABILITY-REAUDIT-00
```

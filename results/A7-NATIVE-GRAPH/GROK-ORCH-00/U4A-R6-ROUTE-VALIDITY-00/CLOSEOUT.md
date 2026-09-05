# CLOSEOUT — U4A-R6-ROUTE-VALIDITY-00

```text
GATE                 = U4A-R6-ROUTE-VALIDITY-00
BASE                 = 4d8694a21ae425d17bf881e45d35741da4023399
SOURCE_COMMIT        = 884aa8c40daf8b78c0b60c7395937e3e76b77fa6
RTL_EDIT             = YES
FILES_CHANGED        = rtl/native_graph/query/a7ng_query_struct_extract.sv
                       rtl/native_graph/query/a7ng_route_valid_gate.sv
                       rtl/native_graph/query/a7ng_query_struct_ooc_top.sv
                       results/.../U3Q-R3-STRUCTURED-QUERY-FEATURE-00/twin.py
                       results/.../U4A-R6-ROUTE-VALIDITY-00/*
QUERY_LAW            = qse-v1-lexicon-hdc-00  KEY VALUES UNCHANGED
VALIDITY_LAW         = bind-state {k*_valid, k*}; NOT (key != 0)
INDEX_VALIDITY       = valid=0 → do not insert that table
QUERY_VALIDITY       = valid=0 → do not probe that table
BIT_BUILD            = NO
PROGRAM              = NO
GATE14_PASS          = NO
COM12                = UNTOUCHED
PERSIST              = CLOSED until this PASS accepted
U4_AXI               = CLOSED
U5                   = CLOSED
RESULT               = PASS
EVIDENCE_CLASS       = RTL_FACT + HOST_MODEL
FIRST_DIVERGENCE     = none
VIOLATED_INVARIANT   = n/a
NEXT                 = PERSIST-IDENTITY-WIDTH-00
                       (32-bit subj/obj → 16-bit DDR truncation)
                       Then U4-MEM02-AXI-DIRECTORY-00
                       Do not open U5 / BIT / PROGRAM
```

## What changed

Extractor now emits `k0_valid_o..k3_valid_o` from class-bind FFs
(`eh/ih/rh/xh`), latched at fire. Keys, IDs, cue arithmetic, CRC debug,
and host-semantic counters are unchanged.

A combinational `a7ng_route_valid_gate` maps validity → probe/insert
enable and key[11:0] → bucket. It does not test `key != 0`.

Index and query host-model consume those bits. T3 remains a live table
with zero admitted records on the 42-title labeled corpus.

## Evidence

- Twin vs frozen keys: 98/98
- XSim golden: `U4A_R6_RTL_GOLDEN_PASS n=98 match=98`
- XSim protocol: `U4A_R6_PROTOCOL_PASS`
- Host-model six directed queries + fully-unknown: unrelated cand=0
- Relevant recall 1.00 ≥ 0.80
- T3 bucket0 occupancy 0 (was 42 in R5)

## Hard stops still in force

PROGRAM=NO BIT=NO COM12=UNTOUCHED U5=CLOSED GATE14_PASS=NO

# PREREG — LOCAL-WAVE-ORDER-CONTRACT-AUDIT-00

```text
GATE        = LOCAL-WAVE-ORDER-CONTRACT-AUDIT-00
RTL_EDIT    = NO
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN

UNKNOWN     = Does a7ng_topk_wavefront_minheap final ordered Top-8
              (score,id) depend on local presentation order, or only
              on the candidate SET?

WHY         = NG02 COLLECT 37-40 = local ST_SORT 28 + ST_DRAIN 8 + FSM.
              Global ST_CAND inserts wave_score_i[i] with lane=8+i.
              If unique ids make lane unused, skip local ST_SORT is the
              dominant C_L lever (~28 cycles/wave).

H_CANDIDATE = shuffled vs canonical presentation → global (score,id) DIFF=0
H_RIVAL     = presentation order or lane=8+i changes global ranking
FALSIFIER   = any (score,id) slot mismatch after global's own ST_SORT

NOT_THIS_GATE = local ordered-vs-bitonic; C9; beats(); PHYS; score skid
```

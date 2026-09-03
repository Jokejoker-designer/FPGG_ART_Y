# PREREG — CUE-OVERLAP-READY-00

```text
GATE        = CUE-OVERLAP-READY-00
BASE        = e3b730eb116ff10b31fd6c058c3742667968580e
RTL_EDIT    = YES  a7ng_cue_soa_mig_top.sv only
BIT         = NO
SYNTH_IMPL  = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64

UNKNOWN     = Can one-wave TermGen lookahead remove compute backpressure
              without changing exact TopK / C9 / OUT?

CHANGE      = wf_cons_ready drops core_batch_ready and !global_topk_busy.
              Those gates stay at SCH_ISSUE.
              sched_idle && tg_ready remain on accept (single rec_hold).

NOT_THIS_GATE =
  TopK / beats() / heap / Fold6 / scorer / DDR protocol
  LM / C9 / epoch / oracle / PHYS / WAVE
  Top8 skid buffer
  GLOBAL-SORT-FINAL-ONLY
  bitstream / program

H_CANDIDATE = TermGen(N+1) overlaps Local/Global(N); BLK_HOLD and T_QUERY fall;
              wave_accept=tg_complete=core_issue=global_merge=4; drop/dup/overwrite=0
H_RIVAL     = overlap creates drop/dup/overwrite or T_QUERY does not fall
FALSIFIER   = C9/OUT change; TopK edit; T_QUERY not down; any of drop/dup/overwrite != 0
UNIT        = P3P4 MIG_XSIM N=64 PHYS=4 + C9 frozen fullchip
```

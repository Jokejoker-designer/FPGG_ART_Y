# CLOSEOUT — G14-OPEN-METRIC-00

```text
BIT_SHA                = F24150BDE6F69080B3C5865386C49F6F02300782FFB4037FAF044BB2099840F7
PROGRAM_COUNT          = 1
PROGRAM                = NO
RTL_EDIT               = NO
BIT_BUILD              = NO
ORACLE_CHANGE          = NO

P3_LANE_UTIL           = INCONCLUSIVE / OPEN
P4_DDR_STALL           = INCONCLUSIVE / OPEN
M7_DDR_BYTES_PER_QUERY = INCONCLUSIVE / OPEN
M10_SCALE_800K         = not_proven / OPEN   (silent N/A refused)
C5_CEILING_VS_THROUGHPUT = PASS (ceilings POST_ROUTE; sustained NOT_MEASURED)

OPEN_METRIC_BEFORE     = 5
OPEN_METRIC_AFTER      = 4
UNSUPPORTED_CLAIMS     = 8 listed in RESULTS.md
GATE14_PASS            = NO
NATIVE_V1_MINI_AI_BOARD_PASS = NO

LAW_GAPS               = 0
XSIM_GAPS              = 0
BOARD_GAPS             = 0
METRIC_GAPS            = 4
FAIL                   = 0
```

H_CANDIDATE (all five close from existing evidence) **FALSIFIED**.
H_RIVAL **SUPPORTED**: this UART cannot measure stall/bytes/util; 800k was never run;
ceilings are not throughput.

Next (human):

1. KEEP M10 OPEN, or sign `AUTHORITY_AMENDMENT_PROPOSAL.md` Option B.
2. Remaining P3/P4/M7 stay OPEN until a **new** observability design is authorized
   (not F24150BD; PROGRAM still NO on this SHA).
3. No 56-box pass reconciliation until METRIC_GAPS=0 or checklist amended and re-ticked.

# RAW EVIDENCE MANIFEST — U3Q-R3

```text
WORKTREE   = D:\Jetking_sem4\SEM_4\arty-a7-online-lm-g14-preboard-00
BRANCH     = grok-orch/v31-canonical-00
HEAD_START = 38b22269e9a5d8c1fae377e48af4869a2822c879
CURSOR_WT  = not used (arty-a7-online-lm-close664 forbidden)
MIG        = quarantined, not committed
```

## Commands / exit codes

| command | exit |
|---------|------|
| python gen_lex_svh.py | 0 |
| python quality_audit.py | 0 |
| vivado -source run_xsim.tcl (hold-test TB bug) | 1 |
| vivado -source run_xsim.tcl (after TB hold fix) | 0 |
| vivado -source build_ooc.tcl | 1 (regex); util DSP=0 PASS |

## SHA256

```text
96225108FE8E434F2B0269A826BB0A6008AEE951FF6CCD27D3F7B9D1CEC84CBF  a7ng_query_struct_extract.sv
135E4DA866D4BF978C9DF3BC4F4FCE753C9E94B1A7F36823D2DEC464ECA6E584  a7ng_query_struct_ooc_top.sv
416CE453E5A34438C0F320AC248E5A2F2777E25C02C4B847BDB44C2415DBFB8F  qse_lexicon.svh
12ADAFB8B3A2AD379DD0346E10E4D7F149971B6450B5B4C5595B72F8329877FE  _PREREG.md
62F6CD663A234D419E5AA4CEC89AAFF7DB7F8AF0EEECC8344C051DF37C7EBC2F  METRICS.json
10586BF54231A334BD4CBAD3F5A6D05AFD75BB4D1BBC22D416289367BC776634  xsim.log
28875DCE7A82D6E06B8286014BFB81E5FD691790812C25D9A4994055D411AD57  xvlog.log
FADD58FBF6A8BA3FA206ECDBE56FD33A9A7EEF0829D69F84940991FD9BC6DEB0  report_utilization_ooc.rpt
```

## Exact metrics

entity_stab=0.9667 (29/30) intent_stab=1.0
same_ent=1.0 intent_diff=1.0 unrelated=0 perturb=1.0 adv=0
sentinel_eid=0 recall@16=0.952 recall@64=0.952
n_host=0 DSP=0 LUT~2437 FF=201

## Verdict

PASS (frozen thresholds). Residual class: lowest-id multi-entity (`condenser pump`).
U5=CLOSED BIT=NO PROGRAM=NO COM12=NO

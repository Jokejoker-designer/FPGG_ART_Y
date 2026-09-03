# RESULTS — G14-PREBOARD-CLOSURE-00 epoch identity

```text
PROGRAM = NO
GATE14_PASS = NO
BOARD_PASS = NO
NATIVE_V1_MINI_AI_BOARD_PASS = NO
READY_TO_PROGRAM = NO
```

BASE_SHA = `1e71eb12b12be4405fa7aa490b2da04782ad18eb`

## Verdict of this bag

Root cause of the patch treadmill is **missing epoch object**, not a weak
`header_ok` clause. See `ROOT_CAUSE.md`.

XSim (this bag):

```text
EPOCH_IDENTITY_XSIM_PASS fails=0
PBOOT_DIRTY_DDR_XSIM_PASS fails=0
C9_LEARNED_PRIOR_GRAPH_XSIM_PASS fails=0 facts=20
HOLD_A C9 = 8382238122802120  (oracle, not retargeted)
```

| Hypothesis | Result | Evidence class |
|------------|--------|----------------|
| H1 illegal cookies → gen=1 | PASS | XSIM |
| H2 TRESET BUMP hides old vis_w | PASS | XSIM |
| H3 wrap TRESET is REBIRTH (gen=1, BRAM empty, DDR[0] illegal) | PASS | XSIM |
| H4 persist_gen_fast shares ng_epoch_legal | RTL inspect; not a C9 SoC instance | ENGINEERING |

Dirty-boot silicon reconstruction remains closed (ONES/TWO_FREE dseq=20, A0–A3 hit).
Wrap forget, which P0 left open, is now I9 on the store.

Full-chip SoC XSim (hex cwd = `tests/xsim`):

```text
GATE14_C9_SOC_COFIT_XSIM_PASS fails=0
C9_PACK_A/U/C/B=8382238122802120/8786858483828180/2322832182208180/8382438142804140
LM_OUT_A/U/C/B=653/689/237/60
FIRST_DIVERGENCE=NONE
```

First full-chip attempt with cwd=bag is **not** a law fail: C9 matched, OUT=0
because `a7lm06_wmem.hex` was missing.

`persist_gen_fast` unit: `PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS fails=0 CELLS=7`
(WRAP rebirth GEN=1).

Unique bit impl is a separate bag `G14-EPOCH-REBIRTH-BIT-00`. PROGRAM=NO.

Not this root: WDMA pulse, AXI owner lifetime, digest identity, 16-bit DDR key
truncation.

Silicon replay: **not done**. PROGRAM=NO.

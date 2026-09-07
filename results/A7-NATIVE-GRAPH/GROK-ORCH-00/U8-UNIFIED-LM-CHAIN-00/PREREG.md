# PREREG — U8-UNIFIED-LM-CHAIN-00

Written **before** any U8 RTL. Phase A is identity audit only.

```text
GATE   = U8-UNIFIED-LM-CHAIN-00
HEAD   = 2984b221eee294cc45301be76e562520eb5dce5b
U7     = PASS XSim 8931717 (DEPTH=32 working set)
LAW    = LEARN_KEY_CLASS_CONTEXT_V1   (learn key; not LM ctx)
QHEAD  = NO
BIT    = NO
PROGRAM= NO
```

## Blueprint U8 (authority, not chat)

```text
real unified Top-K
→ ctx write
→ exactly one start_fwd
→ LM-06 active (P_LM = 802,816)
→ exactly one done
→ pred
→ FPGA response

host final-answer = 0
host next-token   = 0
weight write during teacher-off = 0
```

Original DAG also said frozen OUT remains `653 / 689 / 237 / 60` and
HOLD_A C9 = `8382238122802120`. Those are **NID-era C9 silicon** facts
on bit `1F0F2ABB`. They are not automatically TYPE_CLASS facts.

## Hard stops this gate must not violate

- Do not stuff CLASS_ID into graph NID.
- Do not pick first member as canonical.
- Do not retarget HOLD_A oracle.
- Do not open Q-head.
- Do not BIT/PROGRAM.
- Do not invent an LM token mapping because it is convenient in RTL.

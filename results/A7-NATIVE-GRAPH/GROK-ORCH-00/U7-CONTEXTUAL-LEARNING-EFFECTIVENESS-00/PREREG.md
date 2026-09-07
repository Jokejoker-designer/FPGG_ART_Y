# PREREG — U7-CONTEXTUAL-LEARNING-EFFECTIVENESS-00

Written **before** the confirmation XSim run. Reward sequences are ordinal
over FPGA Top-K **valid** CLASS_IDs (pads skipped). TB does not inspect
CLASS_ID to choose a reward.

```text
GATE   = U7-CONTEXTUAL-LEARNING-EFFECTIVENESS-00
HEAD   = e133c2805b59c7cb631e99be82f6c5ca7bb528dd
LAW    = LEARN_KEY_CLASS_CONTEXT_V1
STORE  = pri += scalar_reward  (G1 legal {-3..+3})
G2     = delta = (reward * 256) ASR 8 = reward for legal magnitudes
HEAP   = valid > score > id< > lane<
U6     = UNCHANGED learn=0 control
QHEAD  = NO
BIT    = NO
PROGRAM= NO
```

## Frozen RTL prior law (not invented)

`a7ng_learned_prior_store` adds `upd_rew` (G2 `out_reward` = G1 scalar)
into `pri` via sat8. G2 `delta_o` equals that scalar when
`native_conf=256`. Grade `PRIOR_AFTER = PRIOR_BEFORE + reward`.

## Frozen U6 gold used as baseline (not dynamic inspection)

install chiller QSE: eid=1 iid=1 rid=0 xid=0 ev=1 iv=1 rv=0 xv=0
baseline Top-K valid: 65,66,67 scores 16,16,16 (heap id tie-break)

chiller QSE: eid=1 xid=0 ev=1
baseline Top-K[0:7]: 57,58,59,60,61,62,63,64 scores 8

water chiller QSE: eid=1 xid=1 ev=1 xv=1
baseline Top-K starts 58,60,62,64 scores 16

leak chiller = HELD_OUT (never trained)

## Preregistered ordinal schedules (valid Top-K index)

```text
SCHED_A_INSTALL = [-1, +2,  0]   # 65 demote, 66 promote, 67 neutral
SCHED_B_INSTALL = [+2,  0, -1]   # shuffled
SCHED_ZERO      = [ 0,  0,  0]
SCHED_CHILLER58 = [ 0, +2,  0, 0, 0, 0, 0, 0]  # gold heap[1]=58
```

## Predicted after SCHED_A (if lookup-before-heap is causal)

```text
65: 16 + (-1) = 15
66: 16 + (+2) = 18
67: 16 +  0   = 16
Top-K valid: 66, 67, 65
```

If store updates but Top-K stays 65,66,67 → FAIL LEARNING_NOT_CAUSAL_TO_RANKING.

Same-key second SCHED_A is still ordinal over the **current** valid Top-K
(after the first causal flip that is 66,67,65), not a host remap onto the
original 65,66,67 order:

```text
66: 2 + (-1) = 1   score 17
67: 0 + (+2) = 2   score 18
65: -1 +  0  = -1  score 15
Top-K valid: 67, 66, 65
store commits: 6 (3 keys × 2 updates, no new allocation)
```

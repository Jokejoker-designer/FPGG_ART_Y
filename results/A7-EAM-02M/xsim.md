# A7-EAM-02M xsim

**Status:** `A7EAM02M_XSIM_PASS`  
**Law:** `eam02m-bind-v1`  
**Simulator:** Vivado 2026.1 xsim  
**DUT:** `eam02m_core` wrapping frozen `eam01r_core` (not modified)

## What passed

| Test | Result |
|------|--------|
| OPEN episode 0, value token `0xA7` | PASS |
| BIND two far cues (d≥24) → same `episode_id`, `cue_n=2` | PASS |
| Second episode, two cues, no cross-talk | PASS |
| TEACHER_OFF then BIND → NACK `1` | PASS |
| PROBE A and B: HIT, same episode, same value, d=0 | PASS |
| 1-bit flip of cue A: HIT, d=1 (01R theorem) | PASS |
| Unrelated key d≥24: MISS | PASS |
| Rebound same cue: `BIND_COLLIDE`, `cue_n` unchanged | PASS |

Not claimed: unseen paraphrase retrieval (that is 03E).

## Note

First unrelated candidate `sep_key(20)` sat at d=8 from a stored cue and was an illegal “unrelated”. TB now searches for d≥24 against all bound cues.

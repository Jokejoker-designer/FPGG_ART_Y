# A7-EAM-02M closeout — FROZEN

**Verdict:** `A7EAM02M_PASS` / **FROZEN / BOARD_PASS**  
**Frozen claim:** FPGA-native post-bitstream multi-cue episodic binding and teacher-off exact recall.

Do **not** add “semantic” or “generalization” to this claim.

## Scope

```
cue A ─┐
       ├──> episode 0     (Hamming(A,B)=29, not one ball)
cue B ─┘
```

Silicon: FPGA allocates `episode_id`, binds two **different** UTF-8 cues, TEACHER_OFF, both recall episode 0 / token `0xA7`. Unrelated miss d=28. 1-bit perturbation hit d=1. Bind after teacher-off NACK.

xsim also: second episode / no cross-talk, rebound collide, unrelated only legal if d≥24.

## Erratum

NACK after teacher-off may keep stale `hit=1`. Authority: `kind=0x9E` + `nack_code=1`. Not a functional blocker.

## Next

A7-EAM-03E-A0 — encoder-only SAME/DIFF geometry. No 01R glue until that gate passes.

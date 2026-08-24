# A7-EAM-02M silicon

**Verdict:** `A7EAM02M_PASS` / **FROZEN**  
**Frozen claim:** FPGA-native post-bitstream multi-cue episodic binding and teacher-off exact recall.  
**Not in the claim:** semantic, generalization, unseen paraphrase.  
**Device:** Arty A7-100 `xc7a100t` Digilent `210319BE776EA` COM12 115200  
**Bit:** `arty_a7_eam02m.bit` SHA `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696`  
**Timing:** WNS +0.788 ns, WHS +0.026 ns @ 100 MHz  
**Util:** LUT 1704, FF 2332, BRAM tile 52, DSP **0**

Frozen LM-00/05/06c3 and EAM-00B/01R bits **unchanged**.

## Ladder (host sent strings, FPGA folded + bound)

| Step | Result |
|------|--------|
| PING `M2M` | 0x81 |
| OPEN value `0xA7` | episode **0** |
| BIND_TXT "FPGA nào đang dùng?" | episode 0, `cue_n=1` |
| BIND_TXT "Board hiện tại dùng chip gì?" | episode 0, `cue_n=2` |
| TEACHER_OFF | 0x93 |
| PROBE_TXT A | HIT episode **0**, token 0xA7, d=0 |
| PROBE_TXT B | HIT episode **0**, token 0xA7, d=0 |
| PROBE_TXT unrelated | MISS, best d=28 |
| PROBE 1-bit flip of fold(A) | HIT episode 0, d=1 |
| BIND after teacher-off | NACK code 1 |

Fold Hamming(A,B)=29 — two **different** exact cues, not a semantic ball.

## What this is not

An unseen paraphrase of either sentence is **not** required to hit. That is A7-EAM-03E.

Cosmetic: NACK reply after teacher-off can leave the previous probe's `hit` flag set. Kind is `0x9E` and nack code is 1; the ladder keys on those, not the stale hit bit.

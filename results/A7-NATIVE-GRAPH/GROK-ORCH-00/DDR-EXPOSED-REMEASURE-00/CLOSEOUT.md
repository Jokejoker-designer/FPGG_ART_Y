# CLOSEOUT — DDR-EXPOSED-REMEASURE-00

```text
RTL_EDIT     = NO
SYNTH_IMPL   = NO
BIT          = NO
PROGRAM      = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD
PHYS         = 4
WAVE         = 16
N            = 64

waves / AR / beats / bytes        = 4 / 4 / 64 / 1024
R backpressure / FIFO_HW / OUT_HW = 0 / 1 / 1
RRESP / RLAST / RID               = 0 / 0 / 0

C_D_SERVICE_MAX                   = 44   (44/42/42/42 recurring)
C_D_EXPOSED                       = W0 45; W1–W3 9  (startup occupancy)
II_STEADY                         = 46   (= C_D_SERVICE + ARM)
II_OBS last-wave                  = 51
FINAL_G_TAIL                      = 122  (last_g 310 − ACC_W3 188)
T_QUERY elig                      = 310  (unchanged)
AR_TO_FIRST_R                     = 24 every wave
LAST_R → NEXT_AR                  = 6 / 6 / 7  (not a large launch gap)

FROZEN_C9                         = HOLD (not re-run)
FROZEN_OUT                        = HOLD (BASE 653/689/237/60)

DDR_EXPOSED_REMEASURE             = PASS
NEXT                              = DDR-WAVE-PINGPONG-00
NOT_NEXT                          = GLOBAL-TAKE-SIFT-00
NOT_NEXT                          = DDR-LAUNCH-DECOUPLE-00
```

C_D_EXPOSED occupancy after fill is small. That does **not** mean DDR
is off the II. Fetches are serialized (`MAX_OUT=1`, one plane buffer).
II_STEADY=46 is recurring FETCH_SERVICE.

TAKE-SIFT cannot move II (intermediate C_G is 16–23). Launch-decouple
does not apply (6–7 cycles after LAST_R). Ping-pong (fetch N+1 during
fetch N) is the II attack. **Not implemented in this gate.**

Do not program. Do not merge as Gate14 pass.

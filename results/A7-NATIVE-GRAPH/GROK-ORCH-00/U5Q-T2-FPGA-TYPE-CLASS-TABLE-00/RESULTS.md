# RESULTS — U5Q-T2-FPGA-TYPE-CLASS-TABLE-00

```text
XSIM = U5Q_T2_TYPECLASS_TABLE_PASS
OOC  = PASS (utilization + 10 ns estimate; not full-chip fit)
```

Frozen:

```text
TYPECLASS_TABLE_SHA256   = B5958D4ADBE96F1D4432915E767BA2C4806594DBB291BBFFBEC95FE588E436C2
CLASS_ID_MAPPING_SHA256  = CEA2B9710D4D5F229BC341DF790E557B20F023F98161464C6C79BEADAE6BD68B
TC_N                     = 443
CLASS_ID                 = 16'd1 .. 16'd443  (not from NID)
```

T1 confirmation CLASS_ID streams reproduced (XSim). No-answer n=0. Cap8 leak_check overflow emit=8 trunc=39. CLASS_ID>255 on duct query. Stall + reset mid-scan OK. QSE chiller fields match T1 then same Top-29.

OOC xc7a100t (do not conclude SoC fit):

| LUT | FF | BRAM | DSP | WNS@10ns | TNS |
|-----|----|------|-----|----------|-----|
| 137 | 126 | 0 | 0 | +3.089 ns | 0 |

ROM implemented as LUT (512x*). Cycles/query ≈ TC_N + handshake ≈ 450 at one class/cycle.

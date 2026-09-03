# PHASE2-G2-CONTEXT-DELTA-RTL-00 — preregistration (copied before data)

**PROGRAM=NO.** Copied/referenced before XSim/OOC. Do not lower the frozen table after a miss.

Source preregister (Cursor written gate, SHA frozen):

```text
D:\Jetking_sem4\SEM_4\arty-a7-online-lm\results\A7-NATIVE-GRAPH\PHASE2-SERIAL-G2-PREREG-00\PREREGISTER.md
SHA256 DDEB61064C20A36EC6856EF5EC52C69A4B7F30DA4871C3F536025C6792DA9DF0
```

G0 law SHA256: `BE892A777F2616F169AFB72D68399FF0150C817A77A20AB249CBAC70512A8E86`  
G1 resolver RTL SHA256 (do not modify): `2219DA29C265D2461ED30783EBEA0F0649050B9B6E5F6EAFDB8F1C4E05F3F5F7`  
Prompt SHA256: `48D4E35CADFE0A5DA0C67CDC3577B0B47EAF2CAB448C32963DD62CFE81E15449`

## One unknown

Does an FPGA-only delta engine, driven exclusively by a legal G1 consume record, produce the exact `a7ng-learn-ctx-v1` signed delta for every registered row and remain lossless under downstream backpressure without exposing host-writable delta/index/address authority?

## Frozen table (HS-17)

| reward | native_conf | expected delta |
|-------:|------------:|---------------:|
| +3 | 256 | +3 |
| −3 | 256 | −3 |
| +1 | 0 | 0 |
| +1 | 255 | 0 |
| +3 | 65535 | **+767** (never +768) |
| −3 | 65535 | −768 |
| 0 | 256 | 0 |

Equation: `delta = sat16( signed32(reward) x signed32(native_conf) ASR 8 )`.

## Negative control

Do not use `a7ng_wm00_learn_upd` (`delta_i`) as this DUT.

## Non-claims

Not G3, persist, Teacher-Off, Gate 14, BOARD_PASS, PROGRAM, full-chip.

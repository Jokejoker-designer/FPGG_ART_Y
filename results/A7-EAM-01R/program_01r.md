# A7-EAM-01R board program

**Not a close.** Router silicon only. No LM-06 glue. No 02Q semantic claim.

| Item | Value |
|------|--------|
| Bit | `build/out/arty_a7_eam01r.bit` |
| SHA-256 | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` |
| Device | xc7a100t_0 / Digilent `210319BE776EA` |
| UART | COM12 115200 |
| Board route | WNS **+0.908** TNS 0, WHS **+0.019** THS 0 |
| CFGBVS | VCCO / 3.3 |
| Program | `A7_EAM01R_PROGRAM_PASS` startup HIGH |
| PING | `A7EAM01R_PING_PASS` reply `5A 81 … 52 31 52` (`R1R`) |

Frozen bits still match: `arty_a7_lm00`, `lm05`, `lm06c3`, `eam00b`.

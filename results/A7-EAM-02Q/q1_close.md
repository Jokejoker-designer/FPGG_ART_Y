# A7-EAM-02Q Q1 encoder — silicon twin

**Not a semantic close.** FPGA Q1 is bit-exact with the frozen host map. PARA/UNREL still have no LM-06 hidden dumps.

| Item | Value |
|------|--------|
| Law | `eam02q-q1-rh-v1` seed `0x0EA10201` |
| xsim | `A7EAM02Q_XSIM_PASS` 16/16 twin + encode→01R |
| Bit | `build/out/arty_a7_eam02q.bit` |
| SHA-256 | `507DB68857ACA140FF2E5C6956BF5489CE823B55BB0893CB04770A20FD55CBDA` |
| Route | WNS **+0.169** TNS 0, WHS **+0.023**, **DSP 0** |
| Program | `A7_EAM02Q_PROGRAM_PASS` Digilent `210319BE776EA` |
| PING | `Q1R` |
| Silicon ENC | 4/4 keys match host (`0`, `+1`, patterned, ramp) |
| MAP_H / PROBE_H | miss then HIT `d=0` token `0xA1`; far hidden miss |

Host never sends a Hamming winner. Q2 stays closed. LM-06 not glued.

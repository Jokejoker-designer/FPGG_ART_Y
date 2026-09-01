# P2-CAUSAL-LEARN-FAST-SERIAL-TOPK-01 — RESULTS

Parent FAST-00: **PASS_FUNCTIONAL / FAIL_PHYSICAL** (LUT=3869 WNS=-2.277). That bag is preserved.

DUT SHA-256: `2177073D4103F7971116E5F3C48FE2A33F8E9BC7FDDCA317AD2A3AE156F70EF6`  
G1 (unmodified): `2219DA29C265D2461ED30783EBEA0F0649050B9B6E5F6EAFDB8F1C4E05F3F5F7`  
G2 (unmodified): `0614386298F31DC6A5EB456959290F9C6ADDC899FBF91F8CD49BB5A3D2BBA800`  
TB (unchanged vs FAST-00): `167F5C6D3052F3702A75ABBC3146F21F78536143440E5D8223057777FF408767`

Vivado 2026.1 (SW Build 6511674). `xc7a100tcsg324-1`. Clock **12.5 MHz / 80.000 ns**.  
`PROGRAM=NO`. No COM12/JTAG/bit/full-chip. No G4. Full-chip TopK not instantiated.

## Unknown

Can sequential scan + iterative Top-8 (minheap comparator: higher score, then lower id) replace the combinational 8-sort, keep four-arm C3/C7/C9 bit-exact, and meet LUT<=800 FF<=800 BRAM/DSP=0 WNS/TNS/WHS/THS clean?

## XSim

Same TB / same four-arm oracle as FAST-00. `CAUSAL_LEARN_FAST_XSIM_PASS fails=0`

| Arm | A_hold K* | B_hold K* | C7 | vs FAST-00 |
|-----|-----------|-----------|----|------------|
| positive +3 | r3/39 | r2/42 | Δ=+3 | **bit-exact** |
| negative −3 | r3/39 | r3/36 | Δ=−3 | **bit-exact** |
| unrelated +2 | no K* | identical 8 ids+scores | Δ=+2 | **bit-exact** |
| contradiction FPGA | r3/39 | r3/33 | Δ=−3 | **bit-exact** |

Host: `query_id` + reward/echo only.

## OOC

Attempt 1 (collect-then-insert, extra col/heap arrays): LUT=637 FF=**1187** miss FF<=800. Timing clean WNS=+70.096. Reports kept `ooc_*_attempt1*`.

Attempt 2 (one-at-a-time scorer issue + insert into `topk_*` in place):

```text
LUT=559  (LUTRAM=0)
FF=634
BRAM=0 DSP=0
WNS=+69.879 TNS=0 WHS=+0.098 THS=0
control_sets reported in ooc_control_sets.rpt
```

Target `LUT<=800 FF<=800 BRAM/DSP=0 timing clean`: **met**.

FAST-00 combo sort LUT 3869 / WNS -2.277 → this gate LUT 559 / WNS +69.879.

## Not claimed

G4 persist, G5 Teacher-Off, Gate 14, BOARD_PASS, PROGRAM, SoC instantiate, `pred=664` as G3 evidence.

STOP for Codex audit.

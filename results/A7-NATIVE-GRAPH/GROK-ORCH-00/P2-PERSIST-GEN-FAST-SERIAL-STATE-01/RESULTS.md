# P2-PERSIST-GEN-FAST-SERIAL-STATE-01 — RESULTS

**PROGRAM=NO.** Fast / no-MIG. No COM12 / JTAG / bit / full-chip / G5 / Teacher-Off.  
XSim ≠ board. UNIT = mapping. Host reward-only.

Parent FAST-00: **PASS_FUNCTIONAL / FAIL_PHYSICAL** (LUT 1272 / FF 1066 / WNS +69.929). That bag and its two FAIL logs are not overwritten.

## Unknown

Can serial C8 fold + sequential stamp/state memory (≤1 BRAM) keep the seven-cell oracle bit-exact vs FAST-00 final log and meet LUT≤1000 FF≤1000 BRAM≤1 DSP=0 with clean timing?

## Source SHA

| File | SHA256 | Note |
|------|--------|------|
| G1 | `2219DA29…F3F5F7` | **unchanged** |
| G2 | `06143862…BBA800` | **unchanged** |
| G3 | `2177073D…F70EF6` | **unchanged** |
| DUT this gate | `D1BF0340…D4DAC9` | serial fold + `ws_mem` |
| FAST-00 DUT (bag) | `37550110…5B4084` | preserved |

## XSim (bit-exact vs FAST-00 closing log)

`PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS fails=0 CELLS=7`  
`unit_xsim.log` SHA `A68099ED…FE01E2`  
Wall sim time 211960 ns (FAST-00 was 162040 ns). Extra cycles accepted.

| Cell | This gate | FAST-00 final |
|------|-----------|---------------|
| FLUSH_RELOAD | rank=2 score=42 GEN=1 SDIG=`0000000001000001` reload same | same |
| FREEZE | ACK_DROP=5, C8/C9 unchanged | same |
| TRAIN_RESET | GEN 1→2 Ascore=39 | same |
| RUN_B_NE_A | ADIG=`0000000001000001` BDIG=`0000001008030208` Bscore=42 A=39 | same |
| GEN0 | GEN=1 KAscore=39 | same |
| WRAP | GEN=6 wimm=1 Ascore=39 | same |
| POWER | GEN=1 rank=2 score=42 | same |

### Digest latency (measured)

| Event | `dig_cyc_o` |
|-------|-------------|
| learn fold (P_UPD, 16 slots × 2) | **32** |
| reload fold (P_DIG, 16 slots × 2) | **32** |

Query adds one RAM-read cycle per candidate (`S_RD`). TRAIN reset does **not** scrub `ws_mem`; `sdig<=0` and `live_gen+=1` make old stamps invisible.

## OOC (`xc7a100tcsg324-1`, 80.000 ns)

```text
LUT  = 700     target <=1000  met  (FAST-00 1272)
FF   = 748     target <=1000  met  (FAST-00 1066)
BRAM = 0.5 tile = 1×RAMB18   target <=1  met  (inferred ws_mem_reg)
DSP  = 0       met
WNS  = +69.404 TNS=0
WHS  = +0.132  THS=0
```

Synth: `ws_mem_reg is implemented as Block RAM`. Hier: RAMB18=1, RAMB36=0.

Timing **clean**. Resource **met**.

## Verdict

**PASS_FUNCTIONAL_PHYSICAL**

Do **not** open G5 / Teacher-Off / full-chip / board. Do **not** program `A0219207…`.  
Do **not** declare §14 or BOARD_PASS. `pred=664` is not C8/C11.

STOP for Codex audit.

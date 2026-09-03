# P2-G1G5-FULLCHIP-COFIT-00 — post-route PROGRAM=NO

**PROGRAM=NO.** No COM12 / JTAG / board / Gate14 close / Teacher-Off / BOARD_PASS.  
XSim ≠ board. AI cannot declare BOARD_PASS.

Codex decide (this bag): **PROCEED_PATCHED_CORE**. Historical `pred=664` stays on old core `29D230FC`.  
Gate-14 candidate core is LN-FIX `75706E2C`. A-FAST exact acceptance **pred=249 / logit0=1623245** (Python). Do **not** force 664.

## One unknown (answered at physical fit, not silicon)

Can G1 resolver + G2 delta + G4 persist backend (1 RAMB18 at synth) + G5 live MODE/ANCH/CFRAME be wired into the accepted GRAPH-PAYLOAD-NORESET Minheap SoC that already owns graph scorer + stream-minheap TopK + **one** TinyGPT LN-FIX, meeting route0 / clean timing / BRAM36≤135 / DSP≤240, without duplicating FAST TopK / scorer / LM, without editing MIG generated RTL / law / WMEM?

**Physical-fit answer: YES on the numeric gates below.** Not Teacher-Off. Not board.

## Exact regressions (this bag; parent logs not overwritten)

| Check | Marker / oracle | Log |
|-------|-----------------|-----|
| AFAST patched | pack `3b392b291b190b09` pred **249** logit0 **1623245** `LN_FIX_AFAST_REGRESSION_PASS` `SEMANTIC_CHANGE_EXACT` | `regr_afast_xsim.log` |
| G1 | `FEEDBACK_RESOLVER_UNIT_XSIM_PASS fails=0` | `regr_g1_xsim.log` |
| G2 | `CONTEXT_DELTA_UNIT_XSIM_PASS fails=0` | `regr_g2_xsim.log` |
| G3 unit only | `CAUSAL_LEARN_FAST_XSIM_PASS fails=0` — **not in SoC** | `regr_g3_xsim.log` |
| G4 | `PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS fails=0 CELLS=7` | `regr_g4_xsim.log` |
| G5 R1 | `TEACHER_OFF_SOC_XSIM_PASS fails=0 CELLS=9 LM_KNOWN` OUT **549/861/549/237** consumed-X=0 | `regr_g5r1_xsim.log` |

## Integration (no second TopK / scorer / LM)

`rtl/native_graph/integrate/a7ng_g1g5_cofit.sv` SHA `802C85CD…`:

- Instantiates unmodified `a7ng_persist_gen_fast` (G4; contains G1+G2) + unmodified `a7ng_teacher_off_glue`.
- Local LUTRAM `ddr_mem[0:31]` for persist stamp (not MIG).
- Glue `p_topk_*` = **graph** minheap ids/scores. C9 pack from graph ids, not persist 16-cand.
- C10 from graph `bind_done` / TinyGPT `pred`. Glue `lm_start` unused (one TinyGPT in `ab_core`).
- Auto `C_FREEZE` after persist boot so MODE 5→8.
- Does **not** instantiate `a7ng_teacher_off_soc_xsim`, `a7ng_causal_learn_fast`, or bitonic `a7ng_topk`.

FINDING (not FAIL): G4 persist still contains its locked internal 16-cand scorer/insert in the netlist. Idle unless glue `C_FIRE`. That is the SHA-locked G4 backend, not a second global TopK.

## Physical gates (post-route DCP → bit)

Slice parse of the impl tcl was **wrong** (`Slice|15360|0` took Fixed as tot → `free=-15360`, `SKIP_BITSTREAM`). Correct parse from `report_utilization_route.rpt` table 2:

```text
SLICE used=15360 tot=15850 free=490
LUT=31914 (logic 29170) LUTRAM=2744 FF=41920
F7=4478 F8=1805
control_sets=2451 min=2394 unused_FF_loc=1576
WNS=+1.276 TNS=0 WHS=+0.008 THS=0  (all user constraints met)
route_err=0  (66340/66340 fully routed)
BRAM36=103  RAMB18 post-route=0  RAMB18 synth=1 (persist ws_mem packed)
DSP=19
CDC rows_unsafe=2 clkgen_falsepath=1 candidate_logic=2  (same FINDING class as GRAPH-PAYLOAD; not bitstream skip)
DRC write_bitstream: 0 Errors
```

| Gate | Threshold | Measured | Result |
|------|-----------|----------|--------|
| route errors | 0 | 0 | PASS |
| WNS | ≥0 | +1.276 | PASS |
| TNS | =0 | 0 | PASS |
| WHS | ≥0 | +0.008 | PASS |
| THS | =0 | 0 | PASS |
| BRAM36-eq | ≤135 | 103 | PASS |
| DSP | ≤240 | 19 | PASS |
| free slices | <64 FAIL, <256 RISK | 490 | PASS (no RISK) |

## Bit (written only after gates PASS)

```text
path=results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-G1G5-FULLCHIP-COFIT-00/arty_a7_ng_native_v1_grok_orch_p2_g1g5_cofit_00.bit
BIT_SHA256=2E18B1440791D4554A3DD863AAC35A6150B6B2302CF23494D09649BFAAB225C4
bytes=3826011
PROGRAM=NO
```

Parent GRAPH-PAYLOAD-NORESET bit **preserved**:

```text
9B2D67C3E5A63FF52F6AD41CC069C48A68C0A52A7A3C2AE9FF2A4102BF84E199
```

## Vs GRAPH-PAYLOAD-NORESET (9B2D67C3)

| Metric | GRAPH-PAYLOAD | COFIT | Delta |
|--------|---------------|-------|-------|
| LUT | 32842 | 31914 | −928 (packing; not a resource close) |
| FF | 41954 | 41920 | −34 |
| Slice used | 15159 | 15360 | +201 |
| free slices | 691 | 490 | −201 |
| control sets | 2452 | 2451 | −1 |
| WNS / TNS | +1.276 / 0 | +1.276 / 0 | 0 |
| BRAM36 / DSP | 103 / 19 | 103 / 19 | 0 |
| core | 29D230FC | 75706E2C | LN-FIX |
| A-FAST accept | historical 664 | 249 / 1623245 | Python match |

free=490 ≥256 → **not RISK**. Not PASS_MATERIAL (≥1000) / not PASS_TARGET (≥2000). Do **not** call resource closure.

## Explicitly not claimed

- Teacher-Off
- Gate14 close
- BOARD_PASS
- Silicon / UART / COM12 / JTAG
- Existence row `NATIVE_V1_EXIST_ROW,pred=664` (old core only)
- Duplicate FAST TopK / second TinyGPT

## STOP

Codex audit / token decision. PROGRAM=NO.

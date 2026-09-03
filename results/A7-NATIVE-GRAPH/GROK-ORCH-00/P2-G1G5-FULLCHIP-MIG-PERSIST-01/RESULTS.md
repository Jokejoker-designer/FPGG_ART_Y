# P2-G1G5-FULLCHIP-MIG-PERSIST-01 — post-route PROGRAM=NO

**PROGRAM=NO.** No COM12 / JTAG / board / Gate14 / Teacher-Off / BOARD_PASS.  
XSim ≠ board. Parent COFIT bit `2E18B144…225C4` **preserved**.

## Unknown (answered at physical fit, not silicon)

Replace COFIT LUTRAM persist mock with FPGA-owned AXI/MIG records on `NG_DDR_PRIOR_BASE`, existing owner mux, C7 ready only after B OKAY, reload only after R+RLAST OK, G4 7 cells with BRAM kill / DDR retained.

**Physical-fit answer: YES** on the numeric gates below. Not Teacher-Off. Not board. Not BRAM-loss silicon proof (that needs PROGRAM).

## Exact regressions (this bag)

| Check | Marker |
|-------|--------|
| G1 | `FEEDBACK_RESOLVER_UNIT_XSIM_PASS` |
| G2 | `CONTEXT_DELTA_UNIT_XSIM_PASS` |
| G3 unit | `CAUSAL_LEARN_FAST_XSIM_PASS` — not in SoC |
| G4 LUTRAM unit | `PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS` CELLS=7 SHA `D1BF0340` unedited |
| G4 via AXI | `PERSIST_AXI_MIG_XSIM_PASS` CELLS=7 BP=1 BRESP=1 RRESP=1 RLAST=1 wrerr=1 rderr=1 |
| Collision | `PERSIST_AXI_COLLISION_XSIM_PASS` dual=0 |
| AFAST | pack `3b392b291b190b09` pred **249** logit0 **1623245** |
| G5 R1 | OUT 549/861/549/237 CELLS=9 `LM_KNOWN` |

`MIG_PERSIST_REGRESSION_PASS` (unit markers above; AXI re-run after RRESP cell).

AXI 7-cell: FLUSH_RELOAD / FREEZE / TRAIN_RESET / RUN_B_NE_A / GEN0 / WRAP / POWER (BRAM kill, DDR retained, A rank=2 score=42). Freeze window: ACK_DROP=5, no C7, no `awvalid` for 16 cycles. Printed `awc=1` is **lifetime** count from the pre-freeze C7 commit, not a freeze write.

## Integration

`a7ng_persist_axi_bridge.sv` `E95B34AC…` replaces cofit LUTRAM.

- Slot `i` → `NG_DDR_PRIOR_BASE + i*16` (128-bit beat, lower 64 = persist word).
- Write complete / persist `ddr_ack` only after **BRESP==OKAY** (retry ≤3).
- C7 ready only after commit write to slot 31 B OKAY.
- Reload `ddr_ack` only after **RVALID && RLAST && RRESP==OKAY**.
- Existing mux: persist_owner vs boot / WMEM / SOA / graph CDC / WDMA. One-hot.
- G4 persist SHA **unedited**. MIG generated RTL **unedited** (Vivado xci `SYNTHESISFLOW` side-effect restored, not committed).

FINDING: CDC candidate_logic=**3** (COFIT was 2) from persist core_clk↔ui_clk. Same class as GRAPH-PAYLOAD/COFIT, not bitstream skip.

FINDING: POWER `wr=4294967280` is unsigned underflow of `bwr-bwr0` after `rst_n` clears bridge byte counters. Not a data-loss fail. Conservation oracle is A visible rank=2 score=42 after BRAM kill + core reset with DDR model retained (`rd_ok>=16`).

## Physical

```text
SLICE used=15433 tot=15850 free=417
WNS=+1.276 TNS=0 WHS=+0.012 THS=0
route_err=0
BRAM36=103 RAMB18=1  (eq 103.5 ≤135)
DSP=19
CDC candidate_logic=3
gate_pass=1 risk_free=0
```

| Gate | Threshold | Measured | Result |
|------|-----------|----------|--------|
| route errors | 0 | 0 | PASS |
| WNS/TNS | ≥0 / =0 | +1.276 / 0 | PASS |
| WHS/THS | ≥0 / =0 | +0.012 / 0 | PASS |
| BRAM36-eq | ≤135 | 103.5 | PASS |
| DSP | ≤240 | 19 | PASS |
| free slices | <64 FAIL, <256 RISK | 417 | PASS (no RISK) |

## Bit (written only after gates PASS)

```text
arty_a7_ng_native_v1_grok_orch_p2_g1g5_mig_persist_01.bit
BIT_SHA256=F06C6E846369B30AE721E32758BEB56FE0216106024F05948B7A16B20C482489
bytes=3826011
PROGRAM=NO
```

Parent COFIT `2E18B144…225C4` still on disk.

Vs COFIT-00: free 490→417 (−73). Timing identical WNS=+1.276. BRAM36 103, extra visible RAMB18=1 (persist `ws_mem`).

## Explicitly not claimed

Teacher-Off, Gate14, BOARD_PASS, silicon / UART / COM12 / JTAG, BRAM-loss on board.

G5 unit TB `a7ng_teacher_off_soc_xsim.sv` still has LUTRAM `ddr_mem[0:31]` — **not in SoC**, not this bitstream.

## STOP

Codex audit / token. PROGRAM=NO.

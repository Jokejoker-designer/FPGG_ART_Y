# P2-GATE14-C1-UART-RX-COMMAND-01 RESULTS

PROGRAM=NO. COM12=NO. JTAG=NO. BOARD_ACTION=NO.

Parent board run `P2-GATE14-BOARD-PROGRAM-20-R1-00` remains:

`PROGRAM_OK` / `BOARD_EXISTENCE_PATCHED_PASS` / `FAIL_C1_NO_HOST_COMMAND_PATH`

Bit `6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A` was **not** reused or overwritten. `program_count=1` is preserved.

## Verdict

`PASS_BIT_READY_PROGRAM_NO`

New uniquely named bit (not programmed):

```text
bit_path=results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-GATE14-C1-UART-RX-COMMAND-01/arty_a7_ng_native_v1_grok_orch_p2_gate14_c1_uart_rx_command_01.bit
BIT_SHA256=4569115F8076A616733749322AD24B126908CF2A7DFA6B44EFA6CACC0FFAEE8F
PROTOCOL_VER=0x01
```

TEACHER_OFF=not_claimed GATE14_PASS=not_claimed BOARD_PASS=not_claimed

A new human token is required after Codex audits this bit.

## Unknown (one)

Can a small legal UART RX command path, without host semantic authority, let the same FPGA receive TRAIN→persist→FREEZE→exam and emit C0–C11?

**XSim: yes.** Physical: bit ready, PROGRAM=NO. Silicon not claimed.

## Evidence (parent R1, preserved)

Raw UART 112 B SHA `F015A119…CCCEE6`: BOOT / MIG_OK / WMEM_OK / TOPK=PACK=`3B392B291B190B09` / POISON=0 / CORE_DONE / pred=249.

C1 failed because `uart_txd_in` (XDC A9) was `unused_rx`. Cofit auto-issued `C_FREEZE`. No host TRAIN/query/reward/FLUSH/KILL/RELOAD/FREEZE path.

## Architecture (this bit)

```text
uart_txd_in A9
  → a7ng_uart_rx100 (CLK100MHZ, 115200, 2-FF, stop-bit)
  → a7ng_byte_cdc (100 MHz → 12.5 MHz, req/ack 3-flop ASYNC_REG)
  → a7ng_gate14_uart_cmd_rx (SOF A7 14, CRC16-CCITT-FALSE, whitelist 0x01–0x0D, 1-entry queue)
  → a7ng_gate14_cmd_map (TYPE→glue C_*; reward echo vs FPGA txn)
  → a7ng_g1g5_cofit g14_en=1 (auto-freeze off; MODE FPGA-owned)
```

CFRAME TX (SOF C1 11) is the grading authority. ASCII boot lines kept. Host cannot write MODE/idx/delta/address/cue/answer. Live MODE: TRAIN snapshot → 5, FREEZE snapshot → 8.

## XSim ladder

| Gate | Marker | Result |
|------|--------|--------|
| A UART RX | `UART_RX100_XSIM_PASS` | PASS |
| B parser 100k | `GATE14_PARSER_RANDOM_XSIM_PASS n=100000` | PASS |
| C authority | `GATE14_COMMAND_AUTHORITY_XSIM_PASS` | PASS |
| D Gate14-20 UART | `GATE14_20_UART_XSIM_PASS` MODE=8 OUTA=549 UNREL=861 OUTB=237 ckpt=fff | PASS |
| E parent regressions | `GATE14_C1_REGRESSION_PASS` | PASS |

D drove G5 mapping through UART **bytes**, not internal force:

- C1 MODE=5 then MODE=8
- C9 HOLD_A pack `0706050403010002` OUT=549
- UNREL pack `0f0e0d0c0b0a0908` OUT=861
- HOLD_B pack `0f0e0d0c090b080a` OUT=237
- CFRAME checkpoints 0–11 (`ckpt=fff`)

Parent: A-FAST pred=249 logit0=1623245; G1; G2; G3 four arms; G4 seven cells; G5 R1 549/861/549/237; persist AXI/BRESP/RRESP/RLAST; persist CDC; WDMA rel; collision dual=0.

## Physical

```text
route_errors=0
WNS=+1.276 TNS=0.000 WHS=+0.021 THS=0.000
BRAM36=103 RAMB18=1 DSP=19
free_slices=268  (>=64; not <256 RISK)
candidate_logic CDC=0
persist_crit=0
clock-gen falsepath only: c166_raw → clk_pll_i uns=1
```

Parent free=427. This bit 268. UART RX + parser + CFRAME used slices; still above 256.

## Host tooling

`python/gate14_uart.py`: legal encoder, CRC16, refuse forbidden corpus keys, CFRAME decoder.

## Stop

`PASS_BIT_READY_PROGRAM_NO`

Do not open COM12. Do not JTAG. Do not program. Do not recapture. Do not 40-fact. Do not claim Teacher-Off / Gate14 PASS / BOARD_PASS.

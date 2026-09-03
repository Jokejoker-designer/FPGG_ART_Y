# P2-GATE14-C1-UART-RX-COMMAND-01 parent regressions

PROGRAM=NO. Parent bit `6975AB75…F8B39A` not overwritten.

| Test | Marker | Result |
|------|--------|--------|
| A-FAST LN-FIX | `LN_FIX_AFAST_REGRESSION_PASS arm=NEW` pred=249 logit0=1623245 | PASS |
| G1 resolver | `FEEDBACK_RESOLVER_UNIT_XSIM_PASS` | PASS |
| G2 context delta | `CONTEXT_DELTA_UNIT_XSIM_PASS` | PASS |
| G3 four arms | `CAUSAL_LEARN_FAST_XSIM_PASS` | PASS |
| G4 seven cells | `PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS fails=0 CELLS=7` | PASS |
| G5 R1 OUT 549/861/549/237 | `TEACHER_OFF_SOC_XSIM_PASS fails=0 CELLS=9 LM_KNOWN` | PASS |
| persist AXI BRESP/RRESP/RLAST | `PERSIST_AXI_MIG_XSIM_PASS` | PASS |
| persist CDC | `PERSIST_AXI_CDC_XSIM_PASS` | PASS |
| WDMA release CDC | `WDMA_REL_CDC_XSIM_PASS` | PASS |
| collision dual=0 | `PERSIST_AXI_COLLISION_XSIM_PASS fails=0 dual=0` | PASS |

Gate14 UART ladder (this bag, not parent):

| Test | Marker | Result |
|------|--------|--------|
| UART RX 100 MHz | `UART_RX100_XSIM_PASS` | PASS |
| Parser 100k random | `GATE14_PARSER_RANDOM_XSIM_PASS n=100000` | PASS |
| Command authority | `GATE14_COMMAND_AUTHORITY_XSIM_PASS` | PASS |
| Gate14-20 UART bytes | `GATE14_20_UART_XSIM_PASS` MODE=8 OUTA=549 UNREL=861 OUTB=237 ckpt=fff | PASS |

# P2-GATE14-C9-SOC-IO-SAFE-BIT-07 BOARD RUN

**Programmed once. UART armed before program. Stopped on first mismatch.**  
Does **not** declare GATE14_PASS or BOARD_PASS. Oracle not retargeted. No second program.

## Return

```text
GATE=P2-GATE14-C9-SOC-IO-SAFE-BIT-07
CLASS=SILICON_FAIL_DIVERGENCE
COM12=PRESENT
JTAG_TARGET=localhost:3121/xilinx_tcf/Digilent/210319BE776EA xc7a100t_0
BIT_PATH=results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-GATE14-C9-SOC-IO-SAFE-BIT-07/arty_a7_ng_native_v1_grok_orch_C9-SOC-IO-SAFE-BIT-07.bit
BIT_SHA256=3A7EF2044CD92730F048032ABF9E9CC914461EE7CE767745089CD082CC31A00B
PROGRAM_ATTEMPTS=1
PROGRAM_RESULT=OK End of startup HIGH
UART_RAW_PATH=BOARD/uart_raw.bin
UART_RAW_SHA256=75109F9194C8F1D1B1F5E3BAE73AC77E9DF21B9333BEBACC6E8260AC607224FA
A_FACTS_ACCEPTED=20
A_REWARD_COMMITS=20
PERSIST_RELOAD=FLUSH/KILL/RELOAD ran; C8 GEN stayed 0xFFFFFFFF (observability); not proven restore
FREEZE=MODE=8; freeze-block cons stayed 20
RESET_FORGET=not_reached
B_FACTS_ACCEPTED=0
B_REWARD_COMMITS=0
C9_A/U/C/B=2322838281802120 / not_run / not_run / not_run
OUT_A/U/C/B=748 / not_run / not_run / not_run
HOST_FORBIDDEN_COUNTERS=0
FIRST_DIVERGENCE=HOLD_A OUT=748 want=653 pack=2322838281802120 want=8382238122802120
GATE14_PASS=NO
BOARD_PASS=not_claimed
NEXT=Codex triage HOLD_A silicon pack/OUT vs XSim learned C9. Do not retarget oracle. Do not auto-reprogram.
```

## Evidence

- Distinct A tokens `0x10..0x23` (not 20× `0xA1`). C5 cons 0→20, C6 txn 1→20, C7 addr FPGA-owned 50987008…50987312.
- Exam HOLD_A: MODE=8 LMST=1 LMDN=1 X=0. Pack and OUT do **not** match frozen oracle.
- Stopped. No UNREL/CONTRA/B. No 40-fact. No second bit.

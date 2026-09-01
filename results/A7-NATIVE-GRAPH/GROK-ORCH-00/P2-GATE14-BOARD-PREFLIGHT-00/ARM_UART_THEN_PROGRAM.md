# Arm UART before program — prepared, not executed

**PROGRAM=NO.** Do not run these commands in this gate. COM12 was **not** opened.

Order after a **human named token** that cites bit SHA `6975AB75…F8B39A`:

```text
# 1) ARM UART FIRST (blocks until EXIST_ROW / pred=249 / timeout)
python results\A7-NATIVE-GRAPH\GROK-ORCH-00\P2-GATE14-BOARD-PREFLIGHT-00\capture_uart_gate14_preflight.py --port COM12 --baud 115200 --max-seconds 240 --i-have-human-token

# 2) THEN program THIS bit only (exclusive TCL refuses leftover SHA / PYNQ / missing token)
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source results\A7-NATIVE-GRAPH\GROK-ORCH-00\P2-GATE14-BOARD-PREFLIGHT-00\program_candidate_excl.tcl
```

Capture files (created only after step 1 actually runs):

```text
LISTEN_START.txt
uart_gate14_preflight.txt
```

JTAG pin: `localhost:3121/xilinx_tcf/Digilent/210319BE776EA`  
Device: `xc7a100t_0` / `xc7a100t`  
UART: COM12 115200, FTDI `210319BE776EB` (channel B). JTAG is channel A `210319BE776EA`.  
Refuse historical `pred=664`. Accept A-FAST LN-FIX `pred=249`. Pack golden `3B392B291B190B09`.

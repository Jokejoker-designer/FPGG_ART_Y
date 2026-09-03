# P2-GATE14-C1-UART-RX-COMMAND-01 — preregistration (before RTL)

**PROGRAM=NO.** No COM12 / JTAG / board. Do not overwrite bit `6975AB75…`.  
Parent board run stays `PROGRAM_OK` / `BOARD_EXISTENCE_PATCHED_PASS` / `FAIL_C1_NO_HOST_COMMAND_PATH`.

## OBSERVATION

R1 UART 112 B: BOOT/MIG_OK/WMEM_OK/TOPK=PACK=`3B392B291B190B09`/POISON=0/CORE_DONE/`pred=249`.  
`uart_txd_in` (XDC A9) assigned only to `unused_rx`. TX is `uart_tx` on **CLK100MHZ** @ 115200 (`CLK_HZ=100_000_000`).  
`core_clk` post-route `core_raw` **80 ns = 12.5 MHz**. `uart_rx.sv` default `CLK_HZ=8e6` is **wrong** for this SoC.  
`a7ng_g1g5_cofit` auto-issues glue `C_FREEZE` after `p_done` or `boot_wait==FE`. Glue already owns MODE (TRAIN=5, FREEZE=8) from `C_TRAIN`/`C_FREEZE`.

## UNKNOWN

Can a small UART RX + binary whitelist + one-entry queue drive cofit so FPGA emits C0–C11, without host semantic authority, and still fit (free≥64, CDC candidate_logic=0)?

## H_CANDIDATE

100 MHz UART sampler (same clock as TX) → byte CDC to 12.5 MHz core → CRC/len/seq decoder → legal TYPE only → glue cmd handshake. MODE stays FPGA FSM. Auto-freeze disabled when Gate14 enable=1.

## H_RIVAL

1. Keep auto-freeze; host cannot reach TRAIN.  
2. Clock RX from core 12.5 MHz with 100e6 CLKS_PER_BIT → baud fail.  
3. ASCII parser too big / host MODE payload.

## FALSIFIER

XSim: bad stop bit, CRC, dup SEQ, forbidden TYPE, host MODE/idx/delta. Gate14-20 UART sequence missing a C0–C11 frame. Physical: timing/CDC/resource miss.

## UNIT

uart_rx100; parser random ≥1e5 bytes; command authority; Gate14-20 via UART bytes into glue/persist/LM stack.

## CONTROL

Parent regressions A-FAST 249, G1–G5, persist AXI/CDC, WDMA rel, collision dual=0. Parent bit 6975AB75 unedited.

## METRICS

XSim PASS markers below. Physical: route0 WNS≥0 TNS=0 WHS≥0 THS=0 BRAM36≤135 DSP≤240 cand_logic=0 persist_crit=0 free≥64.

## PASS/FAIL

`PASS_BIT_READY_PROGRAM_NO` or FAIL_UART_RX / FAIL_PARSER / FAIL_HOST_AUTHORITY / FAIL_GATE14_20_COMMAND_XSIM / FAIL_REGRESSION / FAIL_PHYSICAL.

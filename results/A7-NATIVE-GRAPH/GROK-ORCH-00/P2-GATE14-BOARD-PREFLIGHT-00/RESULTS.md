# P2-GATE14-BOARD-PREFLIGHT-00 — read-only

**PROGRAM=NO.** No RTL/build edit. COM12 **not opened**. `program_hw_devices` **not called**.  
Codex ACCEPT WDMA CDC `BIT_READY_NOT_PROGRAMMED`. Teacher-Off / Gate14 close / BOARD_PASS **not claimed**.

## Re-hash (EVIDENCE)

Candidate bit still:

```text
arty_a7_ng_native_v1_grok_orch_p2_wdma_release_cdc_audit_03.bit
bytes=3826011
SHA256=6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A
```

Parent D5B `D5B725CF…D22C22` preserved. SOURCE_SHA 16/16 MATCH (`manifest_fail=0`). No live-tree RTL drift vs WDMA-RELEASE lock.

## Hardware enum (EVIDENCE)

| Item | Value |
|------|--------|
| Serial ports (no open) | COM3, COM4, COM12 |
| COM12 | **present** FTDI `VID_0403+PID_6010+210319BE776EB` USB Serial Port |
| JTAG | **present** `localhost:3121/xilinx_tcf/Digilent/210319BE776EA` |
| Device | `xc7a100t_0` part=`xc7a100t` (not PYNQ `xc7z020`) |
| Composite USB | `VID_0403&PID_6010\210319BE776E` |
| Pre-enum owners | no vivado / hw_server / xsdb; no TCP 3121 |
| Python COM12 | no capture_uart / pyserial cmdline |
| Post-enum owners | hw_server released; COM12 still listed |

COM3/COM4 are Bluetooth serial, not the Arty UART.

**Not** `WAIT_HUMAN_RECONNECT` — COM12 and JTAG both present.

JTAG list-only TCL connected, listed, closed target, disconnected. Never set `PROGRAM.FILE`.

## Prepared, not run

- `ARM_UART_THEN_PROGRAM.md` — arm COM12 first, then exclusive program.
- `capture_uart_gate14_preflight.py` — refuses to open COM without `--i-have-human-token`; accepts `pred=249`; refuses historical `pred=664`.
- `program_candidate_excl.tcl` — refuses without `HUMAN_PROGRAM_TOKEN.txt` + `authorize_program=yes` + exact SHA `6975AB75…`.
- `GATE14_20FACT_SEQUENCE.md` — frozen corpus `corpus_20.json` SHA `23A4B503…` + capture paths. 20-fact exam **not run**.

`HUMAN_PROGRAM_TOKEN.REQUIRED.txt` is **not** an authorization (`authorize_program=false`).

## STOP

Need a **human named token** citing gate + bit SHA `6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A` before any program. Do not use old bits.

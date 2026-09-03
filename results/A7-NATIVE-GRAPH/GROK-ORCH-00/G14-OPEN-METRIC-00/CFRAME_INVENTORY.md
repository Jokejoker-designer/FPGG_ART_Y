# CFRAME inventory on F24150BD (UART, live)

Decoder: `python/gate14_uart.py` (`c0`…`c12_fields`).
Sched: `rtl/native_graph/control/a7ng_gate14_cframe_sched.sv`
SHA256 `2B93E559E8D80636233043DD06FBE42BF96A26979BEC7BCFB1DAE3C54ED8E0C5`

Exam dump on HOLD_A includes ckpt 0–12 (`exam_log.json` `dump_ckpts`).

| CK | Payload on this bit | Metric use |
|----|---------------------|------------|
| C0 | SoC id | identity |
| C1 | MODE nibble | teacher-off MODE=8 |
| C2 | anchor | not util |
| C3 | ids + scores | candidate ids (K=8 pack) |
| C4 | evidence | not util |
| C5 | cons/rej/ack | 20 facts; not bytes |
| C6 | rsv/sat | not stall |
| C7 | persist addr/ack/err(busy bit) | persist busy ≠ PE DDR stall |
| C8 | gen/sdig | epoch |
| C9 | ids/pack/poison/r1* | 8 packed ids BOARD |
| C10 | lmst/lmdn/out | OUT oracle |
| C11 | adig/bdig/afor/bvis | persist identity |
| C12 | teacher/ext_llm/MODE/n_host_* | HS-02 live zeros |

**Absent from C0–C12 and from UART_SLIM text stream:**

```text
lane_busy / lane_util / recs_per_cyc
pe_stall / pe_busy / stall_frac
axi_read_bytes / axi_read_bursts / axi_read_beats
time/query / records/cycle
```

Top default `UART_SLIM=1`. Synth TCL for this bit passed `PHYS=4` `SIM_FULL=0` only
(no `-generic UART_SLIM=0`). Slim `hb_next` prints BOOT/MIG/WMEM/TOPK/PACK/POISON/CORE_DONE/pred
only. `axi_bytes[18:0]` is CDC’d to `axi_b_100` but **not selected** on the slim UART.

Internal RTL counters may exist. They are **not BOARD-observable** on this programmed UART.
This gate does **not** add a UART field.

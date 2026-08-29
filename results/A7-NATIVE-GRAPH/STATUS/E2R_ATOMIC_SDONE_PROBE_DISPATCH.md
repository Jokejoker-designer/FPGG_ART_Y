# E2R-ATOMIC-SDONE-PROBE-00 — READY (do not program until COM12)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-ATOMIC-SDONE-PROBE-00/`  
**com12_authorized_gate:** must be this id (not yet; SGO authorize **consumed**)  
**JTAG:** `210319BE776EA` · COM12 115200 · arm before program

**BUILD-ONLY licensed** (COM12 port present; SGO authorize consumed). Exclusive synth/impl/bit only.

Do **not** program / JTAG / `hw_program` / `program_device` unless `BRIDGE.json` `board.com12_authorized_gate` is exactly `E2R-ATOMIC-SDONE-PROBE-00` at program time (re-read BRIDGE immediately before any hw_server). Do not reprogram SGO bit `832E55E2…`. Do not program on leftover SGO authorize.

## Exclusive-build lessons (SGO bit)

- One `vivado.exe` writer. License `D:\Xilinx\licenses\vivado_basic.lic`.
- Exclusive Tcl: **no** `[\s\S]` (Vivado Tcl abort after route on SGO).
- Omit `e2r_la_pmod_ja.xdc`. Waive ja-only NSTD-1/UCIO-1. No LiteScope / JA analyzer.
- Prefer `write_bitstream` from the same `e2r_post_route.dcp` if a post-route abort happens.

## ACK implication (XSim, not silicon)

Stub `ACK_ONLY_AFTER_DONE` (SHA `ADA5C6E3…`): dest=5 only after done/`!m_busy`. Silicon ATOM1 dest=5 is **compatible** with core seeing done. ATOM `dma_st=5` stays CDC FINDING. Sequential `SDONE=0` is still latch/print until this pack.

## Do not

A2 / C-FIX / LiteScope / Phase 2 / steal Grok R6 / BOARD_PASS / use sequential `SDONE=` as class / strip UART probes (that wait is post-`pred=664`).

## Scientific frame

- **OBSERVATION:** Silicon SGO_HIT dma_st=5(R) leftover SET. Stub SDONE_ROSE. Sequential `SDONE=0` `W_STALL` `PHASE=01` `pred` absent. UART SDONE is `latched_sdone_f1t <= dbg_s_done_sticky` while `core_busy_ui`.
- **UNKNOWN:** at first dest=4∧owner, packed s_done latch/sticky, w_stall, core_done (UI bits synced to core)?
- **H_CANDIDATE:** dest=4 and both done bits 0 (`SDONE_MISS`) — true miss vs stub.
- **H_RIVAL:** dest=4 and latch or sticky =1 (`SDONE_HIT`) — sequential `SDONE=0` is latch/print like SGO.
- **FALSIFIER:** sequential SDONE row as class; force dest; C-FIX; unsynced UI bits.
- **UNIT:** first dest=4∧owner + next core cycle.
- **CONTROL:** ATOMIC-SGO `00001B9C`; SDONE-CXSIM ROSE SHA `DF55ACF4…`; sequential `SDONE=0`.
- **METRICS:** ATOM hex, class. Gate PASS = rows decoded. Existence = `pred=664`.

## Pack (draft, `[31:13]=0`)

| bits | field |
|------|--------|
| [2:0] | dest |
| [3] | owner |
| [4] | grant |
| [5] | idle |
| [6] | `latched_sdone_f1t` → core |
| [7] | `dbg_s_done_sticky` → core |
| [8] | `w_stall` (core) |
| [9] | `core_done` (core) |
| [10] | `mgo_sticky` |
| [12:11] | reserved 0 |

Print `ATOM0=` `ATOM1=` only. Class: `NO_DST4` / `SDONE_HIT` / `SDONE_MISS` / `WSTALL` (done=0 and w_stall=1).

# PHASE2-G2-CONTEXT-DELTA-RTL-00 — RESULTS

Prompt SHA-256: `48D4E35CADFE0A5DA0C67CDC3577B0B47EAF2CAB448C32963DD62CFE81E15449`  
DUT SHA-256: `0614386298F31DC6A5EB456959290F9C6ADDC899FBF91F8CD49BB5A3D2BBA800`  
G1 resolver SHA-256 (unmodified): `2219DA29C265D2461ED30783EBEA0F0649050B9B6E5F6EAFDB8F1C4E05F3F5F7`  
G0 law SHA-256: `BE892A777F2616F169AFB72D68399FF0150C817A77A20AB249CBAC70512A8E86`  
G2 preregister SHA-256: `DDEB61064C20A36EC6856EF5EC52C69A4B7F30DA4871C3F536025C6792DA9DF0`

Vivado: 2026.1 (SW Build 6511674). Part `xc7a100tcsg324-1`. Core clock **12.5 MHz, period 80.000 ns**.  
`PROGRAM=NO`. SoC instantiate ABSENT. No COM12/JTAG/bitstream/full-chip.

## Unknown

Does an FPGA-only delta engine, driven exclusively by a legal G1 consume record, produce the exact `a7ng-learn-ctx-v1` signed delta for every registered row and remain lossless under downstream backpressure without exposing host-writable delta/index/address authority?

## Law implemented

```text
prod  = signed32(reward) x signed32({1'b0,native_conf})
delta = sat16(prod ASR 8)
```

Legal prod range is `[-196605,+196605]`. Fabric uses a 19-bit two's-complement shift-add (reward `{-3..+3}`) that is bit-exact on that range. No `*` operator. No DSP.

`native_conf` is unsigned 16, stimulated as an FPGA-latch stand-in. G1 `consume_conf` remains 8-bit and was not modified. Identity pass-through uses G1 consume widths (`rel` 8-bit).

## Static interface audit

`INTERFACE_AUDIT_PASS`. DUT ports have no host `delta_i` / `learn_delta` / `idx_i` / winner / address / cue. Negative control `a7ng_wm00_learn_upd.delta_i` was not used as this DUT.

## XSim

| Test | Result |
|------|--------|
| `tb_a7ng_context_delta` directed 7-row table, each after reset/idle, 5-cycle stall hold, mid-stream reset | `CONTEXT_DELTA_UNIT_XSIM_PASS fails=0` |
| `tb_a7ng_context_delta_rand` seed `C0DEDA7A`, 100000 accepted txns, random gaps + multi-cycle backpressure | `CONTEXT_DELTA_RAND_XSIM_PASS MISMATCH_COUNT=0 n_in=100000 n_out=100000` |

Directed frozen table (all bit-exact):

| reward | native_conf | delta |
|-------:|------------:|------:|
| +3 | 256 | +3 |
| −3 | 256 | −3 |
| +1 | 0 | 0 |
| +1 | 255 | 0 |
| +3 | 65535 | **+767** (not +768) |
| −3 | 65535 | −768 |
| 0 | 256 | 0 |

Directed `n_in=10 n_out=9`: the extra accept is the mid-stream reset falsifier (held payload dropped by `rst_n`; no stale after reset). Scoreboard does not treat that as loss of a retired transaction.

Random (attempt 2 after preserved attempt-1 drain race): `n_stall=79999` `n_gap=59999` `extra=0` `loss=0` `stale=0` `sat_bad=0`. Attempt-1 FAIL log kept as `rand_xsim_attempt1_FAIL.log` (`n_out=99999` because TB dropped `in_valid` in the same posedge active region as the last accept).

Commands:

```text
set XILINXD_LICENSE_FILE=D:\Xilinx\licenses\vivado_basic.lic
python audit_ports.py rtl/native_graph/learn/a7ng_context_delta.sv
C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source run_xsim.tcl
```

Raw: `unit_xvlog.log` `unit_xelab.log` `unit_xsim.log` `rand_xvlog.log` `rand_xelab.log` `rand_xsim.log`.

## OOC (after XSim pass; no competing Vivado)

Attempt 1 (32-bit fabric intermediate): LUT=108 **over** target 100. Reports preserved (`ooc_*_attempt1*`). Arithmetic not weakened.

Attempt 2 (19-bit exact legal range, same table/handshake/ports):

```text
LUT=59 (logic 59, LUTRAM=0)
FF=153
BRAM=0 DSP=0
control_sets=2
WNS=+76.475 TNS=0 WHS=+0.241 THS=0
clk period=80.000 ns (12.5 MHz)
```

Target `LUT<=100 FF<=180 LUTRAM/BRAM/DSP=0 WNS/TNS/WHS/THS clean`: **met**.

```text
C:\2026.1\Vivado\bin\vivado.bat -mode batch -notrace -source run_ooc.tcl
```

## Not claimed

```text
G3 causal Top-K
persistence / G4 generation
Teacher-Off / G5
Gate 14 PASS
BOARD_PASS
PROGRAM
full-chip / SoC instantiate
resource closure of Native V1 (free slices still 691 on GRAPH-PAYLOAD-NORESET)
pred=664 as learning evidence
```

XSim ≠ board. UNIT_PASS ≠ existence. `PROGRAM=NO`.

STOP for Codex audit.

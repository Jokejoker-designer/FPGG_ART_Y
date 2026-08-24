# A7-EAM RTL

## 00 — set-associative (frozen geometry)

Spec: `docs/contracts/A7-EAM-00.md`.

| File | Role |
|------|------|
| `a7eam00_pkg.sv` | 256×16, entry pack, popcount, EMA |
| `eam_tdp256.sv` | inferred TDP 256b × 4096 |
| `eam_core.sv` | pipelined XOR→pop→fold; winner refetch; hit-EMA / miss-evict |
| `eam_controller.sv` | 32-D INT8 merge |
| `eam_axil.sv` | AXI4-Lite CSR |
| `a7eam00_top.sv` | native query + AXI |
| `eam00b_uart.sv` | 00B/00G UART transport |

## 01R — multi-index router (development)

Spec: `docs/contracts/A7-EAM-01R.md`. Same record store. Candidate routing only.

| File | Role |
|------|------|
| `a7eam01r_pkg.sv` | 8 banks × 256 × 32, HIT_MAX=8, MARGIN_MIN=4 |
| `eam01r_ibank.sv` | 8192×13 index TDP (valid+id) |
| `eam01r_core.sv` | exact 8-bucket then radius-1; dedup; Hamming+margin |
| `eam01r_uart.sv` | 00B frames + CMD 0x08 MARGIN; observes `out_vector` |
| `eam02q_q1.sv` | Q1 ±1 hyperplanes, 128-cycle add/sub, 0 DSP |
| `eam02q_q1_signs.svh` | frozen ROM, law `eam02q-q1-rh-v1` |
| `eam02q_uart.sv` | LOADH / ENC / MAP_H + 01R core |
| `a7eam02m_pkg.sv` | 256 episodes, fold law `eam02m-fold-v1` |
| `eam02m_core.sv` | OPEN/BIND/PROBE + teacher-off on frozen 01R |
| `eam02m_uart.sv` | 0x10–0x15; raw 01R MAP/PROBE not exposed |
| `a7eam03e_pkg.sv` | 03E-A0 law `eam03e-a0-signsgd-v1` |
| `eam03e_core.sv` | embed + Elman + ±1 proj + local SignSGD; A0.1-T pipelines pacc/MAC/EUPD/`S_DIST` |
| `eam03e_uart.sv` | BUF/PAIR/ENC; no 01R |

## 03E-UI — operator studio support (not evidence)

Spec: `docs/contracts/A7-EAM-03E-UI.md`. Same core, same law. Added so the studio
UI can mirror the physical board; no EAM top wires `sw`/`btn` into a datapath and
`led` are output pins, so without this there is nothing to read.

| File | Role |
|------|------|
| `eam03e_io_uart.sv` | copy of `eam03e_uart.sv` + CMD 0x2F (SW/BTN/LED + sticky edges); SW0 forces freeze, SW1 forces learn |

Kept as a separate file so `eam03e_uart.sv` stays byte-identical while A0.1-T
closes timing under a frozen law. **Not elaborated, simulated or synthesised** —
do not build until A0.1-T timing closes.

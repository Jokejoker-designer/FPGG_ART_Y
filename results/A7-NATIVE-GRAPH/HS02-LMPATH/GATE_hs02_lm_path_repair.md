# GATE — hs02_lm_path (REPAIR)

GATE: hs02_lm_path
AGENT: a7-vivado-gate
RESULT: PASS_NARROW
CHANGED:
- rtl/board/arty_a7_ng_lm06_ua_soc_top.sv (smoke_done + watchdog; req_lm on calib not smoke_pass; fixed-addr wt∧act sticky FSM)
- vivado/tcl/native_graph/program_lm06_ua_soc.tcl
- results/A7-NATIVE-GRAPH/HS02-LMPATH/*repair*
- results/A7-NATIVE-GRAPH/LM06-UA/arty_a7_ng_lm06_ua_soc.bit (new SoC only; CONTROL D2C6 archived)

TESTS:
- post-route rebuild measure_lm06_ua_core.tcl → WNS=0.244 TNS=0 WHS=0.032 THS=0 BRAM=128 DSP=0
- program Digilent 210319BE776EA (COM12 present)
- UART MODE-only E0/S → rx 91B9; exam_mode=1; lm_path=1; mig_calib=1
- frozen LM-06/01R/02M/A0.3 SHA MATCH (not overwritten)
- CONTROL prior FAIL bit D2C6CF4B archived under HS02-LMPATH

PASS-FAIL: PASS_NARROW
- UNKNOWN closed: board-visible lm_path≠0 after programming without host-invented UART bit
- LIMIT: TinyGPT/DSP ABSENT (full HS-22 OPEN); pe_alive=0; not BOARD_PASS; not semantic retrieval

ARTIFACT: results/A7-NATIVE-GRAPH/HS02-LMPATH/GATE_hs02_lm_path_repair.md
SHA256: 4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E
PRIOR_FAIL_SHA: D2C6CF4B28706B24CE513E2B7A09A4018EB9BB01EBB864FA3A5375B11DB9A92C
ATTEMPT1_SHA: 09304F9D579D9DC599F922A32F30FB5B0B61AB87F589ABDB0F7A01F5B8413A13 (still lm_path=0; smoke_done alone insufficient)

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | HLB FAIL D2C6: exam 0x91 lm_path=0 t+210s; sticky gated on grant_lm←smoke_pass |
| UNKNOWN | can RTL make board-visible lm_path≠0 via wt∧act sticky without MIG smoke dependency? |
| H_CANDIDATE | new bit ≠ D2C6; COM12 lm_path bit set; HLB-clean MODE-only |
| H_RIVAL | hardwire lm_path=1; host invents bit |
| FALSIFIER | frozen overwrite; BOARD_PASS; TinyGPT claimed present |
| CONTROL | D2C6 prior FAIL transcript; frozen LM MATCH |
| Verdict | **CLOSED — PASS_NARROW** — UART `91B9` lm_path=1; bit 4451AFD9; TinyGPT ABSENT LIMIT |

## Measured (provenance)

| Metric | Value | Provenance |
|--------|-------|------------|
| WNS | +0.244 ns | post-route |
| TNS | 0.0 ns | post-route |
| WHS | +0.032 ns | post-route |
| THS | 0.0 ns | post-route |
| BRAM tiles | 128 | post-route cell count |
| DSP | 0 | post-route |
| UART status | 0x91 | board COM12 |
| UART flags | 0xB9 | board; bit5 lm_path=1 |
| exam_mode | 1 after 0xE0 | board |
| TinyGPT | ABSENT | DSP=0 LIMIT |

## RTL repair (not hardwire)

1. `req_lm <= 1` after `ui_rst_n` (calib); `req_graph <= 0` so arb grants LM without smoke_pass / SD_DONE.
2. Fixed-address EV_WR/WAIT/RD/HOLD FSM: write PAT to wt addr 32 + act addr 32, readback compare → `wt_seen ∧ act_seen` → `lm_path_sticky` (not `assign lm_path=1`).
3. Compose start no longer AND-gated on `smoke_pass`.

## NEXT

Re-dispatch `a7-hlb-auditor` to confirm HLB CLEAN on 4451AFD9; then advance LOOP_STATE. TinyGPT ABSENT remains LIMIT for full HS-22. No BOARD_PASS.

BOARD_PASS: false
allow_loop_done_eng: true (narrow lm_path visibility only)
Evidence_class: BOARD_UART_LM_PATH_PROBE

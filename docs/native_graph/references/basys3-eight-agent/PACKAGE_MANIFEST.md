# Package manifest — 8-agent Basys 3

**Closed through:** M8-LM-05 (2026-08-16)  
`FULL_TINY_TRANSFORMER_BACKPROP_FPGA_BOARD_VALIDATED`

This zip is the **same file** as `…THROUGH-M8-HW-06B-20260816.zip`, updated in place
with the LM-00…05 closeouts. It does **not** prove an open-domain LLM.

## Closed claims

| Milestone | Claim | Bitstream SHA-256 (prefix) |
|-----------|--------|----------------------------|
| M8-HW-01 | cyclic 650/650, HOLD `W=1088=0440` | `E27B0277…` `basys3_eight_agent.bit` |
| M8-HW-02 | A → reset → B remap | `74F98993…` `m8hw02.bit` |
| M8-HW-03 | 64 cells one TRAIN | `34D63D5D…` `m8hw03.bit` |
| M8-HW-03R | 32/32 then 128/128 | same `m8hw03.bit` |
| M8-HW-04 | ABC→X, ACB/BAC/AB/forget ≠ X | `DEEFE548…` `m8hw04.bit` |
| M8-HW-05 | `xin chào`+`hello` → basin `0x88` | **reuse** `m8hw04.bit` |
| M8-HW-06A | teacher-free single-turn → `chào bạn` | **reuse** `m8hw04.bit` |
| M8-HW-06B | Quân/Lan multi-turn, AFTER frozen W | `7CE3238E…` `m8hw06b.bit` |
| M8-LM-00 | LEGACY SHA freeze | no new bit |
| M8-LM-01 | 8-token AR 100/100 | `5D80331D…` `m8lm01.bit` |
| M8-LM-02 | tiny LM 1000/1000 logits | `basys3_lm02.bit` |
| M8-LM-03 | causal GPT forward | `8D2AF247…` `basys3_lm03.bit` |
| M8-LM-04 | head/embed SGD 128/128 | `B7135153…` `basys3_lm04.bit` |
| M8-LM-05 | full backprop dumpz CE 40.6% | `8657DA03…` `basys3_lm05.bit` |

## Included

- `rtl/core/` — LIF, STDP 8×8, route-gate, `temporal_context8`
- `rtl/board/` — clock 8 MHz, cyclic/dense/temporal supervisors, UART, top
- `rtl/legacy_bipolar/` — old research RTL, **not** the board default
- `constraints/basys3_eight_agent.xdc`
- `vivado/*.tcl` + `build_basys3.bat` / `program_basys3.bat`
- Frozen bits in `build/out/`: cyclic, `m8hw02`, `m8hw03`, `m8hw04`, `m8hw06b`
- LM bits: `m8lm01`, `basys3_lm02`…`lm05` (separate files; do not overwrite HW bits)
- Timing/util/power/DRC/congestion **text** reports + LM-05 route reports
- `python/` + `python/lm/` + `tests/` + `tb/` + `tools/` (scorers 02–06B and LM-01…05)
- `docs/` including M8-HW-02…06B and M8-LM-00…05 contracts
- `rtl/lm/` tiled TinyGPT / backprop
- `results/` closeouts + board runs + `MILESTONE_CHECKLIST.md` + `SCORECARD.md`
- `results/immutable/M8-HW-FROZEN.json`
- `results/M8-HW-02/IMMUTABLE_20260814/`
- `README.md`, `VALIDATION.md`, `VALIDATION.json`, `AGENTS.md`, `SHA256SUMS.txt`

## Excluded from this zip

- Vivado project cache (`build/vivado`, `.Xil`)
- XSim project trees (`build/sim_m8_hw02` … `sim_m8_hw06b`)
- Checkpoints `*.dcp`
- Python/pytest caches
- Nested `results/M8-HW-02/M8-HW-02.rar`

## Rebuild / program

Vivado 2026.1, license `D:\Xilinx\licenses\vivado_basic.lic`.  
Part: `xc7a35tcpg236-1`. UART: COM8 (HW) / COM10 (LM-02…05) 115200.  
`program_basys3.bat` prefers `m8hw06b.bit`. Use `vivado/build_basys3_lm05.tcl` for the LM-05 bit.  
Do **not** overwrite frozen `m8hw02` / `m8hw03` / `m8hw04` / `m8hw06b` / `lm03` / `lm04` files.

# Basys 3 — 8-Agent Route-Gate SNN (aligned to the proven 4-agent board)

This package is the 8-agent upgrade of the **board-proven** 4-agent demo
(`basys3-four-agent-snn-ready`): same numeric STDP law, same route-gate,
same output latch, same EVAL → TRAIN → EVAL → HOLD supervisor, same UART
frames.

It is **not** an LLM, not a Transformer, and not a conversation model.
The old bipolar “conversation routing” RTL is kept only under
`rtl/legacy_bipolar/` for research comparison.

## What is proven vs what is not

Closed through **M8-LM-05** (2026-08-16) on the same Basys 3 kit.
Living list: `results/MILESTONE_CHECKLIST.md`.

| Claim | Status |
|-------|--------|
| 4-agent cyclic LTP + freeze on Basys 3 | PASS (other package) |
| 8-agent cyclic online STDP | **PASS** HOLD 650/650, `W=1088=0440` |
| A → reset → B remapping (two host seeds) | **PASS** `m8hw02` `74F98993…` |
| 64 cells same-transaction + 128-seed ensemble | **PASS** `m8hw03` `34D63D5D…` |
| Temporal ABC→X, order negatives | **PASS** `m8hw04` `DEEFE548…` |
| Host-encoded phrases → one learned basin | **PASS** same `m8hw04` bit |
| Teacher-free after-train single-turn | **PASS** 06A |
| Simple learned multi-turn (name in ctx) | **PASS** 06B `m8hw06b` |
| LM-00 LEGACY freeze | **PASS** `FROZEN SHA PASS` |
| LM-01 8-token AR | **PASS** `m8lm01` `5D80331D…` |
| LM-02 tiny LM forward | **PASS** `basys3_lm02.bit` |
| LM-03 causal GPT forward | **PASS** `8D2AF247…` |
| LM-04 head/embed SGD | **PASS** 128/128, CE 31% |
| LM-05 full tiny Transformer backprop | **PASS** dumpz CE 40.6% |
| Open-domain / LLM chat | **NOT CLAIMED** |

06B is *simple learned multi-turn* only. LM-05 is a **separate** tiled-SGD bitstream,
not an open-domain LLM. Do not overwrite frozen HW or LM-03/04 bits.

## Board default datapath

```text
one-hot source (8 bits)
        ↓
8×8 STDP (full-parallel update on LEARN)
        ↓
ROUTE_GATE: if W[d][s] > 256 and source[s] then I[d]=560 else 0
        ↓
8 LIF (threshold 512)  — spike latched for UART/LED
        ↓
EVAL_BEFORE → TRAIN 1024 → EVAL_AFTER → HOLD
```

Cyclic teacher: `0→1→2→3→4→5→6→7→0`.
After one TRAIN: `W[d+1][d] = 64 + 8×128 = 1088` (`0440`), then freeze.
`07FF` (2047) is `WEIGHT_LIMIT` clip — press **BTNU** to restart; do **not**
toggle SW11 to retrain (that was how the 4-agent display hit the rail).

## Switches

```
SW15           leftmost; dest inspect MSB
SW14           temporal mode (or A5 62 arms it)
SW13           dest inspect only — OFF for 03/04/05
SW12           dense mode (or A5 60 arms it)
SW11           AUTO / enable
SW10           cyclic vs remap; must be OFF for dense/temporal
SW9            freeze override
SW0            rightmost
BTNU           cyclic: reset weights AND start EVAL
```

Temporal wins over dense. A5 62 is enough to arm 04/05 (SW14 optional).

LED7:0 = latched output spikes. LED12=freeze, LED13=learn, LED14=SW11, LED15=lock.

## UART (COM8, 115200)

```bat
python tools\uart_monitor.py COM8 --seconds 90
```

Live `A5 5A`: `in`/`out` are full 8-bit codes (`01→02→04→08→10→20→40→80→01`).
Result `A5 5C`: before/after accuracy and 8 route bits.

## Build

```bat
set PATH=C:\2026.1\Vivado\bin;%PATH%
build_basys3.bat
program_basys3.bat
```

Cyclic board evidence: `results/13_board_score.md`, `results/M8-HW-01_CLOSEOUT.md`.
Bitstream: `build/out/basys3_eight_agent.bit` (WNS +103.692 ns).
That bit proves **cyclic convergence only**.

## Tests

```bat
set PYTHONPATH=.
python -m pytest -q tests
```

Legacy bipolar association tests (`golden_model.py`) remain; they are **not**
the board default.

# Validation

## Python

```bat
set PYTHONPATH=.
python -m pytest -q tests
```

Legacy golden-model tests + `tests/test_route_gate8.py`.
Those tests are **not** a remapping board proof.

## M8-HW-01 (closed 2026-08-14)

Vivado 2026.1 / `xc7a35tcpg236-1`:

- `BASYS3_BUILD_PASS` WNS **+103.692 ns**
- bit `build/out/basys3_eight_agent.bit` (2,192,225 bytes)
- program Digilent `210183BF7B31A` startup HIGH

COM8 after SW11 + BTNU, **cyclic** teacher only:

| Phase | Evidence |
|-------|----------|
| EVAL_BEFORE 1–32 | `W=64=0040`, `out=00` |
| TRAIN 33 | LTP `64→72` |
| First route 233 | `in=01 out=02`, `W=272` |
| HOLD 1057+ | `W=1088=0440`, updates frozen 1024 |
| Frozen cyclic | **650 / 650** |

Verdict: `8_AGENT_CYCLIC_LEARNING_CONVERGENCE_DEMONSTRATED`.

**Not** `GENUINE_ASSOCIATIVE_LEARNING`. **Not** conversation.

## M8-HW-02 … M8-HW-04

Closed on silicon. See `VALIDATION.json` and `results/MILESTONE_CHECKLIST.md`.

## M8-HW-05 (closed 2026-08-14)

Same `m8hw04.bit` `DEEFE548…`. Host encoder. COM8:

| Gate | out |
|------|-----|
| `xin chào` + `hello` joint | **0x88** |
| `hello` after P1-only | **0** |
| `tạm biệt` | **0x77** |
| RESET | **0** |
| remap | **0xCC** |

`PHRASE_BASIN_ASSOCIATION_BOARD_VALIDATED`. **Not** conversation.

## M8-HW-06A (closed 2026-08-16)

Same `m8hw04.bit` `DEEFE548…`. AFTER infer:

| Input | FPGA | Decode |
|-------|------|--------|
| `xin chào` | 0x88 | chào bạn |
| `hello` | 0x88 | chào bạn |
| `tạm biệt` | 0x77 | empty |

W SHA frozen `5452F2B6…`. LLM 0.

`TEACHER_FREE_AFTER_TRAIN_SIMPLE_INTERACTION_BOARD_VALIDATED`. **Not** conversation.

## M8-HW-06B (closed 2026-08-16)

`m8hw06b.bit` `7CE3238E…` WNS +96.343. 04 untouched.

| Hist | FPGA | Decode |
|------|------|--------|
| Quân + chào + hỏi | 0x66 | Quân |
| Lan + chào + hỏi | 0xEE | Lan |
| only hỏi / permuted | 0x00 | empty |

`SIMPLE_LEARNED_MULTI_TURN_CONVERSATION_BOARD_VALIDATED`. Not an LLM.

## M8-LM-04 (closed 2026-08-16)

Separate bit `basys3_lm04.bit` `B7135153…`. WNS +89.017. COM10:

| Gate | Result |
|------|--------|
| 128 hardware grads vs golden | **128 / 128** |
| FPGA CE drop 8 epochs | **31.03%** (464 → 320) |
| Frozen QKV/FFN SHA | unchanged |
| AFTER extra TRAIN writes | **0** |

`ON_FPGA_GRADIENT_TRAINED_LM_HEAD_AND_EMBEDDINGS`. Not full backprop (LM-05).

## M8-LM-05 (closed 2026-08-16)

Separate bit `basys3_lm05.bit` `8657DA03…`. WNS +82.520. COM10:

| Gate | Result |
|------|--------|
| 128 hardware grads vs golden | **128 / 128** |
| FPGA corpus CE (dumpz + host softmax) | **40.625%** (512 → 304) |
| All 9 banks moved on silicon | **true** |
| AFTER extra TRAIN writes | **0** |

`FULL_TINY_TRANSFORMER_BACKPROP_FPGA_BOARD_VALIDATED`. Last Basys 3 research gate. Not an open-domain LLM.


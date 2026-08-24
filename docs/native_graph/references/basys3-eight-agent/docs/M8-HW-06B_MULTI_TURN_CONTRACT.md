# M8-HW-06B — multi-turn context

**Status:** BOARD PASS 2026-08-16 (`results/M8-HW-06B/run_003`).  
**New bitstream name only:** `basys3_eight_agent_m8hw06b.bit` `7CE3238E…`  
Do not overwrite `m8hw04` `DEEFE548…` / `m8hw03` / `m8hw02` / cyclic.

06A is teacher-free **single-turn**. Context was cleared every probe.
06B keeps the M8-HW-04 binder **across turns** on the FPGA.
The host still encodes text. `rtl/` has no name, no HELLO, no phrase.

## FPGA increment

- Same `ctx := rotl3(ctx) ^ stim ^ rotl2(stim)`.
- New: `hold_ctx` (flag on A5 62/63 unused byte) skips the automatic clear.
- New: `A5 5F 08` clears **ctx only** (weights stay).
- `A5 5F 06` still wipes weights + ctx.
- 04/05 frames send flag=0, so old tests stay valid on this bit.

Each turn is still three host-encoded stims. Multi-turn = several
3-token groups **without** clearing FPGA ctx.

## TRAIN (teacher legal)

1. `Tên tôi là Quân`
2. `Xin chào`
3. `Tôi tên gì?` → teacher = encode_basin(`Quân`)

And a second name family in the same TRAIN:

1. `Tên tôi là Lan`
2. `Xin chào`
3. `Tôi tên gì?` → teacher = encode_basin(`Lan`)

(`Lan` is a second host string chosen so the two histories are Hamming-4.
The encoder is not told that they are names.)

## AFTER (same hard switch as 06A)

Teacher OFF, External LLM 0, Learn OFF, Freeze ON, weight writes 0.

| Probe | Expect |
|-------|--------|
| Quân + chào + hỏi tên | decode **Quân** |
| Minh + chào + hỏi tên | decode **Minh** (name change) |
| RESET ctx, then only `Tôi tên gì?` | not Quân, not Minh |
| `Xin chào` + `Tên tôi là Quân` + hỏi tên | not Quân (order) |

If and only if those hold on silicon with AFTER flags:

```text
SIMPLE_LEARNED_MULTI_TURN_CONVERSATION_BOARD_VALIDATED
```

That is the first time this repo may use *simple learned multi-turn
conversation*. It is still not an LLM and not open-domain chat.

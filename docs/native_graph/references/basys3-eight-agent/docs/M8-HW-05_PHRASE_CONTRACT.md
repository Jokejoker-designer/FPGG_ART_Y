# M8-HW-05 — semantic / phrase association

**Status:** BOARD PASS 2026-08-14 (`results/M8-HW-05/run_001`).  
**Bitstream:** reuse `basys3_eight_agent_m8hw04.bit` (`DEEFE548…`). No rebuild.  
Do not overwrite `m8hw04` / `m8hw03` / `m8hw02` / cyclic bits.

M8-HW-04 proved one host-loaded sequence `A→B→C` can train a readout
to emit `X`, and permutations do not. That is still one triple, not a phrase.

05 adds a **host encoder** and a **many-to-one basin** test on the same
temporal binder + learned 8×8 readout.

## What 05 is

1. Encoder lives on the host. It turns UTF-8 text into three 8-bit stims.
2. FPGA sees only those stims and an 8-bit teacher. No phrase, no HELLO id.
3. Two *distinct* encoded phrases are trained to the *same* teacher basin.
4. After TRAIN, both phrases probe to that basin.
5. A third encoded phrase (distractor) does not.
6. RESET forgets. A new teacher remaps the same phrases to a new basin.

## What 05 is not

- Not a prompt→response lookup table (no `dict[str,str]` in the encoder).
- Not a HELLO / intent opcode in `rtl/`.
- Not conversation. Teacher is still used in TRAIN. M8-HW-06 is AFTER-train
  with Learn OFF / Freeze ON / LLM call count = 0.

## Encoder law (host only)

Published mixer, class-unaware. Same binder as the FPGA context:

```text
acc := rotl(acc, 3) ^ byte ^ rotl(byte, 2)
```

Bytes of `text.encode("utf-8")` are striped into three lanes, then mixed
with length and a single published salt `ENCODER_SALT = 0`. Salt is a mixer
constant, not a per-phrase patch.

`encode_tokens(text) -> (s0, s1, s2)`  
`encode_basin(text) -> teacher`  (8-bit, nonzero)

The encoder must **not** take a response class as input.

## First gate (demo family, host strings only)

| Role | Text | After joint TRAIN |
|------|------|-------------------|
| P1 | `xin chào` | out == basin(`chào bạn`) |
| P2 | `hello` | out == basin(`chào bạn`) |
| D  | `tạm biệt` | out != that basin |
| P1 after RESET | `xin chào` | out != basin |
| Remap | same P1,P2 → basin(`rất vui được giúp`) | out == new basin, != old |

Additional golden gates:

- `encode_tokens(P1) != encode_tokens(P2)` (association is learned, not a collision).
- Train **only** P1: P2 does **not** already emit the basin (no class smuggled in the code).
- Train P1 then P2: both emit the basin.
- `rtl/` contains none of the demo strings and no `HELLO` id.

If and only if those hold on silicon (same `m8hw04.bit`):

```text
PHRASE_BASIN_ASSOCIATION_BOARD_VALIDATED
```

No conversation claim.

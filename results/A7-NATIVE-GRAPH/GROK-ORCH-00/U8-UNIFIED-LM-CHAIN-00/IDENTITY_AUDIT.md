# IDENTITY_AUDIT — U8-UNIFIED-LM-CHAIN-00

```text
GATE     = U8-UNIFIED-LM-CHAIN-00
HEAD     = 2984b221eee294cc45301be76e562520eb5dce5b
RTL_EDIT = NO
RESULT   = OWNER_DECISION_REQUIRED
```

PRIMARY_UNKNOWN: can the U6/U7 authoritative TYPE_CLASS Top-K drive
LM-06 with exactly one `start_fwd` / `done`, host next-token = 0,
**without silently redefining C9/LM-token identity or HOLD_A?**

Chat memory is not authority. Sources below are RTL + frozen bags.

## Three identities that are not the same

| Name | Width / domain | Owner today | Used as |
|---|---|---|---|
| `retrieval_id` | CLASS_ID 16-bit, 1..443 | `a7ng_typeclass_scan` U6/U7 | production Top-K |
| `learn_key` | `{subj,rel,obj}` V1 | `a7ng_learn_key_class_context_v1` | scalar-reward store |
| `lm_tok` | 8-bit token into TinyGPT `tok[]` | `tiny_gpt803k_core` via `ctx_pack[8*i +: 8]` | LM-06 embedding index |

U7 proved: `retrieval_id × query context` → `learn_key` → ranking.
U8 asks: `retrieval_id` → `lm_tok`?

**No frozen authority mapping CLASS_ID → LM token exists.**

## Current LM context law (RTL_FACT)

`a7ng_native_ctx_bind.sv`:

```text
pack[8*i +: 8] = global_id_i[i][7:0]
ctx_n_in = 8
```

`tiny_gpt803k_core.sv` consumes that pack as **vocabulary tokens**:

```text
tok[ctx_idx + ii] <= ctx_pack[8*ii +: 8]
waddr = OFF_TOK + tok[last] * D
```

C9 pack in `a7ng_learned_prior_graph.sv` is the same low-8 packing of
`topk_id` (historical **graph node IDs**, not CLASS_ID).

U4B added `ctx_pack20` (20-bit IDs) as **observe/live ID**, not as the
LM embedding index. LM-06 still eats 8-bit tokens.

## TYPE_CLASS Top-K law (RTL_FACT, U6 PASS)

```text
heap_id[15:0] = CLASS_ID
heap_id[31:16] = 0
MAX observed CLASS_ID in U6 gold > 255 (duct 256+, exact8 427)
```

If CLASS_ID is stuffed into current `ctx_pack` / C9-low8:

| CLASS_ID | low8 | collision |
|---|---|---|
| 65 | 0x41 | token 65 |
| 256 | 0x00 | aliases CLASS_ID 0 / pad-ish |
| 427 | 0xAB | aliases CLASS_ID 171 |

That is `CLASS_ID_LEARN_ID_ALIAS` class failure for LM tokens.

## HOLD_A / frozen OUT (BOARD_FACT, do not retarget)

Bit `1F0F2ABB`, commit `9656245`:

```text
HOLD_A C9 = 8382238122802120
OUT       = 653 / 689 / 237 / 60
```

Those eight C9 bytes are **NID-era low8 node IDs**, not TYPE_CLASS
65/66/67. A TYPE_CLASS-driven pack cannot claim this oracle without
owner retarget (forbidden).

`CURRENT_GATE14_STATUS.md`: `LM06_ACTIVE_CHAIN = OPEN`.
Silicon already ran LM on the **legacy C9 path**. That is not U6
TYPE_CLASS unified retrieval.

## Production glue today

| Path | Retrieval object | Feeds LM? |
|---|---|---|
| `a7ng_u6_typeclass_retrieval` | TYPE_CLASS CLASS_ID | **NO** |
| `a7ng_u7_contextual_rank` | TYPE_CLASS + V1 prior | **NO** |
| `a7ng_learned_prior_graph` + `a7ng_gate14_c9_soa_lm_xsim` | legacy qid / NID Top-8 | **YES** (XSim wrapper) |
| SoC bit `1F0F2ABB` | epoch C9 NID pack | **YES** on board |

U6 said legacy NID candidate authority = **DISCONNECTED** from the
typeclass top. Wiring LM only to the disconnected path is **not**
unified. Wiring TYPE_CLASS IDs into 8-bit tokens is a **silent
identity change**.

## Classification

```text
STATUS = IDENTITY_DOMAIN_MISMATCH
```

TYPE_CLASS is a catalog class. LM ctx is an 8-bit token stream.
C9 HOLD_A is a frozen NID-era pack. None of these is the other
unless project authority defines an explicit FPGA-owned map.

Not UNIQUE_AUTHORITY_DEFINED.
Not UNIQUE_DATA_DERIVABLE (443 classes, 8-bit vocab, CLASS_ID>255).
Member NID as token = MULTI_MEMBER_AMBIGUOUS (R3A already measured).

# VOCAB_AUDIT — LM-06

Sources: `rtl/lm/a7lm06_pkg.sv`, `tiny_gpt803k_core.sv`,
`docs/contracts/A7-LM-06.md`, `A7-LM-06-CONFIRMATION.md`,
`tests/xsim/a7lm06_wmem.hex`, `qse_lexicon.svh`, U6 typeclass table.

## Geometry (RTL_FACT)

```text
law_id     = lm06-signsgd-v1
V          = 1024
C          = 128          // max context slots in core
D          = 128
H          = 4
L          = 4
FF         = 256
P_LM       = 802816
OFF_TOK    = 0            // V*D = 131072 INT8
OFF_POS    = 131072
pred width = 10 bit       // can emit 0..1023
```

Embedding index: `waddr = OFF_TOK + tok[i] * D + dim`.
`tok[]` is loaded from `ctx_pack[8*ii +: 8]` → **only 0..255** enter via V1 transport.

Tokens **256..1023** exist in WMEM, **unreachable** from 8-bit `ctx_pack`.
Widening the vocab index to carry CLASS_ID is **forbidden** in V1.

## Tokenizer / token meanings

There is **no** LM-06 tokenizer file, BPE, or token-name table in-repo.

Token IDs are **opaque INT8 indices** into the embedding table.

QSE lexicon (`qse-v1-lexicon-hdc-00`) is a **different** 60-word structured
lexicon (cls 1..4, small IDs). It is not the LM-06 vocab.

TYPE_CLASS CLASS_ID 1..443 is a **third** identity.

## Special / reserved tokens

None documented in `a7lm06_pkg` or LM-06 contracts.

Core: `ntok==0` → immediate `ST_DONE` (empty context), not a BOS/EOS token.

Every value 0..255 is a legal NID-low8 C9 byte. **No collision-free
opcode bank** exists inside 8-bit transport vs legacy C9.

## Max context length

| Path | ntok |
|---|---|
| LM-06 confirmation recipe | **1** (`ctx=[1]`) |
| C9 bind (`a7ng_native_ctx_bind`) | **8** (hardcoded `ctx_n_in=8`) |
| Core architectural max | **128** (`C`, `tok[ctx_idx+ii] < 128`) |
| ctx_we beat | 8 tokens per beat (`for ii=0..7`) |

## Existing training / ctx law

Confirmation (frozen before silicon, host-compare only):

```text
seed     = 2
context  = [1]
target   = 32
lr       = 3
opcodes  = K257 → K511 → K513, upload 802816, fold, one-full, persist
NOT      8-class CE, conversation, or TYPE_CLASS serialization
```

one_full expected pred=744 (that recipe). Gate14 C9 overlay uses ntok=8
NID-low8 packs; HOLD_A OUT 653 is that overlay after 20-fact graph lesson,
not the LM-06 confirmation recipe.

## Checkpoint provenance

```text
file   = tests/xsim/a7lm06_wmem.hex
bytes  = 2408448  (hex text of 802816 INT8)
SHA256 = c204e55909d99370387c479c74e28c15f285fddee20239459d7c0ec3373001e0
oracle = TinyGPT803k(seed=2), law lm06-signsgd-v1
LM-06 C3 bit SHA = 222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6
```

This checkpoint was **not** trained to interpret TYPE_CLASS descriptors.

## Forbidden encodings (owner lock)

```text
CLASS_ID as single LM token     FORBIDDEN  (16-bit vs 8-bit; >255)
low8(CLASS_ID) as LM token      FORBIDDEN
LEARN_KEY bytes as LM token     FORBIDDEN
member NID / first-member       FORBIDDEN
hash(CLASS_ID) → token          FORBIDDEN
```

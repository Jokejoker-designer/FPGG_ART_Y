# Law `a7ng-termgen-v0`

Binary HDC/VSA TermGen on 64-bit cues. DSP=0 (XOR / rotate / popcount tree).

## Primitives

| Name | Op |
|------|-----|
| BIND | XOR |
| PERMUTE | ROTL1 / ROTL8 / ROTL16 / ROTL32 |
| SIMILARITY | `sim8(a,b) = 64 - popcount(a⊕b)` |

## Terms

| Term | Formula |
|------|---------|
| entity_match | `sim8(query, node)` |
| relation_match | `sim8(query ⊕ ROTL1(relation), node)` |
| intent_match | `sim8(intent, ROTL16(node))` |
| context_match | `sim8(context, ROTL32(node))` |
| path_confidence | `sim8(path, ROTL8(query ⊕ node))` |
| learned_prior | memory passthrough |
| contradiction_penalty | `pop64((query⊕node) & path) >> 1` |

## Hard note

Do **not** use `sim(q⊕r, n⊕r)` — algebraically equals `sim(q,n)` and dead-strips `relation`.

## Pipeline

II=1 after fill; latency=2 (stage1 XOR/BIND, stage2 popcount→terms).

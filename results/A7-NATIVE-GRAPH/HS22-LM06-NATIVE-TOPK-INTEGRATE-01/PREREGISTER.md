# PREREGISTER — HS22-LM06-NATIVE-TOPK-INTEGRATE-01

**Status:** SEALED BEFORE CANDIDATE RTL  
**Owner:** Grok / Project B  
**Evidence class:** `XSIM` only  
**Board/COM12:** FORBIDDEN  
**Type:** implement (existence chain, not iron-law byte/latency)

| Field | Value |
|-------|-------|
| Gate ID | `HS22-LM06-NATIVE-TOPK-INTEGRATE-01` |
| Prerequisite | `HS22-LM06-NATIVE-CTX-FWD-00` R2 ACCEPTED; Project A memory contract v0 |
| Iron-law | **none** — existence of reducer→bind→pred; not an optimization gate |

## ONE UNKNOWN

Can frozen `a7ng_topk_wavefront_global` take **four** preregistered local-wave Top-8 updates, emit the query-global Top-8, and drive accepted `a7ng_native_ctx_bind` so a legal wave perturbation changes LM06 `pred`, **without** the TB driving bind `global_id_i`?

## Frozen hashes (must MATCH at close)

| File | SHA256 |
|------|--------|
| `a7ng_topk_wavefront_global.sv` | `D6D6882BD4C5505246C9B24CB95CEF66BE3BC1F0881545AEDCEC302B01C14B7B` |
| `a7ng_native_ctx_bind.sv` | `5CDBCC47E5D0CC0A4977EA916D4698E453B2EABBE5263FEAE627864F380D7803` |
| `tiny_gpt803k_core.sv` | `B8F485E5A98903A56C23BADEB30CD84451E728F42E64296343086E6D51351880` |

## CONTROL four local waves (n_scored=8)

Tie-break law `a7ng-topk-global-v1`: higher score, then lower `node_id`.

| Wave | ids | scores |
|------|-----|--------|
| 0 | 9,11,0,2,4,6,8,10 | 165,165,1,1,1,1,1,1 |
| 1 | 25,27,16,18,20,22,24,26 | 165,165,1×6 |
| 2 | 41,43,32,34,36,38,40,42 | 165,165,1×6 |
| 3 | 57,59,48,50,52,54,56,58 | 165,165,1×6 |

Independent merge (G₀ empty; G_{t+1}=Top8(G∪W)):

```text
after 0: 9,11,0,2,4,6,8,10
after 1: 9,11,25,27,0,2,4,6
after 2: 9,11,25,27,41,43,0,2
after 3 CONTROL global: 9,11,25,27,41,43,57,59  scores 165
```

Matches SOA sealed query-global IDs @165. Pack `3b392b291b190b09`.

## PERTURB (one legal local change)

Wave 0 last slot: `10@1` → `1@300`. Waves 1–3 unchanged.

Expected global: `1@300, 9,11,25,27,41,43,57 @165` (59 dropped). Pack `392b291b190b0901`.

## H_CANDIDATE / H_RIVAL / FALSIFIER

As assignment prompt. Direct TB drive of `a7ng_native_ctx_bind.global_id_i` is FAIL.

## Protocol

- Only **4th** merge (`merge_count==4` and `global_valid`) may start bind. Intermediate `global_valid` must not.
- After accepted bind start: poison live reducer-output bus on **negedge** before S_CTX; capture must stay accepted pack.
- Negative: four merges, `do_start=0` → no `start_fwd`, `pred` stable 0.
- CONTROL then PERTURB forwards: `pred` differ; packs differ.

## Verdicts (fixed)

| Class | Rule |
|-------|------|
| `PASS_NARROW` | hashes MATCH; 4-wave oracles exact; no direct bind GID; only final merge starts LM; neg stable; race-free capture; preds complete and differ; safety counters 0 |
| `FAIL` | any falsifier |

Not BOARD_PASS, not HS-02, not DDR/TermGen live production.

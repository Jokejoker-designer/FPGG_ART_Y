# _PREREG — U4A-R3-STRUCTURED-QUERY-ROUTER-00

Frozen before the rival run. Do not retarget thresholds after seeing numbers.
Do not change `qse-v1-lexicon-hdc-00`.

```text
GATE            = U4A-R3-STRUCTURED-QUERY-ROUTER-00
HEAD            = 8cb80953e4214fa9b221660ff3b98baeebdbd397
BRANCH          = grok-orch/v31-canonical-00
QUERY_LAW       = qse-v1-lexicon-hdc-00  (frozen; FPGA-owned keys)
EVIDENCE        = HOST_MODEL (+ qse keys already RTL-golden 98/98)
BIT             = NO
PROGRAM         = NO
COM12           = NO
U5              = CLOSED
SOC             = NO
FULL_SCAN       = NO
PHYS            = 4 untouched
```

## Why this gate

U4A-R2 recall@192=0.968 used synthetic `rec_keys(nid)` hash membership as gold.
That does not test query representation. U4A-R3 uses **label gold** and
**FPGA structured keys** (`k0={entity_id,intent_id}`, `k1={relation,context}`).

## Query keys

From U3Q-R3 extractor / twin (identical law):

```text
k0, k1, k2, k3
CRC is fingerprint only — never a routing table key
```

Tables:

```text
P2 : t0=k0, t1=k1
P4 : t0=k0, t1=k1, t2=k2, t3=k3
P8 : P4 plus k0^k1, k2^k3, k0+k2, k1+k3   (mix of FPGA keys, not host hash of nid)
```

Bucket = key % N_BUCKETS (N_BUCKETS power of two).

## Gold (independent, BEFORE router output)

**Label gold (quality):**
For a query text, gold = other corpus titles with the same `_PREREG` entity
family label (U3Q-R3 ENTITY_CANON). Overflowed titles stay in gold.

**Forbidden:** `relevant = set(union of admitted heads)`.

**Scale (N=800000) is occupancy only:**
coverage, overflow, bytes, skew. Do **not** call 800k hash-membership
or whole-entity-class recall "semantic recall".

## Metrics

```text
true recall@K = |label_gold ∩ cands[:K]| / |label_gold|
coverage      = unique stored nids / N_index
head_hit      = |label_gold ∩ stored_heads| / |label_gold|
bytes_q       = |cands|*16 + n_tables*16
```

## Frozen PASS / reject

```text
label_recall@16              >= 0.80
label_recall@64              >= 0.85
unrelated_query mean_cands that hit entity gold  (report; no freeze)
REJECT profile if index coverage < 0.20 (scale N=800000)
CAND_CAP = Pareto on label recall then min bytes; not hard-code 256
P8 rejected if coverage < 0.20 or label_recall@16 < 0.50
```

## Falsifiers

```text
QUERY_REPRESENTATION_LEAK   routing on crc16_dbg or host entity port
RETRIEVAL_RECALL_FAIL       label_recall@16 < 0.80
TAUTOLOGY_GOLD              gold built from admitted heads
FIRST_DIVERGENCE            stop, keep artifact, do not lower threshold
```

## Not this gate

U4 SoC, U5 800k silicon, bitstream, program, COM12, PHYS change, lexicon edit.

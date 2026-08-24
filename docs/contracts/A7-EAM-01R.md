# A7-EAM-01R — Multi-Index Episodic Router

**Status:** **BOARD_PASS / FROZEN** (01R-B randomized silicon). Router only. Not LM-07. Not DDR. Not 02A.  
**Board bit:** `build/out/arty_a7_eam01r.bit` SHA `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF`. Route WNS +0.908 / WHS +0.019.  
**Close:** `results/A7-EAM-01R/ladder_01rb.json` — 32 random keys, set-1-flip / theorem-r1 / unrelated FP=0, in-ball oracle disagree=0.  
**Law:** `eam01r-mih-v1`  
**Parent geometry:** 4096 records, 64-bit key, 128-bit vec, token/conf/age.  
**Authority:** Norouzi, Punjani, Fleet — *Multi-Index Hashing* (exact Hamming NN via substring tables).

## What changed

00G: one table `INDEX[key[7:0]]`. A 1-bit flip in the set byte → **wrong table → TP=0**.

01R: eight tables, one per key byte. Final HIT is **never** an index decision.

```
key bytes → 8 buckets → candidate IDs → dedup
        → fetch 64-bit key → XOR+popcount
        → d1, d2, margin
        → accept iff d1 ≤ HIT_MAX && margin ≥ MARGIN_MIN
```

## Theorem (why radius-1)

Split 64 bits into 8 bytes. If every byte has Hamming ≥ 2 then `d_H ≥ 16`.  
Therefore **`d_H(Q,K) ≤ 8` ⇒ at least one byte has d ≤ 1**.

Exact pass: 8 buckets.  
Fallback: each byte’s 8 Hamming-1 neighbors → ≤ 72 bucket probes.  
Miss only if the record was never indexed or the bucket overflowed (32 slots).

## Storage

| Block | Shape | Contents |
|-------|-------|----------|
| Record store | 4096 × 256 b (RTL) | full entry; **vec must be observed** (00B DCE lesson) |
| Index bank ×8 | 256 × 32 slots × 13 b | `{valid, record_id[11:0]}` |
| Seen-tag | 4096 × 8 | query-uid, skip duplicate IDs |

One record, eight index postings. Overflow of one bank does **not** delete the record.

## Defaults

`HIT_MAX=8`, `MARGIN_MIN=4`. Both UART-programmable. Unrelated 00G keys sat at d≈39 — reject must stay.

## Resource

**Estimate (not evidence):** ~28.4 (records) + ~23.1 (indexes) + 1 (seen) ≈ 53 RAMB36-eq.  
**Budget:** < 60 BRAM36-eq, < 10k LUT, 0 DSP, 100 MHz.

**OOC evidence** (`results/A7-EAM-01R/gates_01r.json`, post-route):

- 52 RAMB36 + 8 RAMB18 = **56 BRAM36-eq**
- Slice LUT **1252**, FF 1322, DSP **0**
- WNS **+0.633**, TNS 0 at 100 MHz
- Record store inferred **4096×243** (vec kept; 13 flag/tag bits DCE)
- Each index bank 8192×13 → 3×RAMB36 8K×4 + 1×RAMB18 8K×1 (not one 8K×18)

00B taught us not to trust nominal; these numbers are Vivado’s.

## Forbidden

Full-scan of 4096 keys. MIG/DDR. Overwrite `arty_a7_lm*.bit` / 00B bit. Claim LM-07.

## Implementation notes

- Index + seen BRAM init 0 (xsim X on `valid` would treat every slot as full).
- Seen-tag has a dedicated wait state. Same record lives in 8 banks; without dedup, `second_d == best_d` and `MARGIN_MIN` rejects every exact hit.
- Record fetch is `S_SEEN → S_RLAT → S_FLAT` (TDP read is registered). One cycle short scored the previous record.
- Index nominates only. Stale epoch / `!valid` records are skipped, not HITs.
- Overflow increments `ovf_n` for that bank and leaves the record in the store + other banks.
- Soft-reset bumps epoch; old index postings stay occupied (not reclaimed in 01R).
- TB keys are pairwise Hamming ≥ 16. Consecutive small integers (00G-style `base+i`) sit at d=2 and would fail `MARGIN_MIN=4` even on exact recall.

## Sibling lane

Semantic keys were **A7-EAM-02Q** (geometry **NOGO** on LM-06 hidden). Multi-cue bind is **A7-EAM-02M**. Dedicated encoder is **A7-EAM-03E**. 01R still accepts a 64-bit key. Do not glue LM-06 here. Do not retune this file for 02M/03E.

## Close (later)

xsim: exact hit; **set-byte 1-flip hits**; 8-in-one-byte hits; **1-per-byte d=8 (radius-1 theorem)**; 2-per-byte (d=16) misses; unrelated reject; overflow documented.  
Synth report: actual BRAM/LUT. Board sweep optional.  
Never write `arty_a7_lm*.bit`. Never overwrite 00B/00G bits.

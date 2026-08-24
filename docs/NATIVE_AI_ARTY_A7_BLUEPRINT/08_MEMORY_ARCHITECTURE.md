# 08 — DDR / BRAM Memory Architecture

> Execution state, corrections and the current status table live in
> [`00_CURRENT_AUTHORITY.md`](00_CURRENT_AUTHORITY.md).
>
> **feedback.md** + **BRAM_WORKING_MEMORY_SPEC.md** compliance (see `00_CURRENT_AUTHORITY.md` §22):
> `RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md`, `FEEDBACK_MD_COMPLIANCE.md`,
> `BRAM_WORKING_MEMORY_SPEC_COMPLIANCE.md`.

## 1. Hard constraint — naive stacking is FALSIFIED

Current routed blocks as separate designs (`POST_ROUTE`):

| block | BRAM |
|---|---:|
| A0.3 | 3 |
| 01R | 56 |
| 02M | 52 |
| LM-06 | 132 |
| naive sum | 243 / 135 |

Later SoC measurements confirm the same failure on other naive compositions:

| composition | BRAM | evidence class | artifact |
|---|---:|---|---|
| UA SoC 128 + frozen LM-06 132 | 260 / 135 | POST_ROUTE_FIT_LIMIT | `results/A7-NATIVE-GRAPH/TINYGPT-SOC/LIMIT_tinygpt_bram_fit.md` |
| consol 132 + TinyGPT-class LM-06 132 | 264 / 135 | FIT_LIMIT | `results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/LIMIT_tinygpt_consol.md` |

**NAIVE STACKING = FALSIFIED.** This is a measured architectural FAIL (HS-11), not an open estimate.

`UA128 + full LM06` is **not** a final architecture. LM-06 already owns `u_w` and `u_a`; that
composition double-counts the same functional memory.

## 2. Final memory principle

```text
DDR
  persistent large state:
  LM persistent weights, graph nodes, edges, episodes,
  indices, learned persistent state, checkpoints

BRAM
  bounded ACTIVE WORKING SET only:
    LM phase    - weight tile, activation tile, scratch/KV, snapshot working data
    GRAPH phase - candidates, frontier, Top-K evidence,
                  agent/path context, pending learning updates

LUTRAM / FF
  ultra-hot state, queues, control

DSP / LUT arithmetic
  compute
```

The objective is a **bounded** BRAM working set, ideally independent of total parameter count where
practical. It is **not** zero BRAM.

## 3. Required integrated layout

```text
DDR3
 ├─ LM weight image
 ├─ topic/node table
 ├─ edge table
 ├─ episode/fact payloads
 ├─ sparse router/index
 ├─ optional logical-agent cold contexts
 └─ evidence/replay buffers

BRAM shared pool
 ├─ frontier
 ├─ node hotset
 ├─ edge hotset
 ├─ top-K
 ├─ update-combine cache
 └─ LM transient tiles when shareable
```

## 4. LM-06 BRAM audit — DONE, and the result matters

LM-06 persistent INT8 weights are **already DDR-resident by contract**. The BRAM problem is the
LM-06 **working machinery**, not storage of the 802,816 persistent parameters. The phrasing
"move 802,816 weights from BRAM to DDR" is forbidden — it describes a migration that already happened.

Measured ownership of the 132 tiles (`POST_ROUTE`, 132 `BMEM` primitives enumerated from
`build/out/a7lm06_post_route.dcp`):

| owner | tiles | role |
|-------|------:|------|
| `u_a` | 66 | activation scratch |
| `u_w` | 64 | weight staging / working tiles |
| `u_snap` | 2 | snapshot machinery |
| **total** | **132** | working set, not persistent store |

Source: `results/A7-NATIVE-GRAPH/MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md`.

Decisive arithmetic: 64 tiles × 36 Kbit = 2.36 Mbit, while an 8-bit image of `P_LM = 802,816` is
6.42 Mbit. `u_w` holds at most ~37% of the model and therefore cannot be the weight store.

Do not assume 2-bit weights free 75% of BRAM. Whether they free anything depends on an unresolved
design question — is `u_w` sized by logical tile shape or by available BRAM? — that must be settled
by reading LM-06 buffer sizing, not inferred from tile counts.

## 5. Episode capacity examples

For 800,000 episodes:

```text
32 bytes/episode → 25.6 MB
64 bytes/episode → 51.2 MB
96 bytes/episode → 76.8 MB
```

Index and graph edges are additional.

Capacity is feasible in DDR-class storage. **DDR capacity is not the primary problem; DDR delivery
and locality is.**

Arty A7 raw link is ~16-bit @ 667 MT/s ≈ 1.33 GB/s theoretical raw (`ENGINEERING_ESTIMATE`). Do not
confuse theoretical link bandwidth with measured graph throughput. A 16-lane engine cannot
sustainably receive 16 fresh 16-byte NodeRecords every cycle directly from DDR — that would be
25.6 GB/s at 100 MHz, roughly 19× the theoretical raw link.

**ENGINEERING DIRECTION / NEEDS EXPERIMENT** (not completed evidence):

```text
DDR burst
  -> compact candidate/cue working set
  -> ping-pong buffer
  -> parallel compute wavefront
  -> Top-K
  -> full metadata fetch only where justified
```

## 6. Avoid full scan

Every query must report:

```text
candidate count
bytes read
bytes written
bursts
cache hit rate
```

If candidates scale linearly to 800k per query, retrieval architecture FAILS.

## 7. Two-stage fetch

Recommended:

```text
cheap compact candidate record
↓
score/prune
↓
only high-score candidates fetch adjacency/payload
```

## 8. Hot-shard strategy

Load the most relevant topic shard into BRAM and let many physical lanes reuse it. This is how FPGA compute parallelism can become useful despite limited DDR bandwidth.

## 8b. Ping-pong / working-set doctrine

```text
DDR burst -> BRAM tile A / tile B -> compute
with ping-pong overlap where evidence later supports it
```

Rejected: `DDR -> one individual weight -> one MAC`, and "zero-BRAM LM".

## 9. Phase sharing — ownership handover, not simultaneous access

Retrieval and LM generation are sequential phases. Naive simultaneous sharing — "GRAPH and LM both
access `u_a` at the same time" — is **unsuitable** and is listed as forbidden in the locked memory
doctrine (`results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`).

The correct protocol is an explicit ownership handover:

```text
GRAPH
  -> BLOCK_NEW_WORK
  -> DRAIN_PE
  -> DRAIN_QUEUE
  -> DDR_COMMIT_IF_DIRTY
  -> VERIFY_QUIESCENT
  -> OWNER_SWITCH
  -> LM
  -> DRAIN
  -> OWNER_SWITCH
  -> GRAPH
```

Ownership state concepts: `owner`, `epoch`, `valid`, `dirty`, `generation` where applicable. Stale
entries die by those fields; payload scrubbing on every switch is not required.

**Hard invariant:** one physical bank has at most one writer authority in one cycle.

**Status: FUTURE INDEPENDENT EXPERIMENT** (`bram_owner_00`, currently BLOCKED behind DDR wavefront
characterization and LM-06 working-set equivalence). This package must not claim it implemented.

Persistent graph/episode knowledge cannot be time-shared away; it must remain in DDR or another
persistent store.

## 9b. Training traffic is not inference traffic

```text
INFERENCE
DDR read -> tile -> compute

TRAINING
DDR read weights -> tile -> compute/update -> dirty tile -> coalesced DDR writeback
```

Do not estimate training throughput from read-only bandwidth. Future work should investigate dirty
tracking, coalesced writeback and burst writeback **before** per-weight DDR writes. Planning, not
PASS evidence.

## 9c. 01R / 02M migration rule

Physical memory migration must not silently retune semantic or retrieval law.

- **01R:** do not change Hamming authority, `HIT_MAX`, MIH semantics or candidate acceptance
  semantics in the same experiment as a memory migration.
- **02M:** do not change binding law, episode retrieval semantics or teacher-off behaviour in the
  same experiment as a memory migration.

Memory migration and law retuning are separate experiments (HS-25).

## 10. Memory integrity gates

- address bounds;
- no overlap between DDR regions;
- CRC/hash where useful;
- flush/reload test;
- reset/forget behavior;
- deterministic cache eviction;
- no host-selected winning address.

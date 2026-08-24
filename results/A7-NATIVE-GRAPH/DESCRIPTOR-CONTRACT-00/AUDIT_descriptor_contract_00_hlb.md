# HLB AUDIT — gate `descriptor_contract_00` (VERIFY_ONLY)

**Auditor:** `a7-hlb-auditor` · **Mode:** LAW_AUDIT / VERIFY_ONLY (no RTL/TB edited)  
**Verdict:** `HLB: CLEAN` — **0 violations**, 2 MINOR findings  
**Gate verdict:** **PASS** — frozen **104-bit** stage-1 descriptor  
**Evidence class:** LAW_AUDIT — not BOARD, not SOA RTL  
**Authority:** `DESCRIPTOR_CONTRACT_FREEZE.md` in this directory

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=descriptor_contract_00
```

---

## Scientific frame

| Slot | Content | Grade |
|------|---------|-------|
| OBSERVATION | Wavefront path fetches 16 B/cand (full NodeRecordV1); TermGen+scorer laws frozen; human rejected 96b as final | **EVIDENCE** |
| UNKNOWN | Which per-candidate fields does lawful stage-1 scoring consume? | **CLOSED** |
| H_CANDIDATE | Stage-1 requires `node_id`+`node_cue`+`learned_prior` = **104 b** | **SUPPORTED** |
| H_RIVAL | 96 b suffices (prior broadcast or omitted); `confidence` aliases prior | **FALSIFIED** |
| FALSIFIER | Golden with differing `learned_prior` changes rank if broadcast; scorer omits prior | **Did not fire on law** |
| UNIT | Per-candidate field trace (not cycles-as-queries) | **EVIDENCE** |
| CONTROL | `a7ng-termgen-v0` golden n=32; CONTRACT_FREEZE score law; mem_schema_v1 offsets | **EVIDENCE** |
| METRICS | 3 lawful fields; 5 NodeRecord tail fields rejected; 0 host violations | **EVIDENCE** |

---

## 1. Law trace — what stage-1 scoring consumes

**Definition (this gate):** “Stage-1 scoring” = first rankable integer score per candidate = TermGen (`a7ng-termgen-v0`) + scorer compose (`a7ng-scorer-v0`) before Top-K.

### Per-candidate (must be FPGA-owned memory)

| Field | RTL consumer | Bits |
|-------|--------------|-----:|
| `node_id` | `cand_id` → Top-K id/tie-break | 32 |
| `node_cue` | All TermGen XOR/ROTL families (`a7ng_termgen_lane.sv:46-52`) | 64 |
| `learned_prior` | Passthrough `prior_d1` → `terms_o.learned_prior` → scorer `+learned_prior` (`termgen_lane:44,88`; `scorer_lane:55`) | 8 |

### Query-context (not per-candidate DDR descriptor)

`query_cue`, `relation_cue`, `intent_cue`, `context_cue`, `path_cue` — broadcast inputs; classified QUERY-CONTEXT in prior `ddr_wavefront_00` HLB audit.

### H_RIVAL falsification — `learned_prior` is lawful per-candidate

1. **Frozen score law** includes `LearnedPrior` (`CONTRACT_FREEZE.md`).
2. **Golden oracle** (`termgen_oracle.py:49-59`, `golden_termgen.json`) varies `learned_prior` per vector; broadcast constant changes composed score when priors differ.
3. **`a7ng_pkg.sv:55`** comment: `memory prior byte; passthrough (not host-composed)`.
4. **`NG_DDR_PRIOR_BASE`** — FPGA-owned per-node prior region (`a7ng_pkg.sv:18,27-29`).
5. **Compact 104b layout** already reads prior per record (`a7ng_wavefront_mig_top.sv:196`).

Broadcast `learned_prior_i` in `a7ng_ddr_wavefront_top.sv:255` is a **test wiring artifact**; it does **not** prove prior may be omitted from the descriptor contract.

### H_RIVAL falsification — `confidence` ≠ `learned_prior`

NodeRecordV1 `confidence` is u16 @ offset 12 (`MEM_SCHEMA_V1.md`). Lawful `learned_prior` is i8 `term_t`. No RTL path maps confidence into TermGen today. Aliasing would be a **schema violation**, not a shortcut.

---

## 2. Host boundary — if host code were deleted, is the freeze still true?

**Yes.** The freeze is a **structural law claim** traced from RTL + golden oracle + CONTRACT_FREEZE. No host file computes per-candidate scores, winners, or cues for the production FPGA path audited here.

### Host files reviewed

| File | Role | Classification |
|------|------|----------------|
| `tests/xsim/termgen_oracle.py` | Golden generator / verifier | METRIC-EVAL-ONLY — not on board path |
| `tests/xsim/tb_a7ng_ddr_wavefront.sv` `pack_node()` | DDR preload pattern | MEMORY-PRELOAD — does not drive scorer inputs |
| `python/native_graph/train_v2_harness.py` | TRAIN harness | Forbids `winner` in payload surface (grep) — no descriptor scoring |

**No VIOLATION:** host does not compute gradient, winner, address, way, hash, or next-token from descriptor fields for FPGA credit.

### Static packing ≠ host winner

Preload patterns that place bytes in DRAM are **MEMORY-PRELOAD** (same class as `ddr_wavefront_00` HLB). The FPGA still reads records and computes scores internally. This is not a prompt→answer map.

---

## 3. Host → FPGA payload surface (retrieval path)

| Field | On production UART path this gate? | Class |
|-------|-----------------------------------|-------|
| Query bytes / token ids | TRAIN/EVAL only (other gates) | TOKENIZE / QUERY-CONTEXT |
| Supervision reward | TRAIN only | SUPERVISION |
| `node_id`, `node_cue`, `learned_prior` per candidate | **Fetched by FPGA from DDR/BRAM** | PER-CANDIDATE MEMORY |
| Precomputed score / winner / address | **Forbidden** | — |
| Gradient / weight delta | **Forbidden** | — |

---

## 4. Findings

### [MINOR] NodeRecordV1 container vs semantic descriptor mismatch

- **where:** `MEM_SCHEMA_V1.md` NodeRecordV1 16 B vs frozen 104 b semantic subset  
- **what:** SOA gate must not confuse “16 B beat” delivery with “104 b consumed”  
- **claim invalidated:** None (documentation clarity)  
- **fix:** Cite `DESCRIPTOR_CONTRACT_FREEZE.md` in `ddr_cue_soa_00` preregister

### [MINOR] Two cue-widen rules in flight

- **where:** `cue-replicate-v0` vs `cue-complement-v0`  
- **what:** Delivery widen differs between wavefront tops; TermGen law identical  
- **claim invalidated:** None for HLB  
- **fix:** SOA gate must declare one widen `law_id` per integration bitstream

---

## 5. Parameter accounting (kept separate)

| Quantity | Value | Note |
|----------|------:|------|
| `P_LM` | 802816 | LM-06 trainable weights |
| `P_encoder` | 9216 | EAM encoder (parked lane) |
| `P_total_trainable` | reported separately | **Never sum with episodes** |
| `N_episodes` | learned memory records | not parameters |
| `episode_storage` | DDR `NG_DDR_EPISODE_BASE` | not parameters |
| `index_storage` | DDR `NG_DDR_INDEX_BASE` | not parameters |
| Stage-1 descriptor | **104 bits / candidate** | **Not** added to parameter headline |

No archive text sums episodes into `P_total_trainable`.

---

## 6. Gate verdict

```text
HLB: CLEAN
GATE: PASS
STAGE1_DESCRIPTOR_BITS: 104
FROZEN_FIELDS: node_id(32) + node_cue(64) + learned_prior(8)
NEXT: ddr_cue_soa_00 (parent dispatch)
BOARD_PASS: none
SOA_RTL: none (blocked before this gate; now unblocked for planning)
```

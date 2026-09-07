# OWNERSHIP — U7A current RTL (do not invent names)

```text
GATE = U7A-ROOT-B-REACHABILITY-REAUDIT-00
HEAD = 930c70747e342d9da57a4d553d89bb3e12c48333
RTL_EDIT = NO
```

Source files cited below are the owners. Duplicate owners are marked.

## Retrieval object (U6 typeclass XSim top)

| Role | Actual owner | Ports / identity |
|------|----------------|------------------|
| query decision | `a7ng_query_struct_extract` | eid/iid/rid/xid + bind flags |
| selected CLASS_ID | `a7ng_typeclass_scan` | `cand_id_o[15:0]` CLASS_ID 1..443 |
| raw member/provenance | TYPE_CLASS row `member_ptr` / `member_count` | provenance only; not Top-K id |
| Top-K identity | `a7ng_topk_stream_minheap` via U6 top | `heap_id[15:0]=CLASS_ID`, `[31:16]=0` |
| retrieval done | `a7ng_u6_typeclass_retrieval` | 1-cycle `done_o` after last drain beat |

This top has **no** `reward_*`, `txn_*`, `upd_*`, `persist_*`, `ddr_*` ports.

## Learning / persistence (current baseline — NOT TYPE_CLASS)

| Role | Actual owner | Identity used |
|------|----------------|---------------|
| query decision (SoC graph) | `a7ng_learned_prior_graph` | `query_id_i[7:0]` **qid**, not CLASS_ID |
| selected candidate | `cand_nid(qid,ci)` in same file | hardcoded `32'h20+i` / `40+i` / `80+i` |
| subject/object for learn | `cand_s` / `cand_o` / `subj_a` | `32'hA000+i` etc. **not** CLASS_ID, **not** NID catalog |
| pending transaction | `a7ng_feedback_resolver` | `{gen,seq}` `txn_o[15:0]` |
| reward acceptance | `a7ng_feedback_resolver` | host `reward_i` + `txn_echo_i` |
| learned-state update | `a7ng_context_delta` → `a7ng_learned_prior_store` | `{subj[31:0],rel[7:0],obj[31:0]}` |
| dirty / BRAM write | `a7ng_learned_prior_store` `ram_we` / `wrote` | working-set 32 slots |
| store allocation | same, `have_free` / `first_free` | vis_w stamp |
| DDR write issue | store `ddr_req_o`+`ddr_we_o` in P_FLUSH | SchemaV2 two beats |
| DDR write completion | `ddr_ack_i` | TB/MIG modeled |
| persist_done | **DUPLICATE** | `a7ng_learned_prior_store.persist_done_o` AND `a7ng_persist_gen_fast.persist_done_o` |
| success/ack | **DUPLICATE / SPLIT** | G1 `ack_valid_o`/`ack_o` (consume/orphan/dup/…) AND store `c7_ack_valid_o`+`ack_count`+`persist_done_o` |
| generation/epoch | store `live_gen` / `train_reset_i` | 8-bit stamp in vis_w |

`a7ng_learned_prior_graph` instantiates G1+G2+store. `a7ng_causal_learn_fast` / `a7ng_persist_gen_fast` is a **second** persist machine (16 slots, `g_subj(slot)` not SchemaV2 two-beat). Duplicate implementation.

## Required chain vs actual

```text
CLASS_ID
  → (NO WIRE)
pending transaction        G1 txn, keyed by latched {subj,rel,obj} from qid tables
  → selected learning target  {subj,rel,obj} 32/8/32, NOT CLASS_ID
  → mutable state             store BRAM pri/pen/stp
  → dirty                     ram_we / wrote
  → persistence issue         P_FLUSH two-beat DDR (only on flush, not on every upd)
  → persistence commit        ddr_ack per beat; P_UPD persist_done does NOT wait DDR
  → completion/ack            G1 ACK_CONSUME at reward accept; store persist_done at P_UPD end
```

**P_UPD does not issue DDR.** Working-set BRAM updates in place. DDR is flush/reload/inval. So "WRITE_COMMITTED" for an ordinary reward is **BRAM `wrote`**, not DDR.

## Duplicate owners

1. `persist_done_o` — store vs persist_gen_fast
2. `c7_addr_o` — store vs persist_gen_fast vs causal_learn_fast (all `subj[15:0]`, OBSERVE_ONLY)
3. Top-K — U6 typeclass heap (CLASS_ID) vs learned_prior_graph heap (qid-derived nid)
4. `ack` — G1 `ack_o` vs store `ack_count`/`c7_ack_valid_o`

## TYPE_CLASS → learning

```text
REACHABILITY = NOT_REACHABLE
```

No RTL net from `topk_class_id_o` / `a7ng_typeclass_scan` into G1 latch, G2, or store `upd_subj_i`.

Minimal integration for a future U7 (not this gate, not implemented):

```text
U6 topk_class_id_o[0]
  → explicit CLASS_ID→{subj,rel,obj} map (must be frozen; do not alias CLASS_ID as NID)
  → G1 latch_valid
  → existing txn/reward/store
```

Do **not** treat CLASS_ID as episode_id, subject ID, object ID, or DDR member address.

## Host semantic

G1 allows host: `reward_i`, `txn_echo_i`. Host must not supply CLASS_ID/NID/address. Graph qid and cand_* tables are FPGA ROM, not host.

## Timing residual (carry, not this unknown)

```text
HIGH_RISK_ARCHITECTURAL_HAZARD = U6_TYPECLASS_MINHEAP_TIMING
OOC WNS = -4.103 ns @ 10 ns estimate
```

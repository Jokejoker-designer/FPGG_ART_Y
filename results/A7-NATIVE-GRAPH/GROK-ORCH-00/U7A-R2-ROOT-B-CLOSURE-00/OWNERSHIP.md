# OWNERSHIP — U7A-R2 after R1

```text
BASELINE_UNDER_AUDIT = a7ng_learned_prior_graph → a7ng_learned_prior_store (R1 law)
```

## Producers

| Signal | Producer | When | Meaning |
|--------|----------|------|---------|
| G1 `ack_o==CONSUME` | `a7ng_feedback_resolver` | reward+txn match while pending | TRANSACTION_CONSUMED, not BRAM |
| G1 ACK_ORPHAN/LATE/DUP | same | no pending / wrong txn / replay | not store commit |
| `persist_done_o` P_UPD | `a7ng_learned_prior_store` R1 | `wrote\|\|ram_we` | STORE_COMMITTED (Object B) |
| `persist_nak_o` P_UPD | same | no BRAM write | fail completion, not success |
| `c7_ack_valid_o` P_UPD | same | same as persist_done success | observe-only companion |
| `ack_count` / `commit_seq` | same | only on BRAM commit | store observability |
| `persist_done_o` P_FLUSH | same | last SchemaV2 beat ACK | Object C DDR flush complete |
| `persist_done_o` P_CLR/BOOT/RELOAD | same | op complete | not BRAM learn commit |
| `persist_done_o` | **`a7ng_persist_gen_fast`** | own P_UPD/P_DIG tail | **not on graph baseline** |

`persist_done_o` on the store is **phase-polymorphic**. Consumers must not treat boot/flush pulses as P_UPD BRAM success.

## persist_gen_fast classification

```text
A. Instantiated on a7ng_teacher_off_soc_xsim (and unit TBs).
   NOT instantiated on a7ng_learned_prior_graph or a7ng_g1g5_cofit.
B. Cannot reach graph persist_done_o / UART C7 of the G14 graph top.
C. Mutually exclusive top vs learned_prior_store graph.

CLASS = DISCONNECTED   (from authoritative graph baseline)
        LEGACY_RIVAL   (teacher_off_soc_xsim only; not patched in R2)
```

g1g5_cofit comment: C9 IDs = learned graph TopK, **not persist FAST IDs**.

If a later gate promotes teacher_off_soc_xsim as live learning authority, that is a **new unknown** (FAST persist_done still ungated). Not this R2 object.

## TYPE_CLASS

```text
a7ng_u6_typeclass_retrieval has no reward/txn/upd/persist ports.
TYPE_CLASS→learning = NOT_REACHABLE
```

## Objects (do not collapse)

```text
A TRANSACTION_CONSUMED   G1 ack
B STORE_COMMITTED        P_UPD persist_done (R1)
C DDR_FLUSH_COMMITTED    P_FLUSH persist_done (SchemaV2 both beats)
D EPOCH                  live_gen / train_reset
```

# RESULTS — U7A-ROOT-B-REACHABILITY-REAUDIT-00

```text
RESULT = FAIL
CLASS  = CONFIRMED_DEFECT
XSIM   = 28655 ns  marker U7A_ROOTB_FAIL
```

## Reachability

```text
TYPE_CLASS → G1/store = NOT_REACHABLE
```

U6 `a7ng_u6_typeclass_retrieval` has no reward/txn/upd/persist ports.
TB did not fake a wire. Decoy CLASS_ID=57 never drives `upd_subj_i`.

## Directed falsifiers (current baseline store/G1)

| Case | Result |
|------|--------|
| duplicate G1 reward | ACK_CONSUME then ACK_DUP; `n_consume=1` |
| store-full 33rd distinct key | **FAIL** `persist_done` + `ack_count++`, `commit_seq` unchanged, lookup miss |
| reset after SchemaV2 identity beat | BRAM lookup miss (no false committed row) |
| C7_ADDR | `0x03012340` for subj `0x00011234` (base+{low16,4'h0}); OBSERVE_ONLY not proof |
| CLASS_ID vs subj 57 | numeric 57 is a store key, not retrieval CLASS_ID |

## First divergence

```text
SYMPTOM                 = persist_done/c7_ack_count success on 33rd distinct update with no BRAM write
FIRST_DIVERGENCE        = CONFIRMED_DEFECT persist_done/ack_count without BRAM commit (store full, wrote=0)
VIOLATED_INVARIANT      = SUCCESS ⇔ INTENDED_STATE_TRANSITION_COMMITTED
ARCHITECTURAL_OWNER     = a7ng_learned_prior_store P_UPD (slot_i==32 tail)
DUPLICATE_IMPLEMENTATIONS = persist_done also in a7ng_persist_gen_fast
DOWNSTREAM_EFFECTS      = U7 cannot treat persist_done/ack as commit; Gate14 SoC Root-B remains open
SMALLEST_NEXT_EXPERIMENT = one-line law: persist_done/c7_ack only if wrote==1 (or explicit NAK). Do not mix TYPE_CLASS integration in the same patch.
```

G1 `ACK_CONSUME` is reward-accept into consume, **before** store. Documented, not inferred as persist commit.

P_UPD does **not** issue DDR. Ordinary reward commit is BRAM `wrote` only. DDR is flush/reload.

## Residuals carried

```text
HIGH_RISK_ARCHITECTURAL_HAZARD = U6_TYPECLASS_MINHEAP_TIMING  WNS=-4.103 ns
C7_ADDR = OBSERVE_ONLY OPEN
TYPE_CLASS_TO_LEARNING = NOT_REACHABLE
```

No RTL patch this gate. No Q-head. No BIT. No PROGRAM. U7 CLOSED.

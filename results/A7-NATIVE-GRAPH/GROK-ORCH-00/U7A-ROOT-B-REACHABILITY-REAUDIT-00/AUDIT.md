# AUDIT — U7A Root-B reachability under TYPE_CLASS identity

```text
GATE                 = U7A-ROOT-B-REACHABILITY-REAUDIT-00
RTL_EDIT             = NO
XSIM_NEW             = NO (reuse U6-TYPECLASS 134665 ns PASS)
BIT                  = NO
PROGRAM              = NO
```

## 1. Objects (must not merge)

| Object | Identity | Completion signal | In bit 1F0F2ABB? |
|--------|----------|-------------------|------------------|
| `a7ng_u6_typeclass_retrieval` | CLASS_ID[15:0], zero-extended heap id | 1-cycle `done_o` after last Top-K drain beat | **NO** |
| Gate14 SoC TinyGPT WDMA / persist | qid / learned_prior / DDR prior | `ack_count++` / `persist_done` / `m_done` | **YES** (historical) |

U6B board smoke proved Gate14 **substrate**, not TYPE_CLASS silicon retrieval.

## 2. U6 typeclass completion law (`RTL_FACT`)

From `rtl/native_graph/integrate/a7ng_u6_typeclass_retrieval.sv`:

```text
S_WALK  → (scan complete, overflow/trunc latched)
S_PAD / S_FINLAST → heap in_last
S_DRAIN → capture topk_id_o[hp_idx], topk_class_id_o, topk_sc_o on each hp_ov
nst = S_DONE iff hp_ov && hp_idx == K-1
done_o <= (nst == S_DONE)     // same posedge as last Top-K slot NBA
S_DONE → S_IDLE next cycle
```

Overflow is latched **before** pad/drain, when walk completes:

```text
if (st==S_WALK && (scan_done || w_done_hold) && !accepting_cand)
  retrieval_overflow_o <= scan_ovf
  retrieval_trunc_o    <= scan_trunc
```

Scanner `q_done` during MAT/SC/HP is held (`w_done_hold`). `done_o` cannot fire
from scanner-done alone.

XSim `U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS` CUT G: TB samples Top-K after `done`.
CLASS_ID streams, scores, overflow (cap8 emit=8 trunc=39) matched independent gold.

```text
TYPECLASS_XSIM_COMPLETION ⇔ CLASS_ID Top-K + overflow commit  = CONFIRMED
EARLY_DONE on this object                                   = NOT observed
ACK-without-commit on this object                           = NOT constructed
```

`done_o` is a **pulse**, not a sticky UART ACK. Consumer must sample Top-K
on/after that edge. Latches persist until the next query overwrites them
in DRAIN (IDLE→WAITQ does not zero Top-K). That is not ACK≠commit; it is
a one-cycle done strobe with held result registers.

## 3. SoC Root-B (historical, unchanged)

G14-ROOT-B-TXN-AUDIT-00:

```text
ROOT_B_PARTIALLY_CONFIRMED
no single host-visible txn identity request→RAM write→retirement
ack_count++ / persist_done can fire with wrote=0 (LATENT)
WDMA_PROTOCOL_AMBIGUOUS (no m_go_ready; silent overflow latent)
```

That SoC does **not** instantiate `a7ng_u6_typeclass_retrieval`.
Reprogramming `1F0F2ABB` is forbidden (`REPROGRAM_AGAIN=NO`).

```text
SOC_ROOT_B_CLOSED     = NO
SOC_TYPECLASS_IDENTITY= NO
```

## 4. C7_ADDR residual (still OPEN)

`RESIDUAL-C7-ADDR-OBSERVE-ONLY-00`:

```text
C7_ADDR = NG_DDR_PRIOR_BASE + {subj[15:0], 4'h0}
OBSERVE_ONLY, not canonical identity
NOT CLASS_ID
```

U7A does **not** close this residual. Do not treat C7_ADDR as TYPE_CLASS.

## 5. Reachability matrix

| Hazard | U6 typeclass XSim | SoC 1F0F2ABB |
|--------|-------------------|--------------|
| done without Top-K last slot | NOT constructed; same-cycle latch | n/a (module absent) |
| done without overflow latch | NOT constructed if walk completed | n/a |
| ACK without architectural write | n/a (no WDMA in this top) | LATENT (wrote=0 persist_done) |
| CLASS_ID truncated to 8 bits | NOT (heap [31:16]=0, [15:0]=CLASS_ID; >255 survived) | n/a |
| NID as Top-K identity | DISCONNECTED | still qid/learned_prior |
| C7_ADDR as identity | not used | OBSERVE_ONLY OPEN |

## 6. Verdict

```text
U7A_REAUDIT            = COMPLETE
TYPECLASS_XSIM_DONE    = CONFIRMED  (completion ⇔ CLASS_ID Top-K commit)
SOC_ROOT_B             = PARTIALLY_CONFIRMED  (unchanged; different object)
C7_ADDR                = OPEN OBSERVE_ONLY
U7                     = CLOSED
U8                     = CLOSED
GATE14_PASS            = NO
```

Do **not** open U7. U7 would require a TYPE_CLASS identity that exists on
the SoC completion path. That integration is not this reaudit and is not
authorized as a silent follow-on.

Claim only:

> On the U6 TYPE_CLASS XSim object, done is the last Top-K CLASS_ID
> drain commit, not an ACK-without-commit. The programmed Gate14 SoC
> is a different object; Root-B stays partially confirmed.

Not claimed: U7, learning, silicon TYPE_CLASS retrieval, board, Gate14.

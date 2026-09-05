# PREREG — PERSIST-IDENTITY-SCHEMA-V2-00

Opened because PERSIST-IDENTITY-WIDTH-00 FAIL (BLOCKER=PERSIST_IDENTITY_ALIAS).

```text
GATE            = PERSIST-IDENTITY-SCHEMA-V2-00
BASE            = bf59f05778305e88586e0723ecc2625b2a38569b
RTL_EDIT        = YES (learned_prior_store flush/reload record only)
OPTION          = A  two-beat record, full 32-bit subj + 32-bit obj
NOT             = 16-bit ID force; hash-as-identity; router; AXI dir; U5
BIT             = NO
PROGRAM         = NO
COM12           = UNTOUCHED
U4_AXI          = CLOSED
U5              = CLOSED
GATE14_PASS     = NO
ORACLE          = HOLD_A C9=8382238122802120 OUT 653/689/237/60
```

## Record law (option A)

```text
addr 0              : epoch header  ng_epoch_pack(live_gen)   UNCHANGED
addr 1+2*s          : {subj[31:0], obj[31:0]}                 s = 0..31
addr 2+2*s          : {rel[7:0], pri[7:0], pen[7:0], stp[7:0], 32'd0}
```

occ recovered as `stp != 0` (unchanged).

## Pass

Replay PERSIST-IDENTITY-WIDTH-00 directed vectors:

low IDs, S1/O1, S2/O2, S3/O3, alias pair, flush/kill/reload.

```text
canonical hit after reload
alias miss
S1 distinct from S2
pri/pen preserved
C7 commit/ack still increments
```

Then C9 graph unit regression (no OUT retarget).

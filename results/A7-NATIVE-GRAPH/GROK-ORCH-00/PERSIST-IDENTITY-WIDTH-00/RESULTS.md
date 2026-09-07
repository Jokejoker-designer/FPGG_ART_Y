# RESULTS — PERSIST-IDENTITY-WIDTH-00

```text
RESULT             = FAIL
EVIDENCE_CLASS     = RTL_FACT + XSIM
FIRST_DIVERGENCE   = DDR persistence serialization
VIOLATED_INVARIANT = canonical learned identity must survive persistence bit-exact
BLOCKER            = PERSIST_IDENTITY_ALIAS
RTL_EDIT           = NO
```

PRIMARY_ANSWER: No. Identities above 0xFFFF do not survive flush→DDR→kill→reload.
The current 64-bit record packs only `subj[15:0]` and `obj[15:0]`. Reload
zero-extends. Low-16 collisions become the same stored key.

This is **not** assumed from RTL text. It is reproduced on the directed vectors.

## Sequence (every high-ID case)

learn → lookup before flush → flush → capture DDR → BRAM kill → reload
→ lookup original → lookup alias → compare pri/pen → C7 commit/ack

## Low-ID control (PASS)

`S_LO=0x11` `O_LO=0x22` `rew=3`

| phase | hit | pri |
|-------|-----|-----|
| before flush | 1 | 3 |
| after kill | 0 (`ws_live=0`) | — |
| after reload | **1** | **3** |

DDR slot: `0011002201030001` = `{subj16=0011, obj16=0022, rel=01, pri=03, pen=00, stp=01}`

Commit/ack: seq 0→1, cnt 0→1. Persist path is alive for IDs that fit in 16 bits.

## S1 high-ID (FAIL)

`S1=0x0001_1234` `O1=0x0003_5678` `rew=4`

| phase | lookup | hit | pri |
|-------|--------|-----|-----|
| before flush | S1/O1 | 1 | 4 |
| DDR payload | — | `1234567801040001` | packed subj16=`1234` obj16=`5678` (lost `0001`/`0003`) |
| after reload | S1/O1 | **0** | 0 |
| after reload | alias `0x0000_1234`/`0x0000_5678` | **1** | 4 |

C7 observe addr for S1 = `03012340` (also `subj[15:0]`). Observe-only; lookup uses BRAM 32-bit until flush.

## S1 vs S2 alias pair (FAIL)

`S2=0x0002_1234` `O2=0x0004_5678` `rew=5`

DDR after flush:

```text
slot2 = 1234567801040001   pri=4   (S1 truncated)
slot3 = 1234567801050001   pri=5   (S2 truncated)
same 16-bit subj/obj slice = 1
```

After reload:

| lookup | hit | pri |
|--------|-----|-----|
| S1/O1 | 0 | 0 |
| S2/O2 | 0 | 0 |
| alias 0x1234/0x5678 | 1 | 4 (first truncated slot) |

Two distinct canonical facts collapse to one 16-bit key. S2 pri=5 is stranded
behind the first alias match. False miss of both originals; false hit on alias;
pri cross-contamination.

## S3 sentinel-high (FAIL)

`S3=0x000C_34FF` `O3=0x000B_EEFF`

DDR `34ffeeff01020001`. After reload: canonical miss, alias `0x34FF`/`0xEEFF` hit pri=2.

## Causal RTL (unchanged this gate)

Flush (`a7ng_learned_prior_store.sv`):

```text
ddr_wdata_o <= {q_subj[15:0], q_obj[15:0], q_rel, q_pri, q_pen, q_stp};
```

Reload:

```text
obj  = {16'd0, ddr_rdata_i[47:32]}
subj = {16'd0, ddr_rdata_i[63:48]}
```

BRAM `pack_e` still holds full 32-bit subj/obj. The loss is **serialization**.

## Not this gate

No AXI directory. No U5. No bit. No COM12. No C9/OUT retarget.
No 16-bit ID force. No hash-as-identity.

NEXT = **PERSIST-IDENTITY-SCHEMA-V2-00** (one repair gate).

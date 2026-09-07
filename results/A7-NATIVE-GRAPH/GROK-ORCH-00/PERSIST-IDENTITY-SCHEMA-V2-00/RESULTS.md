# RESULTS — PERSIST-IDENTITY-SCHEMA-V2-00

```text
RESULT           = PASS
EVIDENCE_CLASS   = RTL_FACT + XSIM
OPTION           = A  two-beat full 32-bit subj/obj
RTL_EDIT         = YES (learned_prior_store flush/reload only)
```

Directed width vectors replayed against SCHEMA-V2:

| case | before | DDR identity | after orig | after alias | pri |
|------|--------|--------------|------------|-------------|-----|
| LO 0x11/0x22 | hit pri=3 | `0000001100000022` | hit pri=3 | — | preserved |
| S1 0x00011234/0x00035678 | hit pri=4 | `0001123400035678` | **hit pri=4** | **miss** | preserved |
| S2 0x00021234/0x00045678 | hit pri=5 | `0002123400045678` | **hit pri=5** | miss | preserved |
| S3 0x000C34FF/0x000BEEFF | hit pri=2 | `000c34ff000beeff` | **hit pri=2** | miss | preserved |

S1 DDR ≠ S2 DDR (`same=0`). N_DIVERGENCE=0.

`PERSIST_IDENTITY_SCHEMA_V2_PASS`

## C9 unit regression (not OUT/silicon)

`C9_LEARNED_PRIOR_GRAPH_XSIM_PASS fails=0 facts=20`

```text
C9PACK HOLD_A 8382238122802120
C9PACK UNREL  8786858483828180
C9PACK CONTRA 2322832182208180
C9PACK HOLD_B 8382438142804140
```

HOLD_A C9 frozen value **unchanged**. OUT 653/689/237/60 not re-run (PROGRAM=NO, no board).

## Residual

C7 observe address still uses `upd_subj_i[15:0]`. That is not the lookup key.
Lookup identity is full 32-bit in BRAM and now in DDR.

## Not opened

U4 AXI directory. U5. BIT. COM12.

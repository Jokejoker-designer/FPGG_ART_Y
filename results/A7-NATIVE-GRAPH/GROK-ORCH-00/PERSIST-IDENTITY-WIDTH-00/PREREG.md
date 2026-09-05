# PREREG — PERSIST-IDENTITY-WIDTH-00

Frozen **before** the directed XSim. Do not retarget after a candidate run.

```text
GATE            = PERSIST-IDENTITY-WIDTH-00
BASE            = a0a923d02153fb7a396e03edc6f055955ad45e41
REMOTE_HEAD     = a0a923d02153fb7a396e03edc6f055955ad45e41
R6_PUBLISHED    = 884aa8c + a0a923d on fpgg/grok-orch/v31-canonical-00
RTL_EDIT        = NO (measure current flush/reload)
BIT             = NO
PROGRAM         = NO
COM12           = UNTOUCHED
U4_AXI          = CLOSED
U5              = CLOSED
GATE14_PASS     = NO
ORACLE          = HOLD_A C9=8382238122802120 OUT 653/689/237/60
```

PRIMARY_UNKNOWN:
Can canonical subject/object identity above 0xFFFF survive
update → store → flush → DDR → BRAM kill → reload → lookup
bit-exact without alias?

## Directed identities (prereg)

```text
S1 = 32'h0001_1234    S2 = 32'h0002_1234   # collide in [15:0]
O1 = 32'h0003_5678    O2 = 32'h0004_5678
S3 = 32'h000C_34FF    O3 = 32'h000B_EEFF
S_LO = 32'h0000_0011  O_LO = 32'h0000_0022  # control < 0xFFFF
REL  = 8'h01
```

## Pass law

```text
subj_before == subj_after
obj_before  == obj_after
S1/O1 distinct from S2/O2 after reload
no alias / false hit / false miss / cross-contamination
```

Do not assume FAIL. Reproduce causally. Do not patch this gate.
Do not force IDs to 16-bit. Do not use a lossy hash as identity.

If FAIL: open PERSIST-IDENTITY-SCHEMA-V2-00 only. Do not open U4 AXI / U5.

# RESULTS — U3Q-R2-QUERY-QUALITY-00

```text
EXTRACTOR     = FPGA-owned qfe-v1-crc16-mix-00 (unchanged)
HOST_HASH     = NO
LAW_SELFCHECK = PASS (same-in-same-out, Q0 k0=B72B). NOT semantic recall.
ENTITY_K12    = 0/30 variants share canonical 12-bit K0 bucket
INTENT_K12    = 0/13
UNRELATED     = 0/28 collisions (below chance)
PERTURB_DELTA = 5/5 (1-byte edit always moves keys)
RETRIEVAL     = label-gold recall@16 = 0.0, @64 = 0.0
SEMANTIC_AUTH = OPEN
```

CRC token keys are a **lexical hash**, not an entity/intent embedding.
Paraphrases of the same HVAC label do not land in the same 12-bit bucket,
so downstream label-gold retrieval is zero. That is a measurement, not a
retarget invitation.

Spot TB `tb_u3q_r2_spot.sv` XSim **U3Q_R2_XSIM_SPOT_PASS** (8/8 held-out).

Marker: `U3Q_R2_MEASURE_PASS` + `U3Q_R2_SEMANTIC_AUTHORITY_OPEN` +
`CRC_SELFCHECK_NOT_SEMANTIC_RECALL`

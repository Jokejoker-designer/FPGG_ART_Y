# RESULTS — U7A-R3B XSim

```text
CHILLER  emit=29 learned=8 CLASS_ID58 key=0x5443003A/0x01/0x01000000 pri=2 score=10
CHILLER2 same key pri=4 score=12 (accumulate)
WATER    emit=10 learned=8 CLASS_ID58 key=0x5443003A/0x09/0x01000001 pri=2 score=18
LOOKUP   chiller HIT pri=4; water HIT pri=2; unbound-mask MISS
DUCT     high_cid=275 subj=0x54430113 learned=8
PIANO    emit=0 learned=0
C7_OBS   addr=0x03001130 seq=32 ack=32
MARKER   U7A_R3B_TYPECLASS_TO_LEARN_REACHABILITY_PASS
TIME     61545 ns
```

Chain proven (XSim, wrapper DUT):

```text
U6 Top-K CLASS_ID
→ FPGA LEARN_KEY_CLASS_CONTEXT_V1
→ G1 pending txn
→ scalar reward (TB/teacher, not identity)
→ G2 delta
→ learned_prior_store (SchemaV2 full32)
→ lookup prior
→ scorer_lane.learned_prior
```

Host n_host_or = 0. RAW_NID not in key. Prefix 16'h5443 reserved.

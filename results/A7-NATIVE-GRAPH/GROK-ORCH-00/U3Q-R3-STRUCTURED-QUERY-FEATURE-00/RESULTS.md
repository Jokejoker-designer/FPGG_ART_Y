# RESULTS — U3Q-R3-STRUCTURED-QUERY-FEATURE-00

```text
LAW     = qse-v1-lexicon-hdc-00
INPUT   = raw tokens only
ROUTE   = k0={entity_id,intent_id} k1={relation_id,context_id}  (not CRC)
CRC     = crc16_dbg fingerprint only
HOST_*  = 0
XSIM    = U3Q_R3_XSIM_PASS
OOC     = DSP=0 LUT~2437 FF=201  (no full-chip)
VERDICT = PASS
U4A/U4/U5/BIT/PROGRAM/COM12 = CLOSED
```

## Metrics vs frozen thresholds

| class | value | threshold | result |
|-------|-------|-----------|--------|
| entity paraphrase id stability | 0.967 (29/30) | >=0.85 | PASS |
| intent paraphrase id stability | 1.0 | >=0.85 | PASS |
| same entity / different intent | entity 1.0, intent_diff 1.0 | >=0.85 | PASS |
| unrelated collision | 0.0 | <=0.10 | PASS |
| lexicon perturbation delta | 1.0 | >=0.80 | PASS |
| adversarial entity hit | 0.0 | <=0.20 | PASS |
| sentinel entity_id | 0 | =0 | PASS |
| retrieval recall@16 | 0.952 | >=0.80 | PASS |
| recall@64 | 0.952 | >=0.85 | PASS |
| n_host_* | 0 | =0 | PASS |
| CRC unused in k0/k1 | true | true | PASS |

## Failure class (not a threshold miss)

`condenser pump`: lowest-id multi-entity hit → entity_id=2 (condenser) not 10 (pump). 1/30 paraphrase miss. Law is frozen; not retargeted.

## Chain

raw token → accept/fire → held packet until retire → FPGA keys k0..k3.
No query-ID shortcut. Packet refused extra tokens while held.

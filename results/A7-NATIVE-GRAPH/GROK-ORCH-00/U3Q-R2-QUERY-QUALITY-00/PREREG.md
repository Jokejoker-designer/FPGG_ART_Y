# PREREG — U3Q-R2-QUERY-QUALITY-00

```text
GATE        = U3Q-R2-QUERY-QUALITY-00
BASE        = d8da32a + U2R in-flight
EXTRACTOR   = FPGA-owned qfe-v1-crc16-mix-00 (no retarget)
SOC_WIRING  = NO
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD

PRIMARY_UNKNOWN =
  On a held-out entity/intent/unrelated/perturbation corpus, what are
  bucket stability, collision, and downstream retrieval recall of the
  existing FPGA extractor? CRC same-in-same-out is LAW_SELFCHECK only.

HARD =
  extractor remains qfe-v1-crc16-mix-00
  corpus held-out from U3Q Q0..Q4 tokens
  gold labels independent of keys
  do not name CRC self-consistency "semantic recall"
  LAW_SELFCHECK same-in-same-out = 1.0
  XSim spot >=8 held-out vectors match twin (after U2R license free, or
  if xvlog can checkout in parallel)

QUALITY (report; not freeze as semantic authority) =
  entity_k12_stability  (same-entity variants, 12-bit K0 bucket)
  intent_k12_stability
  unrelated_k12_collision vs chance 1/4096
  perturbation_key_delta_rate  (expect ~1.0: 1-token change moves keys)
  retrieval_recall@16 / @64 on label gold

NOT_PASS_AS =
  semantic encoder freeze
  CRC self-check quoted as recall
  host hash / winner / address
```

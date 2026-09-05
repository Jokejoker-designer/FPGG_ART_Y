# RESULTS — U4A-R6-ROUTE-VALIDITY-00

```text
RESULT           = PASS
EVIDENCE_CLASS   = RTL_FACT + HOST_MODEL
RTL_EDIT         = YES (validity ports + bind flags + route-valid gate)
KEY_MATCH        = 98/98
HOST_SEMANTIC    = 0
PROTOCOL         = valid=1,key=0 PROBES; valid=0,key=0 DOES NOT
VALIDITY_EQ_KEY  = NOT IMPLEMENTED
DROP_T3          = NO
THRESHOLD_RETARGET = NO
FULL_SCAN        = NO
```

PRIMARY_ANSWER: Yes. Explicit `{k*_valid, k*}` from extractor bind state
keeps absent features out of route tables without changing qse key values.

Numeric zero and semantic absence are distinct: the protocol unit proves
`valid=1,key=0` still probes, so RTL is not secretly `key!=0`.

## 1. Frozen 98-vector replay (RTL_FACT)

XSim `tb_u4ar6_rtl_golden` vs U3Q-R3 `frozen_vectors.svh` + R6 `frozen_validity.svh`.

```text
U4A_R6_RTL_GOLDEN_PASS n=98 match=98
packet/key/cue/crc unchanged
v0..v3 match bind-state goldens
n_host_* remain 0
```

Host twin `freeze_validity.py` independently: KEY_MATCH 98/98.

Frozen corpus contains **zero** natural `(valid=1, key=0)` pairs.
That pair is injected only in the protocol test (not a semantic example).

## 2. Validity law (implemented)

```text
k0_valid = entity_class_bind OR intent_class_bind     (eh|ih)
k1_valid = relation_class_bind OR context_class_bind  (rh|xh)
k2_valid = entity_class_bind                          (eh)
k3_valid = intent_class_bind                          (ih)
```

Unmatched words still XOR into `context_cue` but do **not** set `xh`.
Probe/insert enable is the valid bit. Key selects bucket only.

`a7ng_route_valid_gate`: `probe_t = k_t_valid` (never `key != 0`).

## 3. Index-side (42 labeled titles)

| table | admitted | excluded (valid=0) | bucket0 occupancy |
|-------|----------|--------------------|-------------------|
| T0    | 42       | 0                  | 0                 |
| T1    | 30       | 12                 | 0                 |
| T2    | 42       | 0                  | 0                 |
| T3    | **0**    | **42**             | **0**             |

R5 T3 bucket0 = 42 is gone: every labeled title lacks intent-class bind,
so T3 is not populated. T3 is **not deleted**.

## 4. Directed queries (HOST_MODEL, P4_4k_h64, CAND_CAP=64)

| query | k0 | k1 | k2 | k3 | v0..v3 | probed | buckets (occ) | cand | prec | rec | red | FP | full? |
|-------|----|----|----|----|--------|--------|---------------|------|------|-----|-----|----|-------|
| chiller | 256 | 0 | 4408 | 0 | 1,0,1,0 | T0,T2 | 256(4), 312(4) | 4 | 1.000 | **1.00** | 0.905 | 0 | no |
| water chiller | 256 | 1 | 4408 | 0 | 1,1,1,0 | T0,T1,T2 | 256(4), 1(19), 312(4) | 22 | 0.182 | **1.00** | 0.476 | 18 | no |
| leak chiller | 258 | 0 | 4408 | 605 | 1,0,1,1 | T0,T2,T3 | 258(0), 312(4), 605(0) | 4 | 1.000 | **1.00** | 0.905 | 0 | no |
| payroll tax form | 0 | 0 | 0 | 0 | 0,0,0,0 | none | — | **0** | 1.0 | n/a | 1.0 | 0 | no |
| soccer match score | 0 | 0 | 0 | 0 | 0,0,0,0 | none | — | **0** | 1.0 | n/a | 1.0 | 0 | no |
| adversarial `ypypo tcpgx` | 0 | 0 | 0 | 0 | 0,0,0,0 | none | — | **0** | 1.0 | n/a | 1.0 | 0 | no |

Relevant-domain recall @ CAND_CAP=64: 1.00 ≥ prereg 0.80. Not retargeted.

`water chiller` extra candidates come from T1 (`water` is context-class id 1),
not from a T3 dump.

## 5. Unrelated / fully unknown

All-valid=0 queries: `candidate_count = 0`, no tables probed, **no full-scan**.
That state is UNKNOWN / INSUFFICIENT_EVIDENCE (not implemented this gate).

Unrelated pairwise Jaccard = 0.0 (empty-empty; not corpus identity).

R4/R5 admit-all (42/42) is gone.

## 6. leak-chiller discrimination

Route distinction preserved:

```text
chiller:      k0=256 k3=0   v3=0  probe T0,T2
leak chiller: k0=258 k3=605 v3=1  probe T0,T2,T3
```

T3 occupancy is 0 on this labeled corpus (titles have no intent bind),
so candidate *sets* coincide via T2 entity-cue (4 chiller titles, prec=1).
That is not the R5 T3-bucket0 dump. Intent still changes keys and probed tables.

## 7. Protocol unit (RTL_FACT + HOST_MODEL)

Synthetic, not a semantic example.

| case | valid | key | expected | observed |
|------|-------|-----|----------|----------|
| A | 1 | 0 | MUST probe | probe=1 insert=1 bucket=0 |
| B | 0 | 0 | no probe | probe=0 |
| C | 0 | 0x00A7 | no probe | probe=0 (proves not `key!=0`) |
| D | 1 | 0x1234 | probe bucket law | probe=1 bucket=0x234 |
| E | all 0 | 0 | no tables | probes=0000 |

`U4A_R6_PROTOCOL_PASS`

Host-model isolated T2: valid=1,key=0 returns the one inserted record;
valid=0,key=0 returns 0.

## 8. Pass checklist

1. U3Q keys unchanged 98/98 — YES (XSim + twin)
2. Validity explicit, independent of numeric key — YES
3. Invalid corpus features not inserted — YES (T3 admitted=0, bucket0=0)
4. Invalid query features do not probe — YES
5. valid=1,key=0 still probes — YES
6. Unrelated no longer admit entire corpus — YES (0 candidates)
7. Unrelated Jaccard < 1 or clean zero — YES (0)
8. Relevant recall ≥ 0.80 — YES (1.00)
9. leak-chiller discrimination — YES (route keys/tables)
10. no CRC routing fallback — YES
11. no relevant=set(union) — YES
12. no threshold retarget — YES

## 9. Not this gate

PERSIST 32→16 truncation remains an independently confirmed defect.
U4 AXI directory still closed. U5 closed. BIT/PROGRAM/COM12 untouched.

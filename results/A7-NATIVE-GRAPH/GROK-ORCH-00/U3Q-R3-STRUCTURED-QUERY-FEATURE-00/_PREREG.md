# _PREREG — U3Q-R3-STRUCTURED-QUERY-FEATURE-00

Frozen **before** any RTL edit. Do not change thresholds after a candidate run.

```text
GATE            = U3Q-R3-STRUCTURED-QUERY-FEATURE-00
WORKTREE        = D:\Jetking_sem4\SEM_4\arty-a7-online-lm-g14-preboard-00
BRANCH          = grok-orch/v31-canonical-00
HEAD_AT_PREREG  = 38b22269e9a5d8c1fae377e48af4869a2822c879
BLUEPRINT       = UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md §7 / §20 U3Q
PRIMARY_UNKNOWN = Can a deterministic FPGA-native structured feature packet
                  (entity/intent/relation/context) be generated from raw
                  tokens so paraphrase retrieval works, without host
                  semantic inputs and without CRC-as-route-authority?
LAW             = qse-v1-lexicon-hdc-00
SOC_WIRING      = NO
U4A/U4/U5       = CLOSED
BIT             = NO
PROGRAM         = NO
COM12           = NO
PHYS            = 4 (untouched)
ORACLE          = HOLD
LEARNED_ENCODER = NO
EAM03E/Q*/NGRC  = NO
```

## 1. Production input

Only raw 8-bit UART/application tokens + `fire`/`retire`.

Forbidden at query time (no ports; counters must stay 0):

```text
entity, intent, relation, context labels
hash, shard, bucket
candidate list, winner, address
relation path, next token, final answer
```

## 2. Feature packet (stable accept → retire)

Held until `retire_i` (or next accepted fire after retire). Observable.

```text
entity_id    [7:0]     0 = unknown, else frozen family id
intent_id    [7:0]
relation_id  [7:0]
context_id   [7:0]
entity_cue   [63:0]    HDC bind of bytes of words that hit entity lexicon
intent_cue   [63:0]
relation_cue [63:0]
context_cue  [63:0]
crc16_dbg    [15:0]    fingerprint ONLY; not a route key
k0           [15:0]    {entity_id, intent_id}
k1           [15:0]    {relation_id, context_id}
k2           [15:0]    entity_cue[15:0]
k3           [15:0]    intent_cue[15:0]
```

Assert: `k0 == {entity_id, intent_id}` and `k1 == {relation_id, context_id}`.
CRC must not appear in k0..k3.

HDC byte bind (reuse TermGen rotate):

```text
cue_bind(c, b) = ROTL1(c) XOR {56'h0, b}
```

A word's bytes bind only into the cue of the class it hit. Unmatched words bind into `context_cue` only if no class hit.

## 3. Token / match law

- Lowercase ASCII `A-Z` → `a-z` on ingest.
- Words split on `0x20`. Other bytes are part of the word.
- Exact whole-word match against frozen lexicon (length + bytes).
- Multiple hits in one class: `id = lowest nonzero id` (priority encoder).
- MAX_BYTES = 48, MAX_WORD = 12, MAX_WORDS = 8.

## 4. Frozen lexicon

Class 1 entity, 2 intent, 3 relation, 4 context.

### Entity

| id | words |
|----|--------|
| 1 | chiller |
| 2 | condenser, condensing |
| 3 | evaporator, evap |
| 4 | compressor |
| 5 | refrigerant, r410a, r32 |
| 6 | ahu, handler, handling |
| 7 | duct, ductwork |
| 8 | vav, variable |
| 9 | tower, ct |
| 10 | pump |
| 11 | valve, txv |
| 12 | sensor |

### Intent

| id | words |
|----|--------|
| 1 | install, mount, installation |
| 2 | leak |
| 3 | balance, tab |
| 4 | insulate, insulation, wrap |
| 5 | startup, commission, start |
| 6 | replace, swap |

### Relation

| id | words |
|----|--------|
| 1 | line, pipe, coil |
| 2 | unit, plant, box |
| 3 | gas, airflow |

### Context

| id | words |
|----|--------|
| 1 | water, air, dx, scroll, supply, return, chilled, pressure, temp, dp, expansion, solenoid, cooling, cell, fan, test |

## 5. Held-out corpus (frozen lists)

Not U3Q Q0 numeric tokens `{2,3,4}` etc.

**Entity paraphrases** (canonical first):

- chiller: chiller / water chiller / chiller unit / chiller plant
- condenser: condenser / condensing unit / air condenser / condenser coil
- evaporator: evaporator / evap coil / evaporator coil / dx evaporator
- compressor: compressor / scroll compressor / compressor unit
- refrigerant: refrigerant / r410a / r32 gas / refrigerant line
- ahu: ahu / air handler / ahu unit / air handling
- duct: duct / supply duct / return duct / ductwork
- vav: vav / vav box / variable air
- cooling_tower: cooling tower / tower cell / ct fan
- pump: chilled pump / condenser pump / water pump
- valve: expansion valve / txv valve / solenoid valve
- sensor: temp sensor / pressure sensor / dp sensor

**Intent paraphrases:**

- install: install chiller / mount chiller / chiller installation
- leak: leak check / check leak / gas leak test
- balance: air balance / balance airflow / tab balance
- insulate: insulate pipe / pipe insulation / wrap pipe
- startup: startup ahu / commission ahu / ahu start
- replace: replace compressor / swap compressor / compressor swap

**Same entity / different intent:**

- install chiller / leak chiller / replace chiller

**Unrelated:**

- payroll tax form / weather forecast / soccer match score / cookie recipe / piano lesson / airport delay / stock ticker / garden soil

**One-token perturbation:** last byte of canonical entity word +1: chiller, condenser, evaporator, compressor, ahu

**Adversarial collisions:** 20 strings `w0 w1` with each `w` = 5 lowercase letters from LCG seed `0xA7FE03`, modulus 26, skip if exact lexicon hit is intended (still counted if they accidentally match).

**High-address sentinel:** byte triple `C3 4F FF` and ASCII `799999`

## 6. Retrieval gold (independent of CRC, independent of k2/k3)

- Docs = entity-paraphrase titles.
- Gold for a query = other docs with the **same PREREG entity family label**.
- Retrieve by `entity_id` (k0[15:8]). Not by CRC. Not by `relevant=set(union)`.

## 7. Numeric PASS thresholds (frozen)

```text
LAW_SELFCHECK same-in-same-out              = 1.0
packet hold: two fires without retire keep  = 1.0  (second fire after retire)
k0 packing identity                         = 1.0
CRC unused in k0..k3                        = 1.0
n_host_*                                    = 0
entity_paraphrase_id_stability              >= 0.85
intent_paraphrase_id_stability              >= 0.85
same_entity_diff_intent: entity same        >= 0.85
same_entity_diff_intent: intent differs     >= 0.85
unrelated_entity_collision (both id>0 same) <= 0.10
lexicon_perturbation_changes_entity         >= 0.80
adversarial_entity_hit_rate                 <= 0.20
sentinel_entity_id                          = 0
retrieval_recall@16                         >= 0.80
retrieval_recall@64                         >= 0.85
OOC DSP                                     = 0
```

## 8. Falsifiers / HARD STOP

```text
QUERY_REPRESENTATION_LEAK   host_* counter > 0 or host semantic port exists
RETRIEVAL_RECALL_FAIL       recall@16 < 0.80
CRC_AS_ROUTE                k0/k1/k2/k3 derived from crc16_dbg
FIRST_DIVERGENCE            first frozen metric miss; keep fail artifact
threshold retarget after run
oracle retarget
full-chip P&R / bit / program / COM12
```

## 9. Evidence required

XSim of raw-token → packet → keys; Python twin bit-exact; OOC synth estimate (no full-chip); per-class confusion table; SHA256 of logs.

## 10. Not this gate

U4A profile freeze, U4 SoC, U5 800k, LM ctx_pack8, bitstream.

# MAPPING_DECISION — U8

Agent does **not** choose. Owner lock required.

## POLICY A — Keep legacy C9 NID as LM ctx (HOLD_A frozen)

LM input stays `global_id[7:0]` from the historical C9/NID Top-8.
TYPE_CLASS ranking remains a separate object.

- Semantic: LM still sees graph-node low8 tokens.
- Width: 8×8-bit `ctx_pack` unchanged. `P_LM` unchanged.
- Persistence: none.
- Transfer: none claimed.
- Conflict: **two retrieval engines**. Violates U6 “one candidate owner”.
- U7 evidence: compatible (learn path untouched).
- HOLD_A/OUT: can remain a silicon regression.
- Verdict if chosen: U8 is **not unified**. Call it LM-chain-on-legacy-C9.

## POLICY B — Pack TYPE_CLASS CLASS_ID into LM ctx

Production Top-K CLASS_ID becomes `tok[]`.

- Semantic: LM vocab index = CLASS_ID.
- Width: CLASS_ID is 16-bit; current LM token is 8-bit. IDs 256..443 **alias**.
  Needs a new token/ctx contract (not a silent low8).
- Persistence: none for LM weights; C9 UART dump meaning changes.
- HOLD_A/OUT `653/689/237/60`: **cannot be claimed**. Oracle retarget forbidden.
- Conflict: C9 name would mean CLASS_ID pack, not NID pack.
- Resource: LM embedding table indexed by CLASS_ID vs current vocab.
- Compatibility with historical U7: ranking unchanged; LM is a new consumer.

## POLICY C — CLASS_ID ranks; member NID becomes LM token

Rank TYPE_CLASS; feed a selected member’s NID low8 into LM.

- Semantic: retrieval class vs LM provenance object.
- Risk: **member-selection law**. R3A: `member_ptr` is catalog first, not
  800k NID. First/lowest/highest-confidence member is not canonical.
- Same fail class as R3A POLICY D unless owner freezes a pick law.

## POLICY D — Multi-beat ctx packet (blueprint §8)

```text
beat 0: eight CLASS_IDs (or node IDs)
beat 1: relation/path
beat 2: context/intent
beat 3: confidence/prior + valid count
```

- Semantic: closest to written U8 blueprint.
- Hardware: LM-06 today is one-beat 8×8-bit tokens. This is an LM input
  redesign, not a wire.
- HOLD_A/OUT: not preserved.
- Resource: extra ctx_we beats; TinyGPT `ntok` / embedding law must be
  versioned.
- Do not implement without owner + new LM-input law id.

## POLICY E — Smallest experiment: LM active-chain on frozen C9 path only

Prove, without TYPE_CLASS glue:

```text
existing C9 Top-8
→ ctx_we exactly once
→ start_fwd exactly once
→ LM-06 busy/done
→ pred FPGA-owned
→ n_host_tok = n_host_w = 0
```

Scope: `LM06_ACTIVE_CHAIN` reachability on the **already-wired**
`a7ng_gate14_c9_soa_lm_xsim` / bind path.

- Does **not** claim unified TYPE_CLASS→LM.
- Does **not** retarget HOLD_A.
- Does **not** open Q-head.
- After PASS, still need owner lock before TYPE_CLASS→LM.

## Working-set / resource notes (not a mapping veto)

- Naive LM-06 132 BRAM + graph stack **exceeds** 135 tiles (measured).
  Full-chip TYPE_CLASS+LM co-fit is a later physical gate (U9), not U8 XSim.
- `LEARN_STORE_CAPACITY_32` remains OPEN. U8 must not hide it.
- `U6_TYPECLASS_MINHEAP_TIMING` WNS −4.103 ns OOC remains OPEN. Do not
  “fix timing inside U8”.

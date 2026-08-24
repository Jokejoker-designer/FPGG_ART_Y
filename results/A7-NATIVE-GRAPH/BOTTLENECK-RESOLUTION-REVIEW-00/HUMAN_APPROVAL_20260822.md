# HUMAN APPROVAL — BOTTLENECK-RESOLUTION-REVIEW-00

**Date:** 2026-08-22  
**Authority:** Human (Anh) — explicit approval to use this review as decision basis for next steps  
**LOOP_STATE:** unchanged by this document (`next=STOP` until separate human dispatch)

---

## Approved central decision

**HIGHEST-VALUE NEXT GATE = `WF-GLOBAL-TOPK-00`**

Rationale accepted: known **correctness hole** (`carried_risk_r1`), not performance speculation. NG-02R proves exact 16→8 only; wavefront lacks cross-wave `G_t`. SOA, metadata late-fetch, and HS-02 before global Top-K risk optimizing an incorrect retrieval path.

---

## Approved execution order (human-locked)

### Graph / retrieval track

```text
WF-GLOBAL-TOPK-00
        ↓
DESCRIPTOR-CONTRACT-00   (stage-1 descriptor audit — NOT YET FROZEN)
        ↓
DDR-CUE-SOA-00           (blocked until descriptor contract closes)
```

### LM working-set track (parallel)

```text
LM06-WM-TRACE / MRC
        ↓
one physical WM candidate
        ↓
P&R
        ↓
BRAM-OWNER-00
```

### Integration track (after both tracks mature)

```text
HS22-LM06-ACTIVE-00
        ↓
HS-02 teacher-off semantic
```

### Encoder lane (parallel, isolated)

```text
ENC-GEOM-DIAG-00  — REFERENCE_MODEL only; MUST NOT count as Native Graph progress
```

---

## Three human corrections (binding on review authority)

### Correction 1 — Stage-1 descriptor NOT YET FROZEN

**REJECT** freezing `minimum_stage1_descriptor_bits = 96` as final authority.

| Tier | Bits | Status |
|------|-----:|--------|
| Known lower bound | `node_id` 32 + lawful `node_cue` 64 = **96** | **KNOWN** |
| If `learned_prior` becomes per-node lawful field | +8 → **104** | **OPEN** until descriptor-contract audit |
| Current wavefront wiring | `learned_prior_i` broadcast; `{cue,cue}` replication | **WIRING ARTIFACT** — not law proof |

**Gate before SOA:** `DESCRIPTOR-CONTRACT-00` — resolve which per-candidate fields the lawful scorer actually consumes before first-stage DDR fetch.

### Correction 2 — Encoder geometry diagnostics: preregister transform

Do **not** compute `E_corr` on raw `int16[32]` without transform spec.

| Diagnostic space | Transform | Metrics |
|------------------|-----------|---------|
| **Sign-space** | `b_ij = sign(h_ij)` | `E_balance`, binary bit correlation |
| **Continuous geometry** | `z_ij = standardized(h_ij)` per dimension | covariance, correlation, effective rank |

Amplitude scale across dimensions must not dominate correlation labels.

### Correction 3 — Remaining verdicts accepted as written

Global Top-K, Cue SOA (gated), LM MRC/Pareto ceilings, BRAM ownership evidence needs, single real LM-06, ungated DIFF REJECT, outstanding>8 not opened, HS-02 not opened — **all accepted**.

---

## What this approval authorizes

| Authorized | Not authorized (separate dispatch) |
|------------|-----------------------------------|
| Use review + this file as program decision authority | Edit `LOOP_STATE.json` |
| Preregister `WF-GLOBAL-TOPK-00` scope | RTL / test / bitstream implementation |
| Block SOA until descriptor contract | Open `lm06_wm_ladder` without explicit re-open |
| Block HS-02 until HS-22 + global Top-K | Declare BOARD_PASS |

---

## NEXT (human dispatch when ready)

1. Open `WF-GLOBAL-TOPK-00` preregistration + implementer dispatch  
2. Parallel: scope `DESCRIPTOR-CONTRACT-00` and `LM06-WM-TRACE` (MRC) — documentation/trace gates only until dispatched  
3. Encoder: `ENC-GEOM-DIAG-00` under `results/A7-EAM-03E/` if desired — no graph credit

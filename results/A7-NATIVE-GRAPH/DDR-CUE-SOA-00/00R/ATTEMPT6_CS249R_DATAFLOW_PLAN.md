# Attempt 6 — cs249r IO-aware dataflow plan

**Gate:** `ddr_cue_soa_00r_axi_liveness`  
**Research:** `NATIVE_AI_IO_AWARE_ARCHITECTURE_RESEARCH.md` (Harvard `cs249r_book` synthesis)  
**Date:** 2026-08-23  
**Evidence class target:** `MIG_XSIM` only (no board)

---

## Scientific frame (attempt 6)

| Field | Value |
|-------|-------|
| OBSERVATION | Unit 5/5; MIG query starts PRIOR before ID/CUE (`phantom plane`) |
| UNKNOWN | 832 B lawful 104b descriptor delivery unchanged |
| H_CANDIDATE | **Plane-stationary dataflow** — advance stage only on measured byte credit per plane |
| H_RIVAL | R-skid alone fixes MIG — **FALSIFIED** attempts 3–5 |
| FALSIFIER | No `A7NG_DDR_CUE_SOA_XSIM_PASS`; first query AR order ≠ ID→CUE→PRIOR |
| UNIT | query (64 candidates) |
| CONTROL | Frozen 104b descriptor; AOS 1024 B |
| METRICS | `B_query=832`, `r_beats=52`, `AR=4`, per-plane bytes {256,512,64} |

---

## cs249r principles → RTL law (attempt 6)

Source: [Harvard cs249r_book](https://github.com/harvard-edge/cs249r_book) via project research doc §1–5.

### 1. Memory wall first (Roofline / iron-law)

Do not optimize scorer or PE width until **useful bytes delivered** is proven:

```text
T_query ≈ max(B_query / BW_eff, O_query / R_compute) + L_control
```

**RTL law:** scoreboard exports `axi_read_bytes` per plane; wavefront FSM may not enter next plane until current plane `returned_beats == plane_target`.

### 2. Plane-stationary stream (Eyeriss analogue)

Not row-stationary CNN — **descriptor-plane stationary**:

```text
Stage 0: ID   plane — 16 beats / 256 B  (DDR_STREAM compact)
Stage 1: CUE  plane — 32 beats / 512 B
Stage 2: PRIOR plane —  4 beats /  64 B
Total: 52 beats / 832 B
```

**RTL law:** `phase` advances only on `plane_byte_credit_done`, not `pf_done_pulse` alone.

### 3. IO-aware schedule (FlashAttention lesson)

Do not materialize / fetch later-stage DDR data before earlier compact stream completes.

**Attempt 5 bug:** FSM jumped to PRIOR — violates schedule.

**Fix:** hard gate `id_bcnt==16 && cue_bcnt==32` before `FETCH_PRIOR` arms.

### 4. Decoupled transport (cs249r §5 pipeline)

```text
semantic scheduler (wavefront)
    → proven burst engine (plane_fetch / wavefront engine)
    → elastic R buffer (bridge skid)
    → unpack → BRAM wave
```

Semantic FSM must not drive `m_axi_rready` combinatorially.

### 5. Hierarchy handoff (preload → query)

Maps to `17_` phase ownership / cs249r capacity vs working-set:

```text
DDR_CAPACITY (preload write) → DRAIN → OWNER_SWITCH → DDR_STREAM (query read)
```

**RTL law:** `metric_clear` only when `bridge_idle && plane_fetch_idle && outstanding==0 && r_fifo_empty`.

---

## Implementation checklist (attempt 6)

1. **Plane credit FSM** in `a7ng_cue_soa_wavefront.sv`:
   - States: `FETCH_ID` → `FETCH_CUE` → `FETCH_PRIOR` → `SOA_DRAIN`
   - Transition on `plane_returned_beats == plane_target` from scoreboard
   - Assert `illegal_prior_skip` SVA if PRIOR AR before `id_credit==16 && cue_credit==32`

2. **Scoreboard byte ledger** (iron-law instrumentation):
   - `bytes_id`, `bytes_cue`, `bytes_prior`, `bytes_total`
   - Log in TB: `SOA_PLANE_CREDIT id=… cue=… prior=… total=…`

3. **§9 preload handoff** in `a7ng_ddr_soa_axi_bridge.sv` + `a7ng_cue_soa_mig_top.sv`:
   - Query `start` blocked until `preload_owner_released`
   - No `metric_clear` until full R-path idle

4. **Clone proven handshake** from `a7ng_cue_wavefront` (ddr_wavefront_00 PASS) for AR/R completion — diff only SOA plane descriptors.

5. **Verification:**
   - Unit TB: regression 5/5
   - MIG: first query DDR reads must show bank0 ID cols before bank1 prior col `018`
   - Marker `A7NG_DDR_CUE_SOA_XSIM_PASS`, patterns 1&2, top1 id=57 score=165, AOS==SOA

---

## Forbidden (unchanged)

Schema, TermGen, 01R/02M/LM06, board, sleep hacks, host winner/address.

---

## After PASS

STOP per gate law → queue `ddr_cue_soa_bench_01` (Phase B — measure cs249r roofline terms on SOA vs AOS).

---

## Attempt 6 outcome (2026-08-23)

**Result:** FAIL. Unit 5/5; MIG prior-first @ `0x03000030` unchanged despite plane-stationary gates.

**Lesson (cs249r):** IO-aware **schedule** is necessary but not sufficient — transport engine must match proven ddr_wavefront_00 handshake, not layered FSM patches.

**Attempt 7:** See `DDR_CUE_SOA_00R_AXI_LIVENESS.md` §17.

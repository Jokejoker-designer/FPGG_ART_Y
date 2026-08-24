# Failure classification — ddr_cue_soa_00r_axi_liveness

**Gate:** `ddr_cue_soa_00r_axi_liveness`  
**Evidence:** MIG XSim (`xsim_ddr_cue_soa.log`)  
**Result:** **FAIL** (transport/liveness; SOA not falsified)

## Instrumented boundary (AXI)

| Signal | Observation at hang |
|--------|----------------------|
| Hang byte address | `0x03000030` (prior plane beat 3 / bank 1 col `018`) |
| DDR signature | MIG re-activates bank 1 row `2000`, duplicate Read col `018` pairs, 8-beat bursts (`018`–`01f`), ~882 µs between retry groups |
| `done_o` | Never asserted before TB `#900ms` timeout |
| Marker | `A7NG_DDR_CUE_SOA_XSIM_PASS` **not observed** |

## Class (exactly one primary)

**Primary: `B_RREADY_DEADLOCK`**

- DDR returns prior-plane beat data (visible in `ddr3_model` READ lines).
- DUT does not complete stable AXI `R` acceptance before MIG times out and re-issues the same col-`018` read.
- `m_axi_rready` / `r_ready_o` drops while `m_axi_rvalid` is still active or before outstanding beat credit drains.
- Infinite MIG DDR retry loop; query never reaches `SOA_DRAIN`.

**Contributing (not primary): `C_R_FIRE_ACCOUNTING`**

- Prior `a7ng_soa_plane_fetch` completion required `issued == returned` while `pending` could remain non-zero after target beats captured, blocking `nf` drain and lowering `r_ready_o`.

**Ruled out**

- `A_DUPLICATE_AR_ACCEPT` — duplicate col-`018` pairs correlate with MIG physical retry after R stall, not independent DUT AR reissue while first txn outstanding.
- `D_COMPLETION_FSM` — wavefront `SOA_DRAIN` never reached; hang is in fetch, not pack/drain completion.

## ONE UNKNOWN (unchanged)

Can the frozen 104b descriptor deliver in exactly **832 B / 64-candidate query**?

**Not answered** — byte delta vs AOS (832 vs 1024) not measured on MIG-class path.

## Attempt 5 additive finding (2026-08-23)

| Observation | Implication |
|-------------|-------------|
| First query DDR read = **PRIOR** @ `0x03000030` (bank1 col `018`) | Wavefront FSM reaches PRIOR plane **before** bank0 ID/CUE ARs |
| Bank0 ID reads start ~348 µs **after** prior hang | Symptom is **phantom plane completion** / stale `pf_done`, not primary duplicate-AR root |
| Unit TB 5/5 PASS | Isolated plane_fetch OK; bug is **orchestrator + MIG integration** |

**Attempt 6 focus (orchestrator):** hard beat-count gate per plane; defer `metric_clear` until bridge+plane_fetch idle (§9).

## Attempt 6 result (2026-08-23) — cs249r plane-stationary **FAIL**

| Delivered | MIG outcome |
|-----------|-------------|
| `id_bcnt`/`cue_bcnt` plane gates, byte ledger, §9 OWNER_SWITCH, `wf_start` single-pulse fix, strict `r_ready`, SVA `illegal_prior_skip` | **Unchanged:** first query DDR read = PRIOR @ `0x03000030` (+372 µs before bank0 ID) |

**Inference:** cs249r scheduling on wavefront FSM alone insufficient.

## Attempt 7 result (2026-08-23) — plane_engine clone **FAIL**

| Delivered | MIG outcome |
|-----------|-------------|
| New `a7ng_soa_plane_engine.sv` (cue_wavefront-class); direct wavefront inst; `owner_ready_o` + first-4 AR TB monitor | **Unchanged:** PRIOR @ `126085966 ps` before ID @ `126457966 ps` (+372 µs) |

**Inference:** Bug is **above/beside** AR/R — wavefront `phase`/`pf_base` at `wf_start`, `metric_clear`/`r_drain_hold`, or phase skew. **Attempt 8:** hard `SOA_FETCH_ID`-only first AR; probe `phase`/`pf_base`/`pf_ar_addr`.

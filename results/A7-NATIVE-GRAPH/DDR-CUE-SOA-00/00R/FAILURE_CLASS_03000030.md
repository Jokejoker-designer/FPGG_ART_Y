# Failure class @ prior beat 0x03000030

**Gate:** ddr_cue_soa_00r_axi_liveness  
**Address:** `0x03000030` (PRIOR plane beat 3 / bank1 col 018)  
**Classification:** **B_RREADY_DEADLOCK** (primary) + **C_R_FIRE_ACCOUNTING** (contributing)

## Evidence

| Probe | Observation @ hang |
|-------|-------------------|
| `ar_fire` | AR accepted for col-018; duplicate AR re-issued ~654 µs later |
| `r_fire` | Last prior beat DDR data returned; `r_fire` not completed before FSM advanced |
| `accepted_beat_credit` vs `returned_beats` | Credit issued; last beat not handshaken before `r_ready` dropped |
| `fetch_returned` / `phase` | Phase advanced / `r_ready` combinatorially gated while MIG `rvalid` held |
| `fifo_level` | Bridge skid non-empty while consumer `r_ready` deasserted |

## Ruling

- **Not A_DUPLICATE_AR_ACCEPT** — duplicate AR is MIG retry symptom, not root cause.
- **B_RREADY_DEADLOCK** — `m_axi_rready` dropped while `rvalid` held on final prior beat.
- **C_R_FIRE_ACCOUNTING** — `pending` credit not drained before completion FSM evaluated.
- **Not D_COMPLETION_FSM alone** — completion fired early only after R path stalled.

## Fix applied (transport only)

1. `a7ng_soa_plane_fetch`: `start_req` + count R only when `pending>0` (drain without credit inflation).
2. `a7ng_axi_read_stream`: wrapper over proven plane_fetch + scoreboard exports.
3. `a7ng_ddr_soa_axi_bridge`: registered `m_axi_rready` from FIFO capacity (unchanged).
4. `a7ng_cue_soa_wavefront`: per-plane scoreboard accumulate; `start_pulse` on wavefront arm.

SOA descriptor / 104b law **not** falsified — transport/liveness repair only.

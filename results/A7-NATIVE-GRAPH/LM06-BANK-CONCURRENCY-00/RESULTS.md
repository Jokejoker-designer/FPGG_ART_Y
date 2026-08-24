# RESULTS — LM06-BANK-CONCURRENCY-00 (AMENDED)

**Gate:** `LM06-BANK-CONCURRENCY-00`  
**Type:** `READ_ONLY_TRACE_RESEARCH`  
**Independent verdict:** `PASS_NARROW` — see `AMENDMENT.md`  
**Closeout class (amended):** `TRACE_COMPLETE_PORT_TOPOLOGY_CLOSED_LIFETIME_OPEN`  
**TSV evidence class:** `CURATED_DERIVATION`  
**DCP SHA:** `CE6A6AD7FCDD9BC4D602CBD1D4B679FDE56C551A65AC8D0400418F0A5CDA6022`  
**Parity hypothesis:** not reopened

---

## FACT

1. Frozen LM06 bit mixes **CORE** (~98 BRAM: 64+32+2) and **BOARD tensor** (~34 BRAM: 32+2) under `u_a`/`u_w` names.
2. `act_ram128k16`: Port A RW + Port B RO; ATTQK/ADD FSM states consume both `ard` and `ard_b` in RTL.
3. Research XSim FWD (`SIM_FULL=1`, pred=744): `busy_cycles=2730657`; `act_diff_addr=2515697` (**address inequality** rate ≈92.13%); `max_act_ports=2`.
4. Silicon weight path is `SIM_FULL=0` `TILE.u_bank` — **not** exercised by this XSim (`ACCEPT_STATIC_ONLY` for weight bandwidth).
5. Board tensor path **not** exercised by research TB / `tb_a7lm06_core`.
6. Snap capacity math: `4096×16=65536` bits; `⌈65536/36864⌉=2` → **N_capacity=2**, **topology_headroom=0** (prior headroom=1 **withdrawn**).
7. Curated lower bounds: CORE act 64/64/0; CORE weight 32/32/0; CORE snap 2/2/0; BOARD weight 32/32/0; BOARD act 2/2/0.

---

## DERIVED

1. CORE act/weight tile counts match **TDP width-slice × depth-cascade**, not unused simultaneous banking beyond two ports.
2. Dual-port **capability** is required for at least ATTQK/ADD — do not serialize Port B expecting free BRAM collapse.
3. `act_diff_addr` rate is **not** identical to “semantic dual-consume every cycle” without FSM-gated consumer counters.
4. Snap LUTRAM is a **cross-resource migration** (−2 BRAM possible), not recovery of a wasted topology tile.

---

## INFERENCE

1. Largest open BRAM question may be **whether 34 BOARD tensor BRAM are on the LM06 causal output cone** — larger information gain than F1 until answered.
2. If BOARD tensor is required, then F1 (pingpong lifetime) is the right follow-up, measuring `both_live` ≠ `both_read`.
3. Multipump remains unproven against width×depth lower bound.

---

## NEEDS_EXPERIMENT (reordered)

| Priority | ID | Experiment | Falsifier |
|----------|----|------------|-----------|
| **P0** | **R0** | `LM06-BOARD-TENSOR-REACHABILITY-01` — is BOARD tensor on LM06 output cone? | Required / removable / mixed |
| P1 | F1 | Pingpong lifetime (`both_live` vs `both_read`) — **only if R0=A** | `both_live=1` during fill+compute |
| P1 | D1 | Snap BRAM→LUTRAM (`−2` BRAM, ~1K+ LUT, `NEEDS_SYNTH`) | BRAM not −2 or WNS fail |
| P2 | B1 | Multipump paper model only | N_lower unchanged |
| P2 | G1 | Act working-set tile | DDR ρ_bytes explodes |

---

## Answer table (amended)

| Bank | Bandwidth claim | N_phys | N_lower | Headroom | Evidence class |
|------|-----------------|-------:|--------:|---------:|----------------|
| CORE act | Dual-port needed (narrow) | 64 | 64 | 0 | RTL + XSim addr + ATTQK/ADD |
| CORE weight tile | Dual-port static | 32 | 32 | 0 | **STATIC_ONLY** (DCP+RTL) |
| CORE snap | 1R+1W | 2 | 2 | **0** | capacity arithmetic |
| BOARD weight | 8-CH read // | 32 | 32 | 0 width; lifetime OPEN | RTL_STATIC |
| BOARD act | 128b | 2 | 2 | 0 | RTL_STATIC |

---

## Hard-stop

No BOARD_PASS. No implementation PASS. No auto-chain to F1.  
Human authorizes **`LM06-BOARD-TENSOR-REACHABILITY-01`** next if desired.

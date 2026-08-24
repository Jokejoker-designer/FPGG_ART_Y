# FORMULA_TO_SIGNAL_MAP — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

Every formula below maps to an **actual counter or derived field** in repository evidence, or is marked **MISSING**.

**Legend — evidence class:** `BOARD_MIG` | `MIG_XSIM` | `MIG_XSIM_WAVEFRONT` | `LM06_WM_XSIM` | `POST_ROUTE` | `DERIVED` | `MISSING` | `FORBIDDEN`

---

## 1. Feeder / MIG metrics

| Formula | Variables | RTL / artifact source | Class | Measurable today? | Missing / risk |
|---------|-----------|----------------------|-------|-------------------|----------------|
| `stall_frac = pe_stall/(pe_stall+pe_busy)` | `pe_stall`, `pe_busy` | UART `board_uart_capture.json`; `tb_a7ng_ddr_feed_mig.sv` | BOARD_MIG / MIG_XSIM | **YES** | Pop-request stall, not DDR RTT |
| `recs_per_cyc = cons/cycles` | `recs_consumed`, `cycles_o` | MIG-METRIC-00, BOARD-R2 sweep | MIG_XSIM / BOARD_MIG | **YES** | Single always-pop consumer |
| `eta_beat = pe_busy/(pe_stall+pe_busy)` | derived | same | DERIVED | **PARTIAL** | ≠ `recs_per_cyc` when idle cycles exist |
| `eta_beat = beats/(beats+empty_stall)` | `axi_read_beats`, stall proxy | proposal §1; use `pe_stall` as empty-stall proxy | DERIVED | **AMEND** | Must name stall counter; not `pe_stall` if semantics differ |
| `axi_read_bytes/query` | `axi_read_bytes` | MIG-METRIC, WAVEFRONT, BOARD-R2 | MIG_XSIM | **YES** | Fixed 1024 B in probe |
| `ddr_bytes_per_candidate` | `axi_read_bytes/N_cand` | WAVEFRONT TB | MIG_XSIM_WAVEFRONT | **YES** | 16.0 = full NodeRecordV1 |
| `beats_per_query` | `axi_read_beats` | same | MIG_XSIM | **YES** | 64 beats @ 128-bit |
| `swap_count` | `swap_count_o` | `a7ng_cue_wave_stage` / WAVEFRONT | MIG_XSIM_WAVEFRONT | **YES** | Was gap pre-wavefront; now measured |
| `in_flight` (Little's L) | RTL internal | `a7ng_ddr_feed_pp.sv` | **MISSING** | **NO** | Not exported on board |

---

## 2. Wavefront metrics

| Formula | Variables | Source | Class | Today? | Risk |
|---------|-----------|--------|-------|--------|------|
| `memory_wait_fraction` | `mem_wait_cycles/active_cycles` | WAVEFRONT `PREREGISTER.md` | MIG_XSIM_WAVEFRONT | **YES** | Wave fill wait, not `pe_stall` |
| `jobs_per_cycle_during_wave` | wave jobs / active window | WAVEFRONT RESULTS | MIG_XSIM_WAVEFRONT | **YES** | Sustained rate |
| `jobs_per_emit_cycle` | 16 / emit cycle | WAVEFRONT | MIG_XSIM_WAVEFRONT | **YES** | Width proof only |
| `wavefront_fill_cycles` | `fill_cycles/waves` | WAVEFRONT | MIG_XSIM_WAVEFRONT | **YES** | 401→35 burst 1→4 |
| `buffer_empty_stall` | counter | WAVEFRONT | MIG_XSIM_WAVEFRONT | **YES** | SPEC §10 |
| `buffer_full_stall` | counter | WAVEFRONT | MIG_XSIM_WAVEFRONT | **YES** | Never saturated (L2) |
| `lane_util` | `lane_busy/active` | WAVEFRONT diagnostic | MIG_XSIM_WAVEFRONT | **YES** | Non-gate; ~2.8% |
| `cache_hit_ratio` | hardwired 0 | WAVEFRONT | MIG_XSIM_WAVEFRONT | vacuous | No hotset |

---

## 3. Roofline / throughput

| Formula | Variables | Source | Class | Today? | Risk |
|---------|-----------|--------|-------|--------|------|
| `I = useful_ops / DDR_bytes` | ops, bytes | — | **MISSING** | **NO** | No integrated graph op counter |
| `P ≤ min(P_peak, B_sust × I)` | B_sust, I | Williams roofline | EXTERNAL_THEORY | **PARTIAL** | B_sust ≈ beats/cycle × beat_bytes only on feed probe |
| `R_cand ≤ min(R_PE, B_sust/β_cand)` | β_cand=bytes/cand | β=16 measured | DERIVED | **PARTIAL** | R_PE width proved; R_sust ≈ 0.44/cyc |
| `R_query ≤ min(R_graph, B_sust/B_query)` | B_query | B_query=1024 B @ 64 cand | DERIVED | **PARTIAL** | No multi-hop graph query E2E |
| Link GB/s | bytes×freq | — | **FORBIDDEN** | **NO** | Explicit falsifier all MIG gates |

---

## 4. Data-movement equation (proposal §4)

| Term | Minimum bits (review) | Bytes today | Source | Class |
|------|----------------------|------------|--------|-------|
| `b_stage1` prune gate | 32b cue + 32b id = **64b** | 8 B compact entry | `a7ng_cue_wave_stage` | MIG_XSIM_WAVEFRONT |
| `b_stage1` TermGen law-correct | 32b id + 64b node_cue + 8b prior = **104b** | 16 B full record | TermGen + MEM_SCHEMA_V1 | DERIVED |
| `B_query = N×b_stage1 + …` | N=64 | 1024 B measured (stage1 only) | WAVEFRONT | MIG_XSIM_WAVEFRONT |
| `K_survivor × b_metadata_late` | — | **MISSING** | No late-fetch path | — |
| `E_expanded × b_edge` | 32 B EdgeRecordV1 | **MISSING** on wavefront path | MEM_SCHEMA_V1 | schema only |
| `B_episode` | 32 B EpisodeRecordV1 | **MISSING** on wavefront | MEM_SCHEMA_V1 | schema only |
| `eta_pack = useful_bits/transferred_bits` | stage1 in 128b beat | 64/128=0.5 (8B entry) or 104/128≈0.81 (packed) | DERIVED | Not measured in RTL |

---

## 5. LM working-set / MRC (proposal §8–9)

| Formula | Variables | Source | Class | Today? |
|---------|-----------|--------|-------|--------|
| `D_i` reuse distance | tile-id trace | — | **MISSING** | **NO** |
| `MRC(C) = misses/refs` | miss trace | — | **MISSING** | **NO** |
| `N_refill(C,L)` | eviction trace | WM-00 `pp_swaps` raw | LM06_WM_XSIM | **PARTIAL** (uninterpreted) |
| `DDR_read_bytes(C,L)` | refill×L | — | **MISSING** | **NO** (no MIG in WM bench) |
| `T_mem = T_first + bytes/B_sust` | model | graph B_sust only | DERIVED | **PARTIAL** |
| `max_live_per_cycle` | WM counters | `LM06-WM-00/raw/` | LM06_WM_XSIM | **YES** (not ladder evidence) |

---

## 6. BRAM fit (proposal §12)

| Formula | Variables | Source | Class | Today? |
|---------|-----------|--------|-------|--------|
| `B_total = B_always + max(B_graph, B_lm)` | tile counts | doctrine, BRAM-CONSOL | POST_ROUTE_PROXY | **PARTIAL** |
| `B_lm = 132` | u_w+u_a+u_snap | MEM-00 | POST_ROUTE | **YES** |
| `B_graph naive` | 01R 56 + 02M 52 + … | RESOURCE_BUDGET | POST_ROUTE | **YES** (falsified sum) |
| `H = 135 - B_total` | headroom | — | DERIVED | **PARTIAL** — B_always incomplete |

---

## 7. Little's Law (proposal §11)

| Formula | Variables | Source | Class | Today? |
|---------|-----------|--------|-------|--------|
| `N_out ≈ ceil(B_target × L / S)` | L=RTT | — | EXTERNAL_THEORY | **NO** — W missing |
| `bytes_in_flight ≈ B_target × L` | — | — | EXTERNAL_THEORY | **NO** |
| Plateau at out=8 | stall_frac grid | BOARD-R2 | BOARD_MIG | **YES** | Near saturation of this probe |

---

## 8. Useful-byte metrics (proposal §25)

| Formula | Variables | Source | Class | Today? |
|---------|-----------|--------|-------|--------|
| `D_survivor = K_final / DDR_bytes_query` | K=8 | WAVEFRONT topk output | DERIVED | **PARTIAL** — per-wave only |
| `metadata_fetch_ratio` | fetched/scored | — | **MISSING** | **NO** |
| `D_useful` (semantic) | relevance items | — | **MISSING** | **NO** until HS-02 |

---

## 9. Phase switch (proposal §16)

| Formula | Variables | Source | Class | Today? |
|---------|-----------|--------|-------|--------|
| `T_switch = T_block+T_drain+T_commit+T_verify` | FSM timers | — | **MISSING** | **NO** — `bram_owner_00` not run |
| `phi_switch = T_switch/(T_work+T_switch)` | — | — | **MISSING** | **NO** |
| `writers_per_bank ≤ 1` | owner FSM | doctrine | SPEC | **NOT EVIDENCED** |

---

## Misinterpretation guardrails

1. **Do not** equate `memory_wait_fraction` (wavefront) with `stall_frac` (MIG feed).  
2. **Do not** use `1 - stall_frac` as throughput when `cycles > pe_stall + pe_busy`.  
3. **Do not** cite PINGPONG16 `jobs_per_cycle=0.653` as wavefront gate evidence.  
4. **Do not** apply LM-06 `roofline.stalls` to graph DDR delivery.  
5. **Do not** treat `cache_hit_ratio=0` as measured miss rate — no cache exists.

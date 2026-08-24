# Memory alternatives & Xilinx IP catalog — Arty A7 Native AI

**Device:** `xc7a100t` (135 BRAM tiles, **no URAM**)  
**Board:** Digilent Arty A7-100T — DDR3 256 MB, COM12  
**Status:** RESEARCH_INPUT + deployment reference  
**Date:** 2026-08-23

---

## 1. Executive summary

**BRAM cannot be “replaced” for the hot working set** — it is the only on-chip bulk SRAM with predictable single-cycle access at 100 MHz. What literature and AMD docs support is a **hierarchy**:

```text
DDR3     → capacity + persistent state (graph, LM weights, episodes)
BRAM     → bounded active wave / tiles / Top-K (M_peak discipline)
LUTRAM   → small tables, shallow queues, score accumulators
SRL/FF   → pipeline delay, narrow shift, control state
Vendor IP → AXI decoupling (FIFO, register slice), optional DataMover
```

Naive sum of frozen blocks = **243/135 BRAM FALSIFIED**. Levers are **DDR-back + phase-share + LUTRAM offload**, not eliminating BRAM.

---

## 2. On-chip memory options (xc7a100t)

| Technology | Capacity class | Latency | Best use in Native AI | Caveat |
|------------|----------------|---------|----------------------|--------|
| **Block RAM** | 135 × 36 Kbit ≈ 607 KB | 1–2 cycles | `u_w`/`u_a` tiles, descriptor wave, Top-K | **Hard ceiling** — integration law |
| **Distributed RAM** ([UG474](https://docs.amd.com/r/en-US/ug474_7Series_CLB/Distributed-RAM-SLICEM-Only)) | Depth ≤512 typical per slice cluster; width flexible | 1–2 cycles | Per-lane score regs, small frontier, epoch tables | Consumes LUT; Fmax risk if wide |
| **SRL16E / SRL32E** | Deep narrow | Fixed delay | Delay lines, small shift windows | Not random-access store |
| **FF / LUT** | Tiny | 0–1 | Hot control, single registers | Not for arrays |
| **URAM** | N/A on Artix-7 | — | **Not available** | UltraScale+ only |

### 2.1 When to use LUTRAM instead of BRAM

Adopt when **all** hold:

- Depth ≤ 256–512, width ≤ 32–64  
- Single-port or simple dual-port  
- Not on critical LM tile path (post-route proven)  
- Saves ≥1 BRAM tile with WNS margin  

**Candidates (research):** per-lane reward bucket, query epoch tag, small minesweeper flags.

### 2.2 Phase-shared “virtual BRAM” (not a silicon substitute)

From TinyEngine / `bram_owner_00` doctrine:

```text
M_peak = max_t Σ valid_i(t) × size_i
```

Same physical BRAM bank serves GRAPH wave during GRAPH phase, LM `u_a` during LM phase — **time multiplex**, not larger BRAM. This is the primary “alternative” to naive BRAM stacking.

### 2.3 DDR as “extended memory” (already in use)

| Content | Location | Evidence |
|---------|----------|----------|
| LM persistent weights | DDR | LM-06 contract |
| Graph nodes/edges/episodes | DDR | mem_schema_v1 |
| SOA descriptor planes | DDR stream | 832 B/query target |

**Do not** put hot per-cycle scorer inputs only in DDR without ping-pong BRAM — `ddr_wavefront_00` proved memory-bound.

---

## 3. Xilinx / AMD IP useful for this project

### 3.1 Already in repo / build flows

| IP | Role | Project use |
|----|------|-------------|
| **mig_7series_0** (`vivado/ip/mig_7series_0/`) | DDR3 AXI slave | **Frozen** — official Digilent MIG only |
| **fifo_generator** (Vivado sim paths) | Async/sync FIFO | Consider for **R-channel** vs hand-rolled skid |
| **axi_datamover** (in build sim) | Stream ↔ AXI-MM | Evaluate for SOA plane DMA vs custom `plane_fetch` |
| **smartconnect** | AXI mux | Future full_integration only |

### 3.2 Recommended for `ddr_cue_soa_00r` attempt 7+

| IP / macro | PG / doc | Purpose |
|------------|----------|---------|
| **FIFO Generator** or **XPM_FIFO_ASYNC** | [DS317](https://docs.amd.com/api/khub/documents/3OHRa6P734dI8O_LAyOLxQ/content), [UG953 XPM_FIFO_AXIS](https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/XPM_FIFO_AXIS_SV) | 2–8 entry R skid; `FIFO_MEMORY_TYPE=distributed` for shallow elastic buffer |
| **AXI Register Slice** | AXI Infrastructure | Break `ready` timing path at MIG boundary |
| **AXI Protocol Checker** | Gate `00R` §10 | `pc_asserted==0` evidence |
| **Clone `a7ng_cue_wavefront`** | Internal (PASS) | **Preferred** over new DataMover for SOA — proven on MIG |

### 3.3 Evaluate later (not 00R scope)

| IP | PG | Use case |
|----|-----|----------|
| **AXI DataMover** | [PG022](https://docs.amd.com/r/en-US/pg022_axi_datamover/Command-Interface) | Auto burst split, 4K boundaries — bulk DDR fill/drain |
| **AXI BRAM Controller** | PG078 | Debug visibility of BRAM via AXI (GlassBox-adjacent; not V1) |
| **AXI Interconnect width converter** | AR 62785 | Avoid packet-FIFO mode that limits outstanding AR to 3 |

### 3.4 Forbidden / caution

- Hand-edit `mig.prj` — program law  
- Replace custom SOA unpack with DataMover without **same 104b law**  
- URAM / HBM assumptions on Artix-7  
- Board test on `00R` repair gate (§14 forbid)

---

## 4. Board deployment map (COM12 ready)

| Gate | Board allowed? | When |
|------|----------------|------|
| `ddr_cue_soa_00r_axi_liveness` | **NO** | MIG_XSIM only until PASS |
| `ddr_cue_soa_bench_01` | **YES** (human scope) | After 00R PASS — measure bytes/query on silicon |
| `mig_board_r2` | DONE | 16/16 — do not auto re-run |
| `hs02_semantic` | LIMIT only | Needs dedicated silicon gate |
| LM-06 paths | Per-gate | COM12 per `com12_authorized_gate` |

**Board plugged 2026-08-23** — queue silicon work **after** transport XSim PASS.

---

## 5. Recommended action order

```text
1. Attempt 7 XSim — clone ddr_wavefront_00 + vendor FIFO/register slice at R boundary
2. On PASS → verify trio → ddr_cue_soa_bench_01 (board optional in gate spec)
3. Parallel lm06_wm_trace_00 — lifetime analysis for BRAM vs LUTRAM split
4. bram_owner_00 — phase-shared arena (primary BRAM “alternative”)
```

---

## 6. References

- AMD UG474 — Distributed RAM  
- AMD UG586 — MIG reorder / `ui_rd_data`  
- AMD PG022 — AXI DataMover  
- AMD DS317 — FIFO Generator  
- ZipCPU skid buffer — AXI R-channel discipline  
- Project: `08_MEMORY_ARCHITECTURE.md`, `RESOURCE_BUDGET.md`, `RESEARCH_NATIVE_AI_AUTHORITATIVE_DIRECTIONS_20260823.md`

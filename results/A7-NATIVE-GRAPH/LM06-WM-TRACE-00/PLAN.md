# PLAN — `lm06_wm_trace_00` (Phase D, parallel)

**Written:** 2026-08-27  
**Gate:** `lm06_wm_trace_00` · **Owner:** `a7-ng-memory-arch` · **Authority:** PATCH_DRAFT  
**Skills:** `a7-native-graph-gate`, `a7-fpga-gate`, `scientific-method-native-ai`  
**Queue:** `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` (`lm06_wm_trace_00` QUEUED; `lm06_wm_ladder` BLOCKED; `bram_owner_00` BLOCKED on ladder)  
**Roadmap:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/16_MASTERPLAN_EXECUTION_PATH.md` §2.2  
**Do not declare:** `BOARD_PASS`, `NATIVE_V1_MINI_AI_BOARD_PASS`, UART `pred=664` on silicon  
**This wave does not:** program COM12, overwrite frozen LM-06/01R/02M bits, cut BRAM, edit E2R RTL, open the ladder, or touch graph late-materialize files.

Expands `GATE.md`. Parser: `tools/lm06_wm_trace_parse.py` (existing files only).

---

## 0. Honesty box

| Claim | Class |
|-------|--------|
| Frozen LM-06 working set is `u_a=66` + `u_w=64` + `u_snap=2` = **132 / 135** RAMB36 | POST_ROUTE (MEM-00 / PHYS-AUDIT / Q0 DCP) |
| Naive A0.3+01R+02M+LM-06 = **243/135** | FALSIFIED (HS-11) |
| Persistent `P_LM = 802816` INT8 already DDR-resident | CONTRACT / BOARD LM-06 |
| WM-00: bounded-tile restructure **bit-exact** vs recorded CONTROL (11/11 axes, 9 sequences) | LM06_WM_XSIM PASS_NARROW |
| WM-00: “max 2 tiles/cycle ⇒ ping-pong sufficient” | **STRUCK** (`VERDICT_lm06_wm_00_BINDING.md` L11) |
| BANK-CONCURRENCY-00: CORE act/weight **port topology closed** (headroom 0) | PASS_NARROW / `TRACE_COMPLETE_PORT_TOPOLOGY_CLOSED_LIFETIME_OPEN` |
| BANK-CONCURRENCY-00: `M_peak` / complete `u_a` lifetime | **OPEN** (`BANK_LIFETIMES.tsv`: peak-live UNKNOWN) |
| Tile-id stream / MRC histogram | **MISSING** (`FORMULA_TO_SIGNAL_MAP.md` §5) |
| This plan’s `M_peak` number | **not measured this wave** — plan + inventory only |
| Existence UART `pred=664` | last sealed BOARD capture **∅** — not this track |

---

## 1. ONE UNKNOWN — nothing else

> Under frozen law `lm06-signsgd-v1`, what is **`u_a` `M_peak` lifetime and tile residency**?

Not: a BRAM cut. Not: a 96/64/48/32 rung. Not: existence `pred=664`. Not: graph late-materialize. Not: `u_w` shape-sizing (Q0b) except as a named confounder. Not: `bram_owner_00` phase FSM.

`M_peak` is **not** WM-00 `max_live_per_cycle`. That counter is simultaneous **port demand**. Binding verdict forbids treating it as working-set size, ping-pong sufficiency, or DDR-latency hiding.

---

## 2. Definitions (freeze now — do not retune after seeing traces)

Blueprint (`17_MASTERPLAN_BLUEPRINT_V2_IO_AWARE.md` §4.3):

```text
M_peak = max_t  Σ_i  valid_i(t) × size_i
```

Working-set review (`LM06_WORKING_SET_REVIEW.md` §2):

```text
D_i        = # DISTINCT tile IDs accessed since previous access to tile i
miss_ratio(C) ≈ Pr(D ≥ C)     [off-by-one documented at first trace close]
MRC(C)     = misses / references
```

This gate reports **three layers**. Only L1 answers the unknown. Mixing them is a FAIL of the plan.

| Layer | What it is | Already known? | May size a ladder rung? |
|-------|------------|----------------|-------------------------|
| **L0 instantiated physical** | RAMB36 cells named `u_a` on frozen post-route DCP | YES — 66 = 64 CORE bit-slices + 2 BOARD `tile_activation` SDP | NO — occupancy of the **always-mapped** array, not live content |
| **L1 logical t-slot lifetime** | Which of 8 `ACT_STRIDE` slots are **live** (birth→death) inside one phase | **NO — this unknown** | YES, later, only after a synthesizable smaller array exists |
| **L2 port demand** | Distinct tiles **addressed in the same cycle** | YES — WM-00 Arm A `u_a` max = 2 | **NO** (L11/L12) |

### L1 tile id (frozen address map — arithmetic-free)

From `rtl/lm/tiny_gpt803k_core.sv` and `a7lm06_pkg.sv`:

```text
aa(t, tk, d) = t * ACT_STRIDE + tk * D + d
ACT_STRIDE   = 16384 = C * D     (C=128, D=128)
t            = aaddr[16:14]      (8 logical slots)
loc          = aaddr[13:0]
size_slot    = 16384 × INT16 = 262144 bits
```

Candidate WM decode (`rtl/native_graph/memory/a7ng_lm06_wm_act.sv`): `sel = addr[16:14]`, `loc = addr[13:0]`, `NTILE=8`. Same slicing. Law untouched.

RTL overlay (candidate **death** mechanisms — must be *measured*, not assumed):

```text
ah overlays t=3/4 after attn  (K/V claimed dead)
ay overlays t=0 after residual-in is consumed
```

`valid_i(t)` for slot `i`:

```text
birth  = first write to slot i in the UNIT (or restore)
live   = birth occurred AND last-read of this incarnation has not occurred
         AND no overlay write that the law treats as replacing the slot
death  = last-read of this incarnation, or overlay write that discards it
dirty  = any write since birth/refill
```

Reported L1 metrics (preregistered; report even if they do not help a cut):

```text
M_peak_slots(UNIT)     = max_t |{ i in 0..7 : live_i(t) }|
M_peak_bits(UNIT)      = M_peak_slots × 262144
residency_i(UNIT)      = cycles_live_i / cycles_in_UNIT
reuse_distance_i       = D_i on the tile-id reference stream (reads+writes)
unique_slots_touched   = |{ i : ≥1 access in UNIT }|
overlay_death_ok       = last-read(t=3/4) precedes hid overlay write (boolean per UNIT)
```

**Explicitly not `M_peak`:** `pp_swaps`, `live_pair_events`, `max_live_per_cycle`, `act_diff_addr`, `busy_cycles`, `wr_act`.

---

## 3. UNIT, replication, blocking (experimental design)

**UNIT of analysis = one LM-06 tile phase**, defined as one commanded window on one input sequence:

```text
UNIT = (seq_id, ph)     ph ∈ {EVAL, TRAIN, AFTER}
```

Phase is the window **the bench commanded** (`tb_a7ng_lm06_wm.sv` `ph_t`: `PH_EVAL` / `PH_TRAIN` / `PH_AFTER`), not a guessed FSM decode. Diagnostic split inside a UNIT by core `st` (`u_core.phase[5:0]`) is allowed as a *blocking factor*, not as extra N.

```text
NOT the unit = one clock cycle
NOT the unit = 2.73e6 busy_cycles from BANK-CONCURRENCY FWD
NOT the unit = 100k cycles as fake independent samples
NOT the unit = summed EVAL+TRAIN+AFTER
```

`BANK_ACCESS_TRACE_SUMMARY.txt` `busy_cycles=2730657` is a **duration**, not a sample size. Treating it as N is pseudoreplication (scientific-method skill).

### Replication axis (frozen before any new run)

Reuse WM-00 vector table (`tb_a7ng_lm06_wm.sv`, SHA in `LM06-WM-00/SHA256.txt` = `35219708…`):

| seq | ntok | tokens | tgt | lr | why it is a replicate |
|----:|-----:|--------|----:|---:|------------------------|
| 0 | 1 | `[1]` | 32 | 3 | Tier-1 silicon recipe |
| 1 | 1 | `[7]` | 100 | 1 | token identity |
| 2 | 2 | `[1,7]` | 5 | 3 | ntok=2 |
| 3 | 3 | `[3,9,17]` | 200 | 2 | ntok=3 |
| 4 | 1 | `[255]` | 1023 | 4 | ntok=1, extreme class |
| 5 | 4 | `[0,1,2,3]` | 64 | 1 | ntok=4 |
| 6 | 2 | `[128,64]` | 512 | 3 | ntok=2 |
| 7 | 5 | `[11,22,33,44,55]` | 777 | 2 | ntok=5 |
| 8 | 8 | `[1..8]` | 32 | 3 | ntok=8 (full context) |

Primary blocking factor: **`ntok`**. Activation footprint and overlay timing scale with tokens. Do not average ntok=1 with ntok=8 and call it one `M_peak`.

Secondary blocking: **EVAL vs TRAIN**. `wr_act` is already equal in magnitude across those windows in WM-00 (see §5) — that does **not** imply equal live-sets (writes ≠ residency).

Tertiary (report, do not pool): core `st` groups EMB / LN / ATTQK / ADD / FF / BWD.

Minimum replication to close L1: **seq 0 EVAL + seq 0 TRAIN + seq 8 EVAL + seq 8 TRAIN** (ntok∈{1,8} × {EVAL,TRAIN}). Full 9×3 is the registered bag; partial close must list missing UNITS as LIMIT, not silently drop.

Control for any future trace run: same `a7lm06_wmem.hex` SHA `9A6BBC7A…`, same frozen core SHA, host oracle **off**.

---

## 4. Signals already in repo (do not invent new owners)

### 4.1 Frozen core (read-only)

| Signal | File | Role for L1 |
|--------|------|-------------|
| `aaddr`, `aaddr_b` | `rtl/lm/tiny_gpt803k_core.sv` | tile_id = `[16:14]` |
| `awe`, `awd16` | same | write / dirty |
| `ard16`, `ard_b16` | same | read |
| `st` / `phase[5:0]` | same (`phase = {2'd0, st}`) | diagnostic block |
| `aa` / `ah` / `ay` | same | overlay map |
| `act_ram128k16` ports | `rtl/lm/act_ram128k16.sv` | flat CONTROL array; **no** `wm_*` counters |

### 4.2 WM candidate (observational; does not gate data unless `A7NG_WM_ENFORCE_*`)

| Signal | File | What it actually is |
|--------|------|---------------------|
| `sel_a` / `sel_b` | `rtl/native_graph/memory/a7ng_lm06_wm_act.sv` | L2 tile ids this cycle |
| `pp_active` / `pp_shadow` / `wm_pp_swaps` | same | port-A select changes — **not** MRC |
| `wm_live_pair_events` / `wm_max_live_per_cycle` | same | L2 port demand |
| `slot_tag` / `slot_val` / `slot_dirty` / `slot_age` | same, `A7NG_WM_ENFORCE_ACT` | L1-like, but **zero-latency functional model**, `NLIVE=4`, **not run** (WM-00 L5) |
| `wm_evict_writebacks` / `wm_refills` | same / snap ENFORCE | traffic; uninterpreted in WM-00 (L12) |
| W / snap twins | `a7ng_lm06_wm_wbank.sv`, `a7ng_lm06_wm_snap.sv` | out of this unknown except as confounders |

TB already prints aggregates under `A7NG_WM_CAND` (`tests/xsim/tb_a7ng_lm06_wm.sv` ~447–469):

```text
WM00_WS act pp_swaps=%d live_pair_events=%d max_live_per_cycle=%d
WM00_CNT wr_act upload=… eval=… train=… after=… fold=… reload=…
WM00_ROW v=… ntok=… (UNIT identity)
```

There is **no** per-cycle tile-id `$fwrite` today.

### 4.3 Bank-concurrency research TB (results-only; did not edit `tests/` / `rtl/`)

`results/A7-NATIVE-GRAPH/LM06-BANK-CONCURRENCY-00/tb_lm06_bank_concurrency_research.sv` probes `u_core.aaddr` / `aaddr_b` / `awe` but **aggregates only** (`act_diff_addr`, `max_act_ports`). Schema: `ACCESS_TRACE_SCHEMA.md`. Closeout class: lifetime **OPEN**.

Future trace sink (when parent authorizes a run) stays in `results/A7-NATIVE-GRAPH/LM06-WM-TRACE-00/`, same research-only pattern — **do not** edit frozen `tests/xsim/tb_a7ng_lm06_wm.sv` until a freeze candidate exists.

### 4.4 Post-route / ownership files

| File | Evidence class | Use |
|------|----------------|-----|
| `results/A7-NATIVE-GRAPH/MEM-00/BRAM_OWNERSHIP.md` | POST_ROUTE_PROXY | 66/64/2 classification; shareable-by-phase = YES for `u_a` |
| `results/A7-NATIVE-GRAPH/MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md` | POST_ROUTE | Q0 method + ranking |
| `results/A7-NATIVE-V1/LM06_Q0_BRAM/LM06_BRAM_OWNERSHIP.md` | POST_ROUTE | primary Q0 |
| `results/A7-NATIVE-GRAPH/LM06-BRAM-PHYS-AUDIT-00/{BRAM_PHYSICAL,LOGICAL_BANKS}.tsv` | POST_ROUTE | CORE `u_a` 64 TDP w=1 + BOARD `u_a` 2 SDP; `estimated_removable_tiles=0` |
| `results/A7-NATIVE-GRAPH/LM06-BANK-CONCURRENCY-00/PHYSICAL_TO_LOGICAL_BANKS.tsv` | CURATED_DERIVATION | CORE `act_ram128k16` ≠ BOARD `tile_activation` |
| `results/A7-NATIVE-GRAPH/LM06-BANK-CONCURRENCY-00/BANK_LIFETIMES.tsv` | CURATED_DERIVATION | `M_peak_bits` for CORE act = full-array capacity; **peak-live UNKNOWN** |
| `build/out/a7lm06_post_route.dcp` | POST_ROUTE | SHA `CE6A6AD7…6022` (PHYS-AUDIT / BANK-CONCURRENCY) |
| `build/out/a7lm06_utilization_route.rpt` or `TINYGPT-SOC/frozen_lm06_utilization_route.rpt` | POST_ROUTE | 132 tiles |
| `results/A7-NATIVE-GRAPH/INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` | POST_ROUTE_PROXY | composed 130-tile *cut proposal* — **not** a measured lifetime |
| `docs/contracts/A7-LM-06-TILE.md` | CONTRACT | act 64 BRAM of 18-bit; tensor+MIG ~34 |

### 4.5 Runners (reuse, do not fork existence)

| File | Role |
|------|------|
| `tests/xsim/run_a7ng_lm06_wm.ps1` | Arm ctl/cand, `-EnforceAct` exists but WM-00 **did not run** it |
| `results/A7-NATIVE-GRAPH/LM06-BANK-CONCURRENCY-00/run_bank_concurrency_xsim.tcl` | FWD-only research pattern |

---

## 5. Numbers that already exist (cite, do not re-derive as `M_peak`)

Parser extracts these from disk. They are **not** the answer to §1.

### 5.1 Physical `u_a` (L0)

From `LOGICAL_BANKS.tsv`:

| bank_id | owner | physical_tiles | limiting_dimension | removable |
|---------|-------|---------------:|--------------------|----------:|
| `u_a.core_bitsliced_4x16` | `u_a` | 64 | port (BIT_SLICED) | 0 |
| `u_a.SDP_104b_pair` | `u_a` | 2 | width | 0 |
| **named `u_a` total** | | **66** | | **0** |

CORE 64 is `act_ram128k16`. BOARD 2 is `tile_activation` (tensor sibling). Lifetime of CORE slots **cannot** be used to delete the 2 SDP tiles.

### 5.2 WM-00 Arm A, 9 sequences (L2 + write counts)

From `LM06-WM-00/RESULTS.md` §3–§4 (logs may be absent from `raw/` even though `SHA256.txt` lists them):

| field | `u_a` | class |
|-------|------:|-------|
| `pp_swaps` | 704580 | L2 / select-change count |
| `live_pair_events` | 173453232 | L2 both ports different tiles |
| `max_live_per_cycle` | **2** | L2 only — **not** `M_peak_slots` |
| `wr_act` EVAL | 169344 = 6272 × 27 | writes, not unique slots |
| `wr_act` TRAIN | 169344 | same caveat |
| `wr_act` AFTER | 6272 | same caveat |
| `wr_act` FOLD | 0 | no act traffic in fold window |

`NLIVE_ACT=4` ENFORCE path: **NOT RUN**. Arm B ENFORCE was `u_snap` only, n=1, zero-latency.

### 5.3 BANK-CONCURRENCY FWD-only (L2-ish)

From `BANK_ACCESS_TRACE_SUMMARY.txt`:

```text
workload=A7LM06_FWD_ONLY  SIM_FULL=1
busy_cycles=2730657
act_wr=6272  act_diff_addr=2515697  act_rw_collide=512  max_act_ports=2
pred=744
```

LIMITS: FWD only (no TRAIN); `SIM_FULL=1` (weight array ≠ silicon TILE); no tile-id journal; `act_diff_addr` ≠ semantic dual-consume (AMENDMENT #3).

`BANK_LIFETIMES.tsv` CORE_act `M_peak_bits` cell is **capacity 2097152**, with note `peak-live UNKNOWN`. Parser must not promote that cell to a measured `M_peak`.

---

## 6. Hypotheses (for the eventual TRACE run — not claimed now)

**H_CANDIDATE_LIVESET** — inside each UNIT, `M_peak_slots` is **strictly less than 8**, because overlay (`ah`/`ay`) kills K/V and residual-in before later tensors need them.

**H_RIVAL_FULL8** — all 8 t-slots remain live for a measurable fraction of TRAIN (bwd needs values the overlay claimed dead, or last-read happens after the next slot is born). Then time-multiplex of the 8-slot array **does not** reduce L0.

**H_RIVAL_NTOK** — `M_peak_slots` grows with `ntok`; a rung sized on seq 0 (ntok=1) **fails** on seq 8.

**H_RIVAL_PHYS** — even if `M_peak_slots=2`, CORE’s 64 bit-sliced TDP tiles share one address space for the **full** 131072×16 array (`PHYSICAL_TO_LOGICAL_BANKS.tsv`). A live-set of 2 does **not** delete 48 RAMB36 until a **re-inferred** smaller array is synthesized. Trace ≠ tile cut.

Any TRACE closeout that answers §1 must pick a surviving hypothesis with file-backed `WMTR_REC` / histogram. This PLAN wave does not pick one.

---

## 7. Measurement procedure

### 7.1 This wave (authorized) — no XSim, no P&R, no COM12

1. Freeze this PLAN (UNIT, layers, falsifiers).
2. Run `tools/lm06_wm_trace_parse.py` on **existing** files → `INVENTORY.json`.
3. Record MISSING set. Do not fill `M_peak` with L0 66 or L2 2.

### 7.2 Next measurement wave (parent-dispatched; still not the ladder)

Research-only TB under `results/A7-NATIVE-GRAPH/LM06-WM-TRACE-00/` (copy the BANK-CONCURRENCY pattern: instantiate frozen `tiny_gpt803k_core`, do **not** modify `rtl/` or frozen `tests/`). Emit one line per **act access event**, not per clock:

```text
WMTR_REC cyc=%0d seq=%0d ph=%s st=%0d ntok=%0d owner=u_a
         tile=%0d port=%s we=%0d addr=%0d
```

| field | source |
|-------|--------|
| `cyc` | busy-relative cycle in UNIT |
| `seq` | vector index |
| `ph` | `EVAL` / `TRAIN` / `AFTER` (bench window) |
| `st` | `u_core.phase[5:0]` |
| `tile` | `aaddr[16:14]` or `aaddr_b[16:14]` |
| `port` | `A` or `B` |
| `we` | `awe` (port A); 0 on B (RO) |
| `addr` | 17-bit act address |

Payload dumps out of scope. Dual-port same-cycle → **two** records (needed for L2 check vs L1 live-set).

Parser already accepts `WMTR_REC` lines when those files exist; until then `m_peak_u_a.status=MISSING`.

**Do not** enable `A7NG_WM_ENFORCE_ACT` to “measure” L1: that is a zero-latency functional bound (`NLIVE=4`), not frozen-law residency, and it was not run. ENFORCE is a **later candidate**, after L1 of the unbounded array is known.

Preferred compile: frozen `rtl/lm/act_ram128k16.sv` (CONTROL array) so the trace cannot be accused of WM-candidate perturbation. Optional second arm: WM Arm A (all tiles resident, counters observational) as a **replication of the same L1**, not a new unknown.

### 7.3 How the parser will turn `WMTR_REC` into L1 (algorithm, frozen)

For each UNIT independently:

1. Stream records in cycle order.
2. Slot `i` becomes live on first `we=1` to `tile=i` (birth). Overlay write to `i` **ends** the previous incarnation and starts a new one (death then birth).
3. Last-read of an incarnation = last record with `tile=i` and `we=0` before death.
4. `M_peak_slots` = max over cycles of `|live|` (a slot stays live from birth until death, **including idle cycles** — this is lifetime, not access).
5. Reuse-distance histogram: on each reference to `i`, `D_i` = number of **distinct** tiles referenced since previous reference to `i`. Stack-distance / Mattson MRC. Document inclusive vs exclusive at first close (review: “document off-by-one at gate open”).
6. Never divide by `busy_cycles` to invent a p-value. Report per UNIT; then a table vs `ntok` and `ph`.

If a full journal is too large: dump **per-UNIT occupancy time-series** at slot granularity (8-bit live mask per cycle is 1 bit×8 per cycle — acceptable) plus a compact reference stream `(cyc, tile, we)`. Do not downsample cycles as if they were replicates.

### 7.4 POST_ROUTE_PROXY (parallel, not a substitute)

L0 66 is already measured. A new DCP is **out of scope** until a synthesizable smaller `u_a` exists. Proxy use of the frozen DCP: keep CORE 64 vs BOARD 2 split in every claim so a live-set of CORE slots is not reported as “66 → N”.

---

## 8. What would FALSIFY a later 96 / 64 / 48 / 32 rung

`lm06_wm_ladder` remains **BLOCKED**. Rungs are **reporting ceilings** for a future Pareto candidate (doctrine: stop at first good; 32 is not mandatory). This section freezes *how a future rung dies*, so the trace is aimed at those tests.

Let

```text
B_rung ∈ {96, 64, 48, 32}
B_residual_known = B_u_w_instantiated + B_u_snap + B_always
```

Today, instantiated residual if `u_w` and `u_snap` are **not** cut: `64 + 2 = 66`, plus BOARD tensor 34 if still in the bit, plus encoder/MIG/always-on as enumerated later by `bram_ownership_report`. Exact `B_always` is **INCOMPLETE** (`FORMULA_TO_SIGNAL_MAP.md` §6). A rung claim that ignores BOARD-vs-CORE split or always-on is void.

### 8.1 Trace-level falsifiers (available once L1 exists — still not opening the ladder)

| ID | Falsifier of a proposed `u_a` bound `C_slots` or a total `B_rung` |
|----|-------------------------------------------------------------------|
| **F-MRC** | `MRC(C_slots) > 0` on TRAIN for any registered seq **and** the implied refill bytes are required for bit-exactness (cannot recompute). Bound `C_slots` is illegal. |
| **F-PEAK** | `M_peak_slots(UNIT) > C_slots` for any registered UNIT. |
| **F-NTOK** | Bound holds at ntok=1 and fails at ntok=8 (or the reverse if someone sizes on the large case and claims the small). |
| **F-TRAIN** | EVAL live-set fits `C_slots`; TRAIN does not. |
| **F-OVERLAY** | `ah`/`ay` overlay writes occur **before** last-read of the killed slot (law needs the old value) → overlay-as-death is illegal; H_CANDIDATE_LIVESET dies. |
| **F-PHYS** | Trace `M_peak_slots=2` used to claim `64 × 2/8 = 16` physical tiles **without** a re-inferred array / post-route count. Bit-sliced full-depth map does not shrink by access sparsity. |
| **F-L2SMUGGLE** | Any text that sets `M_peak_slots = max_live_per_cycle` (2). Already struck. |
| **F-EXACT** | Candidate at that bound is not bit-exact vs recorded CONTROL (WM-00 axes). |
| **F-WNS** | Post-route WNS < 0 or TNS ≠ 0 on the candidate (ladder evidence class, not this gate). |
| **F-STALL** | DDR stall explodes when refill is real (doctrine ladder stop rule). Needs MIG; **absent** from WM bench — cannot be claimed from this TRACE class. |
| **F-32TOTAL** | `B_rung=32` while instantiated `u_w` remains 64. Arithmetic illegal unless `u_w` is also reduced by a **separate** measured unknown. |
| **F-UA128** | Stacking UA128 + LM132 (already FALSIFIED; 16_ §6). |
| **F-BOARD2** | Counting BOARD `u_a` 2 SDP as shareable CORE scratch. They are `tile_activation`, not `act_ram128k16`. |

### 8.2 Worked arithmetic (planning only — not a rung)

If H_RIVAL_FULL8 survives (`M_peak_slots=8` every TRAIN UNIT): **no** t-slot time-mux cut. Remaining `u_a` levers are overlay-as-smaller-array (only if F-OVERLAY fails to fire), LUTRAM migration, DDR-back (G1, high `ρ_bytes`), or BOARD-tensor removal (different unknown, `LM06-BOARD-TENSOR-REACHABILITY-01`). Blind 32 is FALSIFIED for `u_a` content.

If H_CANDIDATE_LIVESET survives with `M_peak_slots≤2` **and** F-PHYS is discharged by a new array of 2×16384 INT16 that P&Rs to a measured tile count `B_act'`: then LM working set becomes `B_act' + B_u_w + B_u_snap + B_tensor?`. That number is compared to ceilings **later**. This gate still does not pick 96 vs 64.

INTEGRATE’s “shared 64 + residual 66 = 130” is a **cut proposal**, not L1 evidence. Do not cite it as `M_peak`.

---

## 9. Evidence class

```text
This wave:     PLAN + INVENTORY          class = TRACE_PLAN / POST_ROUTE_PROXY inventory
Trace close:   WMTR_REC + MRC tables     class = TRACE  (XSim research; not BOARD)
Physical L0:   DCP / TSV                 class = POST_ROUTE_PROXY (frozen LM-06-only bit)
Never:         BOARD, BOARD_PASS, pred=664, HS-22 semantic, COM12
```

`FITS != RUNS != TRAINS`. TRACE ≠ POST_ROUTE ≠ BOARD. WM-00 PASS_NARROW is **prerequisite correctness**, not a resource result (`forbid_ladder_without_bit_exact` is met for equivalence, still insufficient for rungs).

---

## 10. Blocking / independence

| Item | Status |
|------|--------|
| UART existence `pred=664` | **not required** (GATE; PHASE2_INDEPENDENT) |
| COM12 | **forbidden** this gate |
| `graph_late_materialize_00` | parallel; do not steal files |
| `lm06_wm_00` | DONE_ENG PASS_NARROW — prerequisite |
| `lm06_wm_ladder` | BLOCKED until human re-open **after** L1 numbers exist |
| `bram_owner_00` | BLOCKED on ladder — do not open |
| LOOP_STATE `lm06_wm_ladder.blocked_by` | still `"lm06_wm_00"` — **parent-owned**; this agent does not edit `LOOP_STATE.json`. Semantic block is now **trace**, per GATE / 16_ §2.2 |
| Frozen bits `222F8043…` / `57D1DF1B…` / `DB3BC58A…` | do not overwrite |
| Encoder ungated DIFF | different lane; do not glue |

---

## 11. Parser (non-silicon harness)

`tools/lm06_wm_trace_parse.py`

- Reads paths in §4 if present; records `missing` otherwise.
- Extracts L0 tile counts, WM-00 L2/write tables, BANK summary, SHA256 log **presence vs manifest**.
- Sets `m_peak_u_a.status = MISSING` unless a `WMTR_REC` file yields a per-UNIT live-set (none today).
- Refuses to copy `max_live_per_cycle` or TSV capacity 2097152 into `m_peak_u_a.value`.
- Writes `results/A7-NATIVE-GRAPH/LM06-WM-TRACE-00/INVENTORY.json`.

Does not run xvlog/xsim, does not hash frozen bits as a rewrite, does not emit a rung.

---

## 12. Forbidden (session law)

```text
ONE unknown, ONE implementer
no lm06_wm_ladder / lm06_wm_01..04 / bram_owner_00 opened or previewed as started
no 96/64/48/32 targeting
no COM12, no program, no r2_rdb, no E2R RTL
no overwrite of frozen LM-06 / 01R / 02M / A0.3 bits
no RESOURCE_BUDGET.md update
no LOOP_STATE.json write
no host next-token / gradient / winner
no GlassBox / ILA this gate
no stealing graph_late_materialize files
AI does not declare BOARD_PASS
```

---

## 13. What is still OPEN after this PLAN wave

```text
1. M_peak_slots / M_peak_bits for u_a          MISSING (L1)
2. Per-UNIT residency_i and MRC(C)             MISSING
3. Overlay death legality (ah/ay vs last-read) MISSING
4. TRAIN vs EVAL live-set difference           MISSING (writes exist; live-set does not)
5. ntok scaling of M_peak                      MISSING
6. NLIVE_ACT=4 ENFORCE at full scale           NOT RUN (WM-00 L5)
7. Synthesizable bounded u_a / WNS / tile count  NOT THIS GATE
8. DDR refill bytes / stall                    NO MIG in WM bench
9. BOARD tensor 34-tile reachability           different unknown (do not auto-chain)
10. Existence UART pred=664                    different track (∅)
```

Marker for a **future** TRACE close (not issued now): `A7NG_LM06_WM_TRACE00_L1_MEASURED` only if `INVENTORY.json` contains per-UNIT `M_peak_slots` from `WMTR_REC` with seq∈{0,8} and ph∈{EVAL,TRAIN}.

---

## 14. NEXT

```text
NEXT = emit research-only WMTR_REC (results/ LM06-WM-TRACE-00 TB) for
       UNIT ∈ {(0,EVAL),(0,TRAIN),(8,EVAL),(8,TRAIN)}
       using frozen act_ram128k16 + tiny_gpt803k_core
       then re-run tools/lm06_wm_trace_parse.py

NOT next = lm06_wm_ladder
NOT next = bram_owner_00
NOT next = blind 32
NOT next = COM12 / E2R
```

Parent dispatches the TRACE run. This agent stops at PLAN + inventory.

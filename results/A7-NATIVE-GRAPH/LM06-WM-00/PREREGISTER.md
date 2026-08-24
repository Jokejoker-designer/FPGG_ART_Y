# PREREGISTER — `lm06_wm_00`

**Written:** 2026-08-22T12:28:35+07:00 (05:28:35Z) — **BEFORE any RTL edit and before any measurement**
**Gate:** `lm06_wm_00` · **Agent:** `a7-ng-memory-arch` · **Archive:** `results/A7-NATIVE-GRAPH/LM06-WM-00/`
**Authority read in full:** `AUTHORITY_MEMORY_DOCTRINE.md`, `LOOP_STATE.json` (`lm06_wm_00` entry),
`CLOSEOUT_ddr_wavefront_00.md`, `DDR-WAVEFRONT-00/CLOSEOUT.md`,
`INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md`, `00_CURRENT_AUTHORITY.md`,
`08_MEMORY_ARCHITECTURE.md`, `09_LM06_LOWBIT_OPTIMIZATION.md`, `BRAM_WORKING_MEMORY_SPEC.md`,
`docs/contracts/A7-LM-06.md`, `A7-LM-06-TILE.md`, `A7-LM-06-CONFIRMATION.md`, `A7-LM-06-LESSONS.md`.

---

## 1. OBSERVATION

Frozen LM-06 (`law_id = lm06-signsgd-v1`, BOARD_PASS 2026-08-19, close bit
`arty_a7_lm06c3.bit` SHA `222F8043…`) owns **132 BRAM tiles** of *working machinery*, measured
POST_ROUTE as `u_a` 66 (activation scratch) + `u_w` 64 (weight staging) + `u_snap` 2 (snapshot).
The persistent 802,816 INT8 parameters are **already DDR-resident by contract** — this is not a
weight-migration problem.

Every naive composition measured so far exceeds the 135-tile device: 243/135, 260/135, 264/135.
`ddr_wavefront_00` (PASS_NARROW, `MIG_XSIM_WAVEFRONT`) established that candidate **delivery** is
**not** the structure competing with those 132 tiles — delivery is ≤2 RAMB18 tiles or less.
Therefore the load-bearing structure is the LM-06 working set itself.

In the frozen RTL the three working-set owners are **flat monolithic arrays**:

| module | shape | maps to |
|--------|-------|---------|
| `weight_bram803k` | one `[0:1048575]` INT8 array | `u_w` |
| `act_ram128k16` | one `[0:131071]` INT16 array | `u_a` |
| `snap_ram4k16` | one `[0:4095]` INT16 array | `u_snap` |

A flat array cannot express ownership, residency, eviction, or a bound. The doctrine's REQUIRED
structure is `bounded tiles / ping-pong buffering / explicit phase ownership`.

## 2. THE ONE UNKNOWN — nothing else

> Can a **bounded / ping-pong** LM-06 working-set implementation remain **bit-exact** with frozen
> LM-06?

**This gate does NOT optimize BRAM.** No 96 / 64 / 48 / 32 targeting. Reaching a smaller tile count
is explicitly **not** the objective. No BRAM-count claim, no ladder rung, no Pareto point will be
declared. `lm06_wm_01..04` and `lm06_wm_ladder` stay BLOCKED and will not be opened, previewed or
partially started. No other gate (`bram_owner_00`, `mig_sweep_full`, `bram_ownership_report`,
`record_schema_freeze`, `mig_pe_wide`, `full_integration`) will be touched.

## 3. CONTROL and CANDIDATE

```text
CONTROL   = frozen LM-06  (arithmetic core + flat monolithic working-set arrays)
CANDIDATE = frozen LM-06 arithmetic core + restructured bounded/ping-pong working set
```

The frozen arithmetic core `rtl/lm/tiny_gpt803k_core.sv` and every arithmetic helper
(`isqrt32`, `floordiv_s48`, `a7lm06_pkg`, `weight_tile803k`, `a7lm06_logits_lutram`) will be
**byte-identical** in both arms. SHA256 MATCH will be proven, not asserted.

**Substitution mechanism (declared now, so it cannot be re-chosen later):** the candidate memories
are new files under `rtl/native_graph/memory/` that declare modules with the **same module names**
(`weight_bram803k`, `act_ram128k16`, `snap_ram4k16`) and the **same port lists**. A run compiles
*either* the frozen `rtl/lm/` memory file *or* the candidate file, never both, in a separate xsim
work directory. Consequence: **zero edits to any frozen LM-06 source file**, and the arithmetic is
provably identical because it is literally the same file.

## 4. Hypotheses

**H_CANDIDATE** — the candidate equals the CONTROL on every applicable equivalence axis.

**H_RIVAL** — restructuring perturbs arithmetic, fold order, or persist/reload state: the tiles
change results somewhere that a coarse output check (e.g. `pred` alone) would miss. Specific rival
mechanisms named in advance:

| # | Rival mechanism |
|---|-----------------|
| RV1 | read-during-write collision semantics differ once the array is split (READ_FIRST vs WRITE_FIRST on a per-bank basis) |
| RV2 | registered read latency changes from 1 cycle when a bank-select mux is inserted |
| RV3 | fold order changes because the fold walks addresses that now cross tile boundaries |
| RV4 | dual-port aliasing: ports A and B land in different tiles and one port sees stale/other-tile data |
| RV5 | enforced eviction loses dirty bytes, so the update fold or the persist/reload digest diverges |
| RV6 | `pred` matches but the full 802,816-byte weight image or a per-layer probe does not |

## 5. FALSIFIERS (any one of these FAILS or LIMITs the gate)

| # | Falsifier |
|---|-----------|
| F1 | any non-bit-exact equivalence axis in §7 |
| F2 | any change to LM-06 arithmetic law (`lm06-signsgd-v1`), weights, geometry, shifts, LN STE, sign-SGD, or `HIT_MAX`/01R/02M/TermGen/Top-K/relation/encoder/training law |
| F3 | any frozen bitstream, frozen manifest, `mig.prj`, or frozen RTL file byte-modified (proven by SHA MATCH, both directions) |
| F4 | a CONTROL that was **computed at compare time** rather than recorded beforehand (HLB R2) |
| F5 | EVAL-phase weight writes proven only by port absence rather than by per-phase counters (HLB R3) |
| F6 | LM tile sizing derived from the `ddr_wavefront_00` summed-occupancy counter (auditor MAJOR-2) |
| F7 | a single input vector presented as the replication unit (pseudoreplication) |
| F8 | any board claim, any COM12 program, any `r2_rdb` latch, any BOARD_PASS declaration |

## 6. CONTROL PROVENANCE PLAN (HLB R2 — mandatory)

The bit-exact CONTROL must be outputs **RECORDED FROM the frozen LM-06 before the candidate runs**.
A host that computes the expected token/activation at compare time is a next-token-on-host
violation even when labelled "control". `python/ref/a7lm06_fixed_ref.py` therefore **will not be
invoked anywhere in this gate**.

Two control tiers, declared now with their evidence classes kept apart:

### Tier-1 — `BOARD_RECORDED` (highest class, n = 1 input sequence)

Source: `results/A7-LM-06/hardware_c3/ladder.json`, produced 2026-08-18T19:18:37Z → 19:24:31Z on
silicon from frozen bit `arty_a7_lm06c3.bit` (SHA `222F8043…`), i.e. **3 days before this gate**.
Frozen recipe from `docs/contracts/A7-LM-06-CONFIRMATION.md`: `seed 2 / context [1] / target 32 /
lr 3`, host-compare-only, retry forbidden.

Recorded comparison points to be used (all read out of `ladder.json`, none recomputed):

```text
fold0        xor32=5          add32=94638317     wr_n=0
one_full     pred=744         loss=16            wr_n=655616
fold1        xor32=23         add32=94627297     wr_n=655616
upload_spots 8 addresses x 8 recorded bytes
layer_probes 4 layers, recorded before[8] and expected_after[8]
persist      bytes=802816     xor32=23
fold_reload  == fold1
AFTER        wr_n unchanged
```

Also `tests/xsim/a7lm06_expected.txt` (mtime 2026-08-18T20:22:17, predates this gate) carries the
same six scalars and will be SHA-recorded as the pre-existing recorded expectation file.

### Tier-2 — `XSIM_RTL_RECORDED` (lower class, fixes the n = 1 replication problem)

The Tier-1 recipe is the **only** input sequence recorded from silicon in this repository. To avoid
F7 (pseudoreplication) without committing F4 (host recompute), additional CONTROL vectors will be
produced by **running the frozen LM-06 RTL itself** in XSim, and **archiving those outputs with
SHA256 and a timestamp BEFORE the candidate is compiled or run**. The control is the frozen RTL, not
a host model. This is explicitly a *lower* evidence class than Tier-1 and will never be reported as
board evidence.

Ordering rule, preregistered: `control run → archive + SHA + timestamp → candidate compile →
candidate run → compare`. If the candidate log timestamp precedes the control archive timestamp the
gate is void.

Tier-2 replication plan: **N = 9 input sequences** — the Tier-1 recipe plus 8 additional
`(context, ntok, target, lr)` vectors chosen to vary context length, token identity, target class
and learning rate. Exact vector table will be fixed in the TB source and its SHA recorded before
the control run. UNIT = one input sequence (forward + update + fold), **not** a clock cycle.

If Tier-1 turns out to be unusable for any axis, that axis will be reported as **LIMIT / not
proven**, not silently substituted with a Tier-2 or host number.

### Tier-3 — pre-existing recorded artifact (corroboration only)

`tests/xsim/a7lm06_after.hex` (4,194,304 B, mtime 2026-08-19T00:38:38, predates this gate) is a
recorded post-training full weight image from the frozen RTL. It will be SHA-recorded and used as a
**corroborating** full-image reference only. It will not be overwritten: both arms of this gate
write to distinct filenames.

## 7. EQUIVALENCE GATE — preregistered axes

All axes must hold. Each axis names its control tier.

| # | Axis | Metric | Control tier |
|---|------|--------|--------------|
| **A1** | same initial weights | SHA256 of `a7lm06_wmem.hex` identical in both arms; `fold0` `xor32`/`add32` exact | Tier-1 + Tier-2 |
| **A2** | same input | identical TB stimulus source (one TB file, SHA recorded) for both arms; vector table identical | structural |
| **A3** | same arithmetic | SHA256 MATCH on every frozen arithmetic source in both arms; candidate touches no arithmetic module | structural + SHA |
| **A4** | same forward result | `pred`, `last_loss` exact, per sequence | Tier-1 (recipe) + Tier-2 (9 seq) |
| **A5** | same forward fold | `fold0.xor32`, `fold0.add32` exact | Tier-1 + Tier-2 |
| **A6** | same update result | `wr_n` exact per sequence; 4 recorded per-layer probe windows byte-exact | Tier-1 + Tier-2 |
| **A7** | same update fold | `fold1.xor32`, `fold1.add32` exact | Tier-1 + Tier-2 |
| **A8** | same persist / reload semantics | persist digest `xor32` over 802,816 B exact; `fold_reload == fold1`; AFTER-mode `wr_n` unchanged | Tier-1 + Tier-2 |
| **A9** | full weight image | 802,816-byte post-update image byte-identical between arms (host-port readback digest, structure-agnostic) | Tier-2 + Tier-3 corroboration |
| **A10** | recorded readback spots | 8 recorded `upload_spots` byte windows exact | Tier-1 |

A "coarse output check" is explicitly not accepted: A4 alone passing while A7/A9/A10 fail is a FAIL
(rival RV6).

## 8. Per-phase write counters (HLB R3 — mandatory)

Once the working-set tiles are writable the structural zero-write guarantee expires. EVAL-phase
writes will be proven from **counters**, not from the absence of a write port.

Counters, instrumented per working-set owner (`u_w`, `u_a`, `u_snap`) and per phase, where the phase
is defined by the TB's own commanded window:

```text
phase EVAL   = start_fwd window (forward only, no start_train)
phase TRAIN  = start_train window
phase AFTER  = after_mode=1 forward window
phase FOLD   = do_fold window
```

Preregistered expectations:

| counter | expected | why |
|---------|---------:|-----|
| `wr_w_eval` | **0** | no persistent-weight write may occur in EVAL |
| `wr_w_after` | **0** | AFTER gate: `wr_n` unchanged (Tier-1 recorded) |
| `wr_w_train` | **655616** | equals Tier-1 recorded `wr_n` — independent cross-check |
| `wr_act_eval` | > 0 | activation scratch is *expected* to be written in EVAL; it is transient, not persistent state |
| `wr_snap_eval` | ≥ 0 | reported, not gated |

`wr_w_eval > 0` or `wr_w_after > 0` is a FAIL. `wr_w_train ≠ 655616` is a FAIL.

## 9. CANDIDATE structure — declared before implementation

Three new additive files under `rtl/native_graph/memory/`. Region decode is arithmetic-free
(pure address bit slicing), so it cannot perturb the LM law.

| file | shadows | restructure | tiles |
|------|---------|-------------|------:|
| `a7ng_lm06_wm_wbank.sv` | `weight_bram803k` | flat `[0:1048575]` INT8 → bounded region tiles, `sel = addr[19:17]`, `loc = addr[16:0]`; matches the `A7-LM-06-TILE.md` 131,072-byte region granularity | 8 × 131072 |
| `a7ng_lm06_wm_act.sv` | `act_ram128k16` | flat `[0:131071]` INT16 → bounded t-slot tiles, `sel = addr[16:14]`, `loc = addr[13:0]`; matches `aa(t,tk,d) = t*ACT_STRIDE + tk*D + d` | 8 × 16384 |
| `a7ng_lm06_wm_snap.sv` | `snap_ram4k16` | flat `[0:4095]` INT16 → bounded snap-region tiles, `sel = addr[11:10]`, `loc = addr[9:0]`; matches the n1/n2/attn/hid map | 4 × 1024 |

Each module additionally carries: per-tile `valid` / `dirty` / `owner_epoch`, an explicit
**ping-pong resident-pair tracker** (`pp_active` / `pp_shadow`, `pp_swaps`), a
`max_concurrent_live_tiles` residency counter, and the §8 per-phase write counters. Read latency
stays exactly 1 registered cycle and read-during-write stays READ_FIRST on both ports, matching the
frozen arrays (rivals RV1, RV2, RV4).

### Two candidate arms, both preregistered

| arm | what it is | evidence class it can earn |
|-----|-----------|----------------------------|
| **Arm A — structural** | bounded tiles + ping-pong accounting, all tiles physically present, no enforced eviction. Synthesizable. | `XSIM` data equivalence + **measured** residency |
| **Arm B — enforced bounded pair** | only `NLIVE` tiles resident; on swap, a dirty tile is written back to a behavioural backing store and the incoming tile refilled from it. Zero-latency backing store ⇒ **functional model, not synthesizable timed RTL**. | `XSIM_FUNCTIONAL_MODEL` |

Arm B is where H_RIVAL can genuinely win (rival RV5), so it is the load-bearing falsifier. Its
`NLIVE` values are fixed **now** from the access pattern, not tuned later:

```text
NLIVE_W    = 2   ports A and B may sit in different W regions (core: w_addr_b)
NLIVE_ACT  = 4   aaddr and aaddr_b may sit in different t-slots; writes target a third
NLIVE_SNAP = 2   snap waddr and raddr may sit in different snap regions
```

If Arm B is not bit-exact at these values that is a **measured negative result** and will be
reported as such, with the observed residency from the counters. It will **not** be converted into
a BRAM target, a ladder rung, or a re-tuned NLIVE search (that would be the ladder's job, and the
ladder is BLOCKED). Arm A and Arm B are reported separately and never merged.

### AMENDMENT A1 — 2026-08-22T12:41+07:00 (05:41Z), still BEFORE any measurement

Two scope decisions taken after reading the frozen RTL in full and before compiling or running
anything. Recorded as an amendment rather than an edit so the original text stands.

**(a) Prior evidence already bearing on this unknown — cite, do not re-claim.**
`weight_tile803k` with `SIM_FULL = 0` is *already* a bounded single-region working set: exactly one
131,072-byte W region resident, dirty-flush on miss, refill from DDR. The C3 silicon run
(`ladder.json`, bit `222F8043…`) executed that bounded structure and produced folds
`5 / 94638317` and `23 / 94627297` — **identical** to the flat `SIM_FULL = 1` monolith recorded in
`a7lm06_expected.txt`. That is a pre-existing **board-class existence proof** that a bounded,
evict-and-refill W working set is bit-exact with the flat reference. This gate **cites** it as prior
evidence and does **not** claim it as its own result.

Consequence: the genuinely open part of the unknown is `u_a` (66 tiles, the largest single owner) and
`u_snap` (2 tiles), which in the frozen RTL are flat, always-resident arrays with **no** bounded
structure, no ownership state and no eviction path at all.

**(b) Arm B is narrowed, and its feasibility bound is declared now.**

> **STRUCK BY HUMAN RULING, 2026-08-22 (post-measurement).** The reasoning in the paragraph below was
> recorded here in advance and is preserved unaltered as the historical prereg record — but the
> inference it contains ("*a two-deep ping-pong pair is always structurally sufficient for
> correctness*") was **struck** and must **not** be carried into any finding. A port-demand count
> supports no correctness conclusion. The only permitted statement is: *in this workload, at most 2
> tiles are demanded in the same cycle.* See `CLOSEOUT.md` **L11**. Traffic / reuse-distance material
> is likewise demoted to the BLOCKED ladder (`CLOSEOUT.md` **L12**).

~~Reasoning recorded in advance: a *correct* bounded working set with writeback/refill is functionally
equivalent to a flat array by construction, and the frozen core presents at most two distinct
addresses per cycle per memory (port A, port B), so a **two-deep ping-pong pair is always
structurally sufficient for correctness**. What a bounded working set actually costs is **swap /
eviction frequency**, which is a traffic question and belongs to the BLOCKED ladder, not here.~~

Therefore Arm B is scoped to where a real enforced eviction path is affordable to simulate at full
LM-06 scale, and its purpose is stated honestly as *validating the eviction/refill data path inside
the real forward+update+fold*, not as a tile-count search:

```text
Arm B primary : snap_ram4k16  ENFORCE  NLIVE_SNAP = 2 of 4 tiles (1024 words each)
                real separate backing store, real dirty writeback, real refill
Arm B extended: act_ram128k16 ENFORCE  NLIVE_ACT  = 4 of 8 tiles
                RUN ONLY IF Arm A's measured swap counters show it is affordable
```

If Arm B extended is not computationally affordable at full LM-06 scale, that is reported as an
explicit **LIMIT with the measured swap count as the stated reason** — it is not silently dropped,
and it is not replaced by a smaller workload presented as full scale.

`NLIVE_W = 2` from the original §9 is **withdrawn as a measurement target**: the W bounded case is
already board-covered per (a), and re-running it here at reduced fidelity would add nothing. `u_w`
is still restructured and still checked on every equivalence axis in Arm A.

**(c) Residency is measured, never targeted.** `max_concurrent_live_tiles`, `pp_swaps` and
per-tile touch counts are reported as measurements. No BRAM tile count, no ladder rung, no
96/64/48/32 value will be derived from them in this gate.

## 10. UNIT and replication

```text
UNIT              = one input sequence (context, target, lr) -> forward + update + fold
NOT the unit      = one clock cycle
Tier-1 replication= n = 1 sequence  (the only silicon-recorded recipe in the repo)  <-- LIMIT
Tier-2 replication= n = 9 sequences (recipe + 8), frozen-RTL control recorded first
Arms              = 2 (structural, enforced-pair)
```

The n = 1 Tier-1 limitation is a property of the repository, not a choice. It will be stated as an
explicit LIMIT and it caps the achievable verdict.

## 11. Preregistered metrics (reported whether they help or not)

```text
per axis A1..A10          : MATCH / MISMATCH, with the raw compared values
pred, last_loss, wr_n     : per sequence, per arm
fold0/fold1 xor32,add32   : per sequence, per arm
persist xor32, fold_reload: per sequence, per arm
wr_w_eval / wr_w_after / wr_w_train / wr_act_eval / wr_snap_eval : per arm
pp_swaps_w / pp_swaps_act / pp_swaps_snap                        : per arm
max_concurrent_live_tiles_w / _act / _snap                       : per arm  (MEASUREMENT, not a target)
tile_evict_writebacks / tile_refills                             : Arm B only
sim cycles to done, wall time                                    : diagnostic only, not a gate
```

Explicitly **not** reported as a gate result: BRAM tile count, LUT, FF, WNS, TNS, DDR bytes. No
synthesis or implementation will be run in this gate; `FITS != RUNS` and `POST_ROUTE !=
FUNCTIONAL_INTEGRATION`. Evidence class of this gate is **simulation-class**.

## 12. Carry-in handling (auditor MAJOR-2)

The `ddr_wavefront_00` figure (3 KiB declared bound / 176 B measured peak / 512 B suggested) is
`ENGINEERING_INFERENCE`: `max_resident` sums all 16 banks while `in_ready_o` stalls on any single
bank full, so the per-bank peak was never measured. **No LM tile in this gate is sized from that
counter** (falsifier F6). The only carry-in relied upon is the qualitative one that survives the
caveat: candidate delivery is ≈2 RAMB18 tiles or less, therefore delivery is not what competes with
LM-06's ~132 tiles.

Carried risk R1 (`a7ng_topk` is per-batch 16→8 with no cross-wave reduction) is not exercised here:
this gate contains no retrieval, no Top-K and no answer path, and no claim will ride that stage.

## 13. Session law

```text
ONE unknown, ONE implementer
no other gate opened / ticked / previewed
no COM12 program, no board run, no r2_rdb latch
AI does not declare BOARD_PASS
LOOP_STATE.json NOT edited by this agent (the parent flips it)
after CLOSEOUT: STOP
```

## 14. Deliverables

```text
PREREGISTER.md                (this file, first)
CONTROL_PROVENANCE.md         (per-vector source + SHA256)
RESULTS.md                    (per-axis equivalence table + raw numbers)
FROZEN_VERIFY.md              (frozen-file SHA MATCH, both directions)
SHA256.txt                    (changed RTL / TB / logs)
CLOSEOUT.md                   (verdict, surviving hypothesis, explicit LIMITs, what is still unproven)
raw/                          (xvlog / xelab / xsim logs, unedited)
one appended line             results/A7-NATIVE-GRAPH/STATUS/DISPATCH_LOG.jsonl
```

# RESULTS — `lm06_wm_00`

**Gate:** `lm06_wm_00` · **Agent:** `a7-ng-memory-arch`
**Preregistration:** `PREREGISTER.md`, written 05:28:35Z, amended 05:41Z, both **before** any RTL
edit and before any measurement.

## Verdict block — fixed by the parent (binding)

```text
result_class     PASS_NARROW
evidence_class   LM06_WM_XSIM
ladder           BLOCKED (unchanged)
BOARD            none
RESOURCE_BUDGET  not updated
```

Simulation-class only: **not** BOARD, **not** POST_ROUTE, **no** synthesis ran.

> **Human correction applied 2026-08-22 (post-measurement, binding).** An earlier revision of this
> file drew a correctness inference from a port-demand count ("max 2 tiles/cycle ⇒ ping-pong is
> sufficient"). That inference is **struck**; see §4 and LIMITs **L11 / L12 / L13** in `CLOSEOUT.md`.
> Traffic / reuse-distance material is **demoted to the BLOCKED ladder** and is not evidence here.
> `docs/native_graph/RESOURCE_BUDGET.md` was reverted to its pre-gate bytes and is **not updated**
> by this gate.

---

## 1. Runs executed

| tag | arm | working set compiled | seq | image | wall | verdict |
|-----|-----|----------------------|----:|-------|-----:|---------|
| `timing_probe` | CONTROL | frozen flat arrays | 1 | no | 55 s | RUN_PASS |
| `CONTROL_frozen` | CONTROL | frozen flat arrays | **9** | yes | 622 s | RUN_PASS |
| `CONTROL_n1` | CONTROL | frozen flat arrays | 1 | yes | 83 s | RUN_PASS |
| `CAND_ARMA` | **CANDIDATE Arm A** | bounded tiles, all resident | **9** | yes | 724 s | RUN_PASS |
| `CAND_ARMB_SNAP_n1` | **CANDIDATE Arm B** | enforced bounded snap pair | 1 | yes | 874 s | RUN_PASS |
| `CAND_ARMB_SNAP` | CANDIDATE Arm B | enforced bounded snap pair | 9 | — | **ABORTED** | see LIMIT L5 |
| `MUTANT_NEGCTL` | negative control | act port-A WRITE_FIRST | 1 | no | 81 s | **NOT DETECTED** |
| `MUTANT2_NEGCTL` | negative control | one dropped W write | 1 | no | 82 s | **DETECTED, FAIL** |

`xvlog` errors 0/0, `xelab` errors 0/0 on every run. Raw logs unedited in `raw/`, all SHA256'd in
`SHA256.txt`.

### What the two arms actually are — stated before any number is read

| arm | what it is | what it is **not** |
|-----|-----------|--------------------|
| **Arm A** | **Retile + accounting.** Every tile is still physically resident; the ownership / ping-pong state is instrumentation and never gates data. It proves *data equivalence of the restructure* and it *measures* access behaviour. | **Not a BRAM bound.** Arm A does **not** demonstrate a reduced BRAM footprint, a smaller tile count, or that a design holding fewer tiles works. No synthesis ran, so it carries no resource number at all. |
| **Arm B** | **Functional zero-latency model**, `u_snap` only, **n = 1**. Real writeback and real refill through a behavioural backing store, inside the full forward + update + fold. | **Not timed RTL.** The admit path is zero-latency. Arm B therefore carries **no timing, no throughput, and no latency-hiding claim** whatsoever. A synthesizable version needs a stall the frozen port list has no room for. |

### Ordering discipline (HLB R2)

```text
control run       05:40:49Z -> 05:51:12Z
control SEALED    05:51:36Z   (raw/CONTROL_SEAL_SHA256.txt)
candidate compile 05:53:51Z   <- strictly after the seal
candidate run     05:53:51Z -> 06:05:59Z
```

The candidate was not compiled until the control was archived and hashed. No candidate log timestamp
precedes the control seal.

### The two arms differ **only** in three memory files

`raw/xvlog_CAND_ARMA.log` records the exact analysed file list. The frozen arithmetic core
`rtl/lm/tiny_gpt803k_core.sv`, `a7lm06_pkg`, `isqrt32`, `floordiv_s48`, `weight_tile803k` and
`weight_bram_tdp8` are the **same files** in both arms (SHA MATCH, `FROZEN_VERIFY.md`). Substitution
is by module-name shadowing in a separate work directory, so no frozen source was edited.

---

## 2. EQUIVALENCE GATE — per-axis result

CONTROL = frozen LM-06. Tier-1 = board-recorded `ladder.json`. Tier-2 = frozen-RTL recorded control.

| # | Axis | Metric compared | Control tier | CONTROL | CANDIDATE Arm A | verdict |
|---|------|-----------------|--------------|---------|-----------------|---------|
| **A1** | same initial weights | `a7lm06_wmem.hex` SHA + `fold0` | T1 + T2 | `9A6BBC7A…`; `xor 5 / add 94638317` | identical file; `xor 5 / add 94638317` | **MATCH** |
| **A2** | same input | one bench file, one vector table | structural | `tb_a7ng_lm06_wm.sv` `35219708…` | same file, same SHA | **MATCH** |
| **A3** | same arithmetic | frozen source SHA, both arms | structural | 10 / 10 MATCH | 10 / 10 MATCH | **MATCH** |
| **A4** | same forward result | `pred`, `last_loss`, 9 seq | T1 + T2 | `744 / 16` + 8 more rows | byte-identical rows | **MATCH** |
| **A5** | same forward fold | `fold0 xor32 / add32` | T1 + T2 | `5 / 94638317` | `5 / 94638317` | **MATCH** |
| **A6** | same update result | `wr_n`, 9 seq | T1 + T2 | `655616` … `5900544` | identical | **MATCH** |
| **A6b** | recorded per-layer probes | 4 layers × 8 bytes post-update | **T1** | 32 / 32 bytes | `bad = 0` | **MATCH** |
| **A7** | same update fold | `fold1 xor32 / add32`, 9 seq | T1 + T2 | `23 / 94627297` … `41 / 94725643` | identical | **MATCH** |
| **A8** | persist / reload semantics | 802,816 B flush + reload + refold | T1 + T2 | `41 / 94725643` = pre-flush fold | identical | **MATCH** |
| **A9** | full weight image | 802,816 bytes, SHA + byte diff | T2 + T3 | `851D42AD…` | `851D42AD…`, **diff = 0 bytes** | **MATCH** |
| **A10** | recorded readback spots | 8 windows × 8 bytes pre-update | **T1** | 64 / 64 bytes | `bad = 0` | **MATCH** |

**Preregistered axes MATCHED: 11 / 11. Mismatches: 0.**

Machine-checked line-for-line: `WM00_AXIS` 10 lines diff 0, `WM00_CNT` 3 lines diff 0,
`WM00_ROW` 9 lines diff 0.

### Per-sequence rows (UNIT = one input sequence)

Identical in CONTROL and Arm A, every field, all nine rows:

| v | ntok | tokens | tgt | lr | pred | loss | `wr_n` (cum.) | fold xor | fold add |
|--:|-----:|--------|----:|---:|-----:|-----:|--------------:|---------:|---------:|
| 0 | 1 | `[1]` | 32 | 3 | **744** | **16** | **655616** | **23** | **94627297** |
| 1 | 1 | `[7]` | 100 | 1 | 744 | 16 | 1311232 | 142 | 94617530 |
| 2 | 2 | `[1,7]` | 5 | 3 | 100 | 16 | 1966848 | 169 | 94714667 |
| 3 | 3 | `[3,9,17]` | 200 | 2 | 32 | 16 | 2622464 | 63 | 94814141 |
| 4 | 1 | `[255]` | 1023 | 4 | 744 | 16 | 3278080 | 203 | 94682553 |
| 5 | 4 | `[0,1,2,3]` | 64 | 1 | 5 | 16 | 3933696 | 225 | 94817169 |
| 6 | 2 | `[128,64]` | 512 | 3 | 64 | 16 | 4589312 | 106 | 94861462 |
| 7 | 5 | `[11,22,33,44,55]` | 777 | 2 | 5 | 16 | 5244928 | 111 | 94798487 |
| 8 | 8 | `[1..8]` | 32 | 3 | 512 | 16 | 5900544 | **41** | **94725643** |

**Bold** = value also recorded on silicon in `ladder.json`. Row 0 reproduces the board exactly.
The nine folds are all different from each other, so the sequences genuinely drive the weight image
to nine distinct states — the MATCH is not a fixed point.

Sequences are chained: each `start_train` mutates the image, so row *k* runs on the image produced by
row *k−1*. A divergence anywhere would propagate into every later fold.

### Corroboration against a pre-gate recorded artifact (Tier-3)

`tests/xsim/a7lm06_after.hex` was written on 2026-08-18T17:38:38Z by a **different** bench
(`tb_a7lm06_core.sv`), four days before this gate.

| comparison | result |
|-----------|--------|
| `CONTROL_n1` image vs `a7lm06_after.hex[0 .. 802815]` | **0 differing bytes of 802,816** |

This independently validates the host-port readback path used for axis A9 against an artifact this
gate did not produce and did not modify.

### Arm B — enforced bounded pair (functional model, n = 1, **not timed RTL**)

`snap_ram4k16` restructured to `NLIVE = 2` resident tiles of 1024 words out of 4, with a **separate
backing store**, **real dirty writeback** on eviction and **real refill** on admit, running inside
the full LM-06 forward + update + fold.

The backing store is **zero-latency**. Arm B is therefore a *functional* model of a bounded working
set and carries **no timing, throughput or latency-hiding claim**. Its single contribution is the
correctness axis below: dirty data survived a real eviction/refill path bit-exactly at n = 1.

| axis | Arm B (n = 1) vs recorded control | verdict |
|------|-----------------------------------|---------|
| A4 `pred` / `loss` | `744 / 16` vs T1 `744 / 16` | MATCH |
| A5 `fold0` | `5 / 94638317` vs T1 | MATCH |
| A6 `wr_n` | `655616` vs T1 | MATCH |
| A6b layer probes | `bad = 0` (32 / 32 bytes) | MATCH |
| A7 `fold1` | `23 / 94627297` vs T1 | MATCH |
| A8 persist/reload refold | `23 / 94627297` | MATCH |
| A9 full image | SHA `44E24593…` = `CONTROL_n1` SHA `44E24593…` | **MATCH, 802,816 B** |
| A10 upload spots | `bad = 0` (64 / 64 bytes) | MATCH |

Dirty data survives eviction: **8 / 8 axes MATCH with real writeback and refill in the loop.**

---

## 3. HLB R3 — per-phase write counters

Proven from counters on the core's own write enables (`wwe`, `awe`, `snap_we`), **not** from the
absence of a write port. Phase is the window this bench commanded, so EVAL is not inferred.

Identical in CONTROL and Arm A (`WM00_CNT` diff 0), nine sequences:

| counter | UPLOAD | EVAL | TRAIN | AFTER | FOLD | RELOAD | preregistered expectation | verdict |
|---------|-------:|-----:|------:|------:|-----:|-------:|---------------------------|---------|
| `wr_w` (weights) | 0 | **0** | **5900544** | **0** | 0 | 0 | eval 0, after 0, train = 655616 × 9 | **PASS** |
| `wr_act` (activation scratch) | 0 | 169344 | 169344 | 6272 | 0 | 0 | > 0 in EVAL, transient not persistent | as expected |
| `wr_snp` (snapshot) | 0 | 23040 | 23040 | 2560 | 0 | 0 | reported, not gated | reported |

- `wr_w[EVAL] = 0` — no persistent-weight write occurs in an EVAL window. **Measured, not structural.**
- `wr_w[AFTER] = 0` — reproduces the recorded `after_gate` (`wr_n` unchanged at 655616).
- `wr_w[TRAIN] = 5900544 = 655616 × 9` — the per-sequence write count independently reproduces the
  board-recorded `wr_n = 655616` nine times over.
- `wr_act[EVAL] = 169344 = 6272 × 27` token-steps and `wr_snp[EVAL] = 23040 = 2560 × 9` are exact,
  which is why these counters are trustworthy as counters.

**Scope note, stated rather than glossed:** `wr_w` counts the core's own weight-write enable `wwe`.
The host upload path is the separate `host_we`/`mem_we`, which the bench holds low for the entire
EVAL and AFTER windows — that part is **structural** (visible in the bench source), not counted.
So the counter evidence covers the LM's own write path; the host load path is argued from the bench
stimulus.

---

## 4. Simultaneous port demand — a raw count, not a conclusion

This gate does **not** optimize BRAM. The rightmost column below is a count of **simultaneous port
demand** and nothing more. **No BRAM tile count, no working-set size, no ladder rung and no
96 / 64 / 48 / 32 value is derived from it.**

Arm A, nine sequences:

| working set | tile granularity | `pp_swaps` | `live_pair_events` | **distinct tiles demanded in the same cycle (max)** |
|-------------|------------------|-----------:|-------------------:|---------------------------------------------------:|
| `u_w` weight staging | 8 × 131,072 B (the frozen `A7-LM-06-TILE.md` region size) | 37,745 | **0** | **1** |
| `u_a` activation scratch | 8 × 16,384 × INT16 (one per `t`-slot) | 704,580 | 173,453,232 | **2** |
| `u_snap` snapshot | 4 × 1,024 × INT16 (n1 / n2 / attn / hid) | 144 | 26,112 | **2** |

The only permitted reading of that column, scoped to this workload:

> **In this workload, at most 2 tiles are demanded in the same cycle.**

Nothing further is claimed from it. In particular this count does **not** establish that the
working set is 2 tiles, does **not** establish that a ping-pong pair suffices for correctness, and
does **not** establish that DDR latency is hidden. Those are separate unknowns and none of them was
measured here. The bit-exactness result in §2 stands on the per-axis comparison against the recorded
frozen CONTROL, **not** on this count — deleting this section entirely would not weaken §2.

### Traffic / reuse distance — carried to the ladder, **not evidence here**

Arm B produced swap, refill and dirty-writeback counters. **These are not findings of this gate.**
Traffic and reuse-distance analysis is the unknown owned by `lm06_wm_01..04`, which remain
**BLOCKED** and were not opened, previewed or partially started. The raw counters are left in
`raw/xsim_CAND_ARMB_SNAP_n1.log` for whichever agent the parent eventually dispatches to that
ladder. They are deliberately **not** interpreted here, **not** converted into DDR bytes, a burst
depth, a residency depth, a tile count or a policy, and **not** used to support any statement in
this document. Arm B's only role in this gate is the correctness axis in §2: dirty data survived a
real eviction path bit-exactly.

---

## 5. Negative controls — what the bench can and cannot see

"All axes MATCH" is only meaningful if the bench can detect a perturbation. Two deliberately broken
candidates were run. Both results are reported, including the inconvenient one.

### MUTANT-2 — one dropped weight write out of 802,816 — **DETECTED**

`a7ng_lm06_wm_wbank.sv` drops the write when `sel_a == 2 && loc_a == 12345` (byte address 274,489,
inside the L0 region). Minimal "lost dirty byte on eviction" defect, rival RV5.

| axis | result |
|------|--------|
| A4 `pred` / `loss` | **FAIL** — `0 / 0` vs recorded `744 / 16` |
| A5 `fold0` | **FAIL** — `0 / 0` vs recorded `5 / 94638317` |
| A7 `fold1` | **FAIL** — `0 / 0` vs recorded `23 / 94627297` |
| A6b layer probes | **FAIL** — **21 of 32** recorded bytes differ, across all four layers |
| A10 upload spots | passed — none of the 8 recorded windows covers address 274,489 |
| overall | `RUN_FAIL fails=4` |

Honest caveat on this mutant: because the dropped write also blocks the initial upload at that
address, the location stays uninitialised and the divergence is **amplified by X propagation** (hence
the `0 / 0` folds rather than a clean one-byte delta). So what is demonstrated is *a single-address
write defect is detected on four independent axes*, not *a one-byte value delta is detected in
isolation*. The 21-of-32 recorded-probe divergence is the cleanest part of the signal.

### MUTANT-1 — activation port-A WRITE_FIRST instead of READ_FIRST — **NOT DETECTED**

`a7ng_lm06_wm_act.sv` flips port-A read-during-write collision behaviour, rival RV1 — the most
plausible slip when a flat array is split into tiles.

| axis | result |
|------|--------|
| every preregistered axis A4 – A10 | MATCH |
| overall | `RUN_PASS fails=0` |

**Interpretation:** the frozen LM-06 access pattern never reads and writes the *same* activation
address on port A in the *same* cycle, so the collision policy is unobservable in this workload. The
mutant was therefore not a valid falsifier.

**Consequence for the claim, stated as a limit and not buried:** the bit-exactness result does
**not** cover read-during-write collision semantics on `u_a` port A. That axis is untested here
because the workload does not exercise it. A future restructure that *does* introduce a collision
(for example a genuinely time-multiplexed shared port under `bram_owner_00`) cannot inherit this
result.

---

## 6. Hypothesis disposition

| hypothesis | disposition | basis |
|------------|-------------|-------|
| **H_CANDIDATE** — candidate == CONTROL on every applicable axis | **SUPPORTED** | 11 / 11 axes, 9 sequences, 2 arms, 802,816-byte image SHA-identical, 20 board-recorded points reproduced |
| **H_RIVAL / RV1** collision semantics differ once split | **UNTESTABLE in this workload** | MUTANT-1 undetected: no same-address same-cycle collision on `u_a` port A |
| **H_RIVAL / RV2** read latency changes | **FALSIFIED** | folds, `pred`, `loss` and the full image are exact across 9 chained sequences; a latency change would desynchronise the FSM immediately |
| **H_RIVAL / RV3** fold order changes across tile boundaries | **FALSIFIED** | `fold0` and all 9 `fold1` values exact; the fold walks all 802,816 addresses and crosses every tile boundary |
| **H_RIVAL / RV4** dual-port aliasing across tiles | **FALSIFIED** | port A and port B are decoded independently; `u_a` addresses two distinct tiles in 173 M cycles with zero divergence |
| **H_RIVAL / RV5** enforced eviction loses dirty bytes | **FALSIFIED** for the snap pair, n = 1 only | Arm B: real dirty writebacks and real refills both occurred (counters in `raw/xsim_CAND_ARMB_SNAP_n1.log`, not interpreted here), image still SHA-identical |
| **H_RIVAL / RV6** `pred` matches but image or probes do not | **FALSIFIED** | image byte diff 0; 32 / 32 layer-probe and 64 / 64 upload-spot recorded bytes exact |

MUTANT-2 shows the axes that falsified RV3 / RV5 / RV6 are live and not vacuous.

---

## 7. Falsifier ledger

| # | Falsifier | Triggered? |
|---|-----------|-----------|
| F1 | any non-bit-exact axis | **NO** — 11 / 11 MATCH |
| F2 | LM-06 arithmetic law / weights / geometry / other law changed | **NO** — same core file, same weight file, SHA MATCH |
| F3 | frozen bit / manifest / `mig.prj` / frozen RTL byte-modified | **NO** — 16 / 16 MATCH, 0 mismatch |
| F4 | CONTROL computed at compare time | **NO** — `python/ref/a7lm06_fixed_ref.py` never invoked; Tier-1 transcribed from a 3-day-old silicon recording; Tier-2 sealed before candidate compile |
| F5 | EVAL zero-write argued from port absence | **NO** — `wr_w[EVAL] = 0` from a counter on `wwe` |
| F6 | LM tile sized from the `ddr_wavefront_00` summed counter | **NO** — tile granularity taken from `A7-LM-06-TILE.md` and the frozen address map; the 512 B carry-in is not used anywhere |
| F7 | single input vector presented as the replication unit | **NO** — 9 sequences; and the n = 1 Tier-1 limit is stated explicitly, not hidden |
| F8 | board claim / COM12 / `r2_rdb` / BOARD_PASS | **NO** — no synthesis, no bitstream, no programming, no board claim |

---

## 8. Preregistered metrics not obtainable in this gate

Reported as absent rather than substituted:

```text
BRAM tile count    ABSENT - no synthesis ran
LUT / FF / LUTRAM  ABSENT - no synthesis ran
DSP                ABSENT - no synthesis ran
WNS / TNS          ABSENT - no implementation ran
DDR read/write B   ABSENT - SIM_FULL=1 reference path has no DDR
stall fraction     ABSENT - same reason
```

`FITS != RUNS`. `XSIM != BOARD`. `POST_ROUTE != FUNCTIONAL_INTEGRATION`. This gate has none of the
three.

# CLOSEOUT — `lm06_wm_00`

## Verdict block — fixed by the parent (binding, verbatim)

```text
result_class     PASS_NARROW
evidence_class   LM06_WM_XSIM
ladder           BLOCKED (unchanged)
BOARD            none
RESOURCE_BUDGET  not updated
```

Simulation-class. **Not BOARD. Not POST_ROUTE. No synthesis ran.**

**Agent:** `a7-ng-memory-arch` · **Marker:** `A7NG_LM06_WM00_XSIM_EQUIV_PASS`
**Artifact:** `results/A7-NATIVE-GRAPH/LM06-WM-00/RESULTS.md`
**Preregistration:** `PREREGISTER.md` — written 05:28:35Z, amended 05:41Z, both before any RTL edit
and before any measurement.

### Human correction applied post-measurement (2026-08-22, binding)

Recorded here so no later reader can recover what was struck:

1. The inference *"max 2 tiles/cycle ⇒ ping-pong is sufficient for correctness"* is **deleted**. The
   measurement is simultaneous **port demand** only. See **L11**.
2. Traffic / reuse-distance analysis is **demoted** — it belongs to `lm06_wm_01..04`, not here. See
   **L12**.
3. Arm A and Arm B are re-described honestly: Arm A is **retile + measurement, not a BRAM bound**;
   Arm B is a **functional zero-latency n = 1 snapshot model, not timed RTL**. See **L13**.
4. `docs/native_graph/RESOURCE_BUDGET.md` was **reverted to its pre-gate bytes**; this gate updates
   no budget.

---

## The one unknown, and the answer

> Can a **bounded / ping-pong** LM-06 working-set implementation remain **bit-exact** with frozen
> LM-06?

**Yes — on all 11 preregistered equivalence axes, over 9 input sequences, in two independent
candidate arms, with the full 802,816-byte weight image SHA-identical and 20 board-recorded control
points reproduced exactly.**

The load-bearing numbers:

| what | result |
|------|--------|
| preregistered equivalence axes | **11 / 11 MATCH**, 0 mismatch |
| board-recorded points reproduced (`hardware_c3/ladder.json`, bit `222F8043…`) | **20 / 20** |
| full post-update weight image, CONTROL vs CANDIDATE | **0 differing bytes of 802,816**; SHA `851D42AD…` on both |
| per-sequence rows (`pred`, `loss`, `wr_n`, fold `xor`, fold `add`) | **9 / 9 identical**, nine *distinct* weight-image states |
| `wr_w[EVAL]` / `wr_w[AFTER]` from per-phase counters | **0 / 0** |
| `wr_w[TRAIN]` | 5,900,544 = 655,616 × 9 — reproduces the recorded `wr_n` nine times |
| enforced bounded snap pair, functional model, **n = 1** (real writeback + refill) | **8 / 8 axes MATCH**, image SHA-identical |
| frozen files re-hashed | **16 / 16 MATCH**, 0 mismatch |

## Which hypothesis survived

**H_CANDIDATE survived.** **H_RIVAL is falsified on four of its five testable arms and is untestable
on the fifth.**

| hypothesis | disposition |
|------------|-------------|
| **H_CANDIDATE** — candidate == CONTROL on every applicable axis | **SUPPORTED** |
| RV2 read latency changes | **FALSIFIED** |
| RV3 fold order changes across tile boundaries | **FALSIFIED** |
| RV4 dual-port aliasing across tiles | **FALSIFIED** |
| RV5 enforced eviction loses dirty bytes | **FALSIFIED** for `u_snap` at n = 1 (real dirty writebacks and real refills both occurred; image still identical) |
| RV6 `pred` matches but image or per-layer probes do not | **FALSIFIED** |
| RV1 read-during-write collision semantics differ once split | **UNTESTABLE in this workload** — see LIMIT L4 |

The result is not vacuous: a deliberately broken candidate that drops **one** weight write out of
802,816 was **detected** on four independent axes, including 21 of 32 board-recorded per-layer probe
bytes.

## Preconditions from the auditors — how each was discharged

| precondition | how it was met |
|--------------|----------------|
| **HLB R2** — CONTROL must be *recorded* from frozen LM-06 before the candidate runs, never host-computed | Tier-1 control is `results/A7-LM-06/hardware_c3/ladder.json`, SHA `37A53A73…` MATCH to contract, recorded on silicon 2026-08-18T19:24Z from bit `222F8043…` SHA MATCH — **3 days before this gate**. Tier-2 (frozen-RTL, 9 sequences) was run, archived and SHA-sealed at **05:51:36Z**; the candidate was not compiled until **05:53:51Z**. `python/ref/a7lm06_fixed_ref.py` was **never invoked**. No host computed a token, loss, activation, fold or weight byte. |
| **HLB R3** — once WM tiles are writable, prove EVAL writes are zero from *counters*, not port absence | Counters on the core's own weight-write enable `wwe`, bucketed by the window the bench commanded: `wr_w[EVAL] = 0`, `wr_w[AFTER] = 0`, `wr_w[TRAIN] = 5,900,544`. The counters are demonstrably trustworthy because the activation and snapshot counters land on exact expected products (6,272 × 27 and 2,560 × 9). Scope stated in `RESULTS.md` §3: the *host* load path `mem_we` is argued structurally, not counted. |
| **MAJOR-2** — do not size LM tiles from the `ddr_wavefront_00` summed-occupancy counter | The 512 B / 176 B / 3 KiB carry-in is **not used anywhere** in this gate. Tile granularity came from `docs/contracts/A7-LM-06-TILE.md` (131,072-byte W region) and the frozen address maps (`ACT_STRIDE = 16384`, snap quarter = 1024). The only carry-in relied on is the qualitative one that survives the caveat: delivery is ≈2 RAMB18 tiles or less, so delivery is not what competes with LM-06's ~132 tiles. |
| **R1** — do not let a retrieval/answer claim ride the per-batch `a7ng_topk` | Not exercised. This gate contains no retrieval, no Top-K, no scorer and no answer path. No claim rides that stage. |

## What this gate deliberately did not do

**It did not optimize BRAM.** No 96 / 64 / 48 / 32 target was pursued, no tile count was reduced, no
Pareto point was declared, no ladder rung was claimed. `lm06_wm_01..04` and `lm06_wm_ladder` were not
opened, not previewed and not partially started. `bram_owner_00`, `mig_sweep_full`,
`bram_ownership_report`, `record_schema_freeze`, `mig_pe_wide` and `full_integration` were not
touched.

One raw count was taken, and it is stated as a bare observation with no conclusion attached:

> **In this workload, at most 2 tiles are demanded in the same cycle.**

That is simultaneous **port demand**, nothing more. It is **not** a working-set size, **not** a BRAM
number, **not** evidence that a ping-pong pair suffices for correctness, **not** evidence that DDR
latency is hidden, and **not** a recommendation. The bit-exactness result of this gate rests on the
per-axis comparison against the recorded frozen CONTROL and would stand unchanged if this count were
deleted.

## Prior evidence cited, not re-claimed

`weight_tile803k` with `SIM_FULL = 0` is already a bounded, evict-and-refill, single-region W working
set, and the C3 silicon run executed it while producing folds identical to the flat monolith. That
pre-existing **board-class** existence proof for a bounded W working set belongs to LM-06's own
close, not to this gate. This gate cites it (`CONTROL_PROVENANCE.md`). It adds one raw observation
alongside it — `live_pair_events = 0` on `u_w` — and draws **no** conclusion from that count about
why the frozen design works.

---

## LIMITs — explicit

| # | LIMIT |
|---|-------|
| **L1** | **Simulation-class only.** No synthesis, no implementation, no bitstream, no board. BRAM / LUT / FF / LUTRAM / DSP / WNS / TNS are **ABSENT**, not favourable. `FITS != RUNS`, `XSIM != BOARD`, `POST_ROUTE != FUNCTIONAL_INTEGRATION`. Nothing here says the restructure *fits* or *closes timing*. |
| **L2** | **The board-recorded control is n = 1 input sequence.** `ladder.json` records exactly one recipe (`ctx [1] / tgt 32 / lr 3`) because that is the only silicon-recorded LM-06 forward/update in the repository. The other 8 sequences are `XSIM_RTL_RECORDED` — the frozen RTL as its own control, a **strictly lower class**. This is the single largest reason the verdict is NARROW. Repairing it needs a board run, which this session is forbidden from doing; it must **not** be repaired with a host oracle. |
| **L3** | **Arm A is retile + measurement, not a BRAM bound.** Every tile is still physically resident; the ownership / ping-pong state is instrumentation and never gates data. Arm A proves *data equivalence of the restructure* and *measures* access behaviour. It does **not** demonstrate a reduced BRAM footprint, a smaller tile count, or that a design holding only the live pair works. |
| **L4** | **Read-during-write collision semantics on `u_a` port A are untested.** The negative control that flips port A to WRITE_FIRST was **NOT DETECTED** — the frozen access pattern never reads and writes the same activation address in the same cycle. The bit-exactness claim therefore does not cover that axis, and any future restructure that introduces such a collision (a genuinely time-multiplexed shared port, e.g. under `bram_owner_00`) **cannot inherit this result**. |
| **L5** | **Arm B is a functional zero-latency model at n = 1, not timed RTL.** It enforces a bounded pair only on `u_snap`, only for one input sequence, and its admit path is **zero-latency**. A synthesizable version needs a stall the frozen port list has no room for. The 9-sequence enforced run was **ABORTED** as infeasible in this session (partial log retained as `raw/xsim_CAND_ARMB_SNAP_nvec9_ABORTED.log`, reason recorded there); the preregistered **Arm B extended** (enforced `u_a`, NLIVE 4 of 8) was **NOT RUN**. Both are stated as gaps, not dropped. |
| **L6** | **Whether a bounded working set is affordable is not addressed by this gate at all.** Arm B's swap / refill / writeback counters exist in the raw log but are **not** findings here — see **L12**. Correctness was the only question asked of Arm B, and correctness is the only thing it answers. |
| **L7** | **The W restructure was exercised on the reference path only.** The candidate shadows `weight_bram803k`, which is the `SIM_FULL = 1` flat reference. The silicon-shaped tile path (`weight_bram_tdp8` inside `weight_tile803k` at `SIM_FULL = 0`) was **not** restructured or re-verified here. |
| **L8** | **Axis A8 is a surrogate for the DDR persist round trip.** Persist/reload was proven by flushing all 802,816 bytes out through the host port, writing every byte back, and re-folding — plus the recorded Tier-1 persist digest. The full DDR flush/reload through `lm06_persist` over the AXI MIG at 802,816 bytes was **not** re-run in this gate; that path's evidence remains LM-06's own board close. |
| **L9** | **`wr_w` counts the core's write enable, not the host's.** `wr_w[EVAL] = 0` is a genuine counter result on `wwe`. That `mem_we` is also low throughout the EVAL and AFTER windows is **structural** (bench stimulus), not counted. |
| **L10** | **Replication is over input sequences, not seeds or orderings.** 9 sequences varying context length (1–8), token identity (0–255), target class (5–1023) and learning rate (1–4), run as one chained trajectory. There is no seed axis, no sequence-order permutation, and no second independent weight image. |
| **L11** | **The tiles-per-cycle count is simultaneous port demand and nothing else.** The only permitted reading is: *in this workload, at most 2 tiles are demanded in the same cycle.* It does **not** establish that the working set is 2 tiles, does **not** establish that a ping-pong pair suffices for correctness, and does **not** establish that DDR latency is hidden. An earlier revision of `RESULTS.md` and this file drew exactly that inference; a human struck it. No correctness conclusion may be drawn from a port-demand count. |
| **L12** | **No traffic or reuse-distance finding is claimed by this gate.** That analysis is the unknown owned by `lm06_wm_01..04`, which remain **BLOCKED** and were not opened, previewed or partially started. Arm B's swap / refill / dirty-writeback counters are left uninterpreted in `raw/xsim_CAND_ARMB_SNAP_n1.log` and are **carried to the ladder, not evidence here**. They are not converted into DDR bytes, a burst depth, a residency depth, a tile count or a policy, and no statement in this closeout rests on them. |
| **L13** | **Neither arm carries a resource or timing claim.** Arm A is **retile + measurement**, not a BRAM bound — it shows no reduced footprint (see L3). Arm B is a **functional zero-latency n = 1 snapshot model**, not timed RTL — it carries **no timing, throughput or latency-hiding claim** (see L5). Combined with L1 (no synthesis), this gate produces **zero** resource numbers and **zero** timing numbers, and `docs/native_graph/RESOURCE_BUDGET.md` is therefore **not updated**. |

## What is still unproven

Stated plainly, because a PASS_NARROW that hides this is worthless:

```text
1. That the restructure FITS.        No synthesis ran. No BRAM tile count exists for the candidate.
                                    The 260 -> <=135 integration problem is untouched by this gate.
2. That it CLOSES TIMING.            No WNS, no TNS, no post-route. A bank-select mux on a BRAM
                                    read path is exactly the kind of change that can cost timing.
3. That a truly BOUNDED LM-06 works. Enforced residency was shown correct only for u_snap, only at
                                    n=1, and only as a zero-latency functional model. A synthesizable
                                    bounded working set needs a stall path that does not exist yet.
4. That a bounded set is affordable. Not asked and not answered. Traffic / reuse distance belongs to
                                    the BLOCKED ladder, not to this gate (L12).
5. That this holds on silicon.       XSIM != BOARD. No bitstream, no COM12, no board run.
6. Collision semantics on u_a.       Untested - the workload does not exercise them (L4).
7. Anything about the ladder.        No rung is claimed. 96/64/48/32 remain unmeasured and BLOCKED.
8. That the working set is 2 tiles.  Never measured. What was measured is simultaneous port demand
                                    (L11), which supports no such conclusion.
```

## Ladder decision — not mine to make

The doctrine says *"Open the ladder only if `candidate == frozen CONTROL`."* That equivalence
condition **is met for the 11 axes measured, at the evidence classes stated above**. Whether those
classes are sufficient to unblock `lm06_wm_ladder` is a decision for the parent and the auditors,
who should weigh L1 (no synthesis), L2 (board control is n = 1) and L5 (enforced arm is narrow and
non-synthesizable) before flipping anything. **This agent opens no gate and edits no `LOOP_STATE`.**

## Session law compliance

| requirement | status |
|-------------|--------|
| ONE unknown, ONE implementer | Yes — bit-exact equivalence only |
| no other gate opened / ticked / previewed / partially started | Yes — `lm06_wm_01..04`, `lm06_wm_ladder`, `bram_owner_00`, `mig_sweep_full`, `bram_ownership_report`, `record_schema_freeze`, `mig_pe_wide`, `full_integration` all untouched |
| no BRAM optimization / no 96-64-48-32 targeting | Yes — no tile count claimed, no rung declared |
| `PREREGISTER.md` written before any RTL edit or measurement | Yes — 05:28:35Z, amendment 05:41Z, first RTL file written after |
| CONTROL recorded before candidate ran | Yes — sealed 05:51:36Z, candidate compiled 05:53:51Z |
| no COM12 program, no board run | Yes — zero programming events, newest `.bit` mtime 2026-08-18 |
| no `r2_rdb` latch | Yes |
| frozen law / weights / bits / manifests / `mig.prj` untouched | Yes — 16 / 16 SHA MATCH, `mig.prj` `870FA6EE…` MATCH |
| `LOOP_STATE.json` not edited by this agent | Yes — parent flips it. **Disclosure:** its mtime moved to 06:16:15Z (inside the gate window) while its content stayed semantically identical (`updated` still `05:20:00+00:00`, `next` still `lm06_wm_00`, `lm06_wm_00` still OPEN, ladder / `bram_owner_00` / `full_integration` still BLOCKED, queue length 52). No write was issued to that path by this agent. SHA at closeout `A4494B6AF9BC0749498C74D14F83256FEB59967E03E313255122D992A2250067`. **Second disclosure:** during the human-correction pass the file was found changed *again* by the parent (mtime 06:34:45Z, now 35,076 B / `963C79C2…`), with `next`, `updated`, queue length and all four gate statuses still unchanged. Both observations are detailed in `FROZEN_VERIFY.md` §5. |
| AI does not declare BOARD_PASS | Yes — no board claim anywhere; `NATIVE_V1_MINI_AI_BOARD_PASS` remains NOT_EVIDENCED |
| after CLOSEOUT: STOP | Yes |

## CHANGED

| path | role |
|------|------|
| `rtl/native_graph/memory/a7ng_lm06_wm_wbank.sv` | **NEW** — W working set as 8 × 131,072 B bounded region tiles + ping-pong accounting (+ `A7NG_WM_MUTANT2` negative control) |
| `rtl/native_graph/memory/a7ng_lm06_wm_act.sv` | **NEW** — activation working set as 8 × 16,384 INT16 bounded t-slot tiles + ping-pong accounting + optional enforced bound (+ `A7NG_WM_MUTANT` negative control) |
| `rtl/native_graph/memory/a7ng_lm06_wm_snap.sv` | **NEW** — snapshot working set as 4 × 1,024 INT16 bounded tiles + optional **enforced** bounded pair with real backing store, writeback and refill |
| `tests/xsim/tb_a7ng_lm06_wm.sv` | **NEW** — one equivalence bench driving both arms; Tier-1 recorded control transcribed as constants; per-phase write counters; 9-sequence vector table; full-image readback + persist/reload surrogate |
| `tests/xsim/run_a7ng_lm06_wm.ps1` | **NEW** — arm-selecting runner; compiles exactly one working-set set per run into a separate work directory |
| `results/A7-NATIVE-GRAPH/LM06-WM-00/**` | PREREGISTER, CONTROL_PROVENANCE, RESULTS, FROZEN_VERIFY, SHA256, CLOSEOUT, `raw/` logs and images |
| `docs/native_graph/RESOURCE_BUDGET.md` | **NOT changed.** An earlier revision appended an `lm06_wm_00` section; on human ruling it was **reverted byte-for-byte** to its pre-gate content (12,333 bytes, SHA `AA6ECC17AC50A349511300D399A6187CB47A404A657AC8FD5C9B483DF272BDFC`, zero `lm06_wm` references). This gate updates no budget — see L13. |
| `results/A7-NATIVE-GRAPH/STATUS/DISPATCH_LOG.jsonl` | one appended line |

**NOT changed:** every frozen LM-06 source (`tiny_gpt803k_core.sv`, `a7lm06_pkg.sv`, `isqrt32.sv`,
`floordiv_s48.sv`, `weight_tile803k.sv`, `weight_bram_tdp8.sv`, `weight_bram803k.sv`,
`act_ram128k16.sv`, `snap_ram4k16.sv`, `lm06_persist.sv`); `arty_a7_lm06c3.bit` and every frozen
LM bitstream; `hardware_c3/ladder.json`; `a7lm06_wmem.hex`; `a7lm06_after.hex`;
`a7lm06_expected.txt`; `tb_a7lm06_core.sv`; `mig.prj`; LM-06 arithmetic law `lm06-signsgd-v1`;
01R law; `HIT_MAX`; 02M law; TermGen law; Top-K law; relation law; encoder; learning/training law;
HNSW; NTDE; every frozen manifest; `LOOP_STATE.json`.

## NEXT

**STOP.** Parent runs verify/audit and decides what follows. `lm06_wm_ladder` stays BLOCKED unless
the parent and auditors judge the stated evidence classes sufficient. No COM12. No board latch.
GOAL `NATIVE_V1_MINI_AI_BOARD_PASS` = **NOT EVIDENCED**. A human declares it.

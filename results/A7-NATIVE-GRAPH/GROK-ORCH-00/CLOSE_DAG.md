# Native AI V1 — Close DAG (Grok-orch-00)

**Written:** 2026-08-29  
**Lane:** `research/native-ai-v1-grok-orch-00`  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**PROGRAM:** NO on this tree.  
**Authority (in order):** UART/board evidence > this charter `research/NATIVE_AI_GROK_ORCH_LANE.md` > MAIN `results/A7-NATIVE-GRAPH/STATUS/MASTER_PREFLIGHT.md` (live) > `EXISTENCE_BEFORE_QUALITY.md` > `NATIVE_AI_V1_ROADMAP.md` > frozen BOARD_PASS releases.  
**Stale — do not drive from:** `NATIVE_V1_CLOSURE.json` (2026-08-28), grok-orch `STATUS/MASTER_PREFLIGHT.md` (14:08), `P0_P1_BACKLOG.md`, `GROK_TRACK_CURSOR.md` (08-21).

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
Encoder silicon / Kidi / A1 / 800k / GlassBox = AFTER existence.
Ungated DIFF twin on MAIN is already NO-GO 11/11 at 100k — do not re-run as if untested.
```

AI never stamps `BOARD_PASS`, `NATIVE_V1_EXISTENCE_BOARD_PASS`, or `NATIVE_V1_MINI_AI_BOARD_PASS`.

---

## 0. Law (do not invert)

```text
EXISTENCE  = UART line NATIVE_V1_EXIST_ROW,pred=664 on one Arty SoC bit
             with host_next_token=0. ABSENT as of 2026-08-29T19:55+07.

QUALITY    = HS-02 semantic, held-out wording, 800k, tok/s, BRAM Pareto.
             Forbidden until EXISTENCE PASS.

FITS != RUNS != TRAINS != CONVERGES != USEFUL
XSim != board. UNIT_PASS != pred=664. Harness != HS-02.
LM-06 standalone golden 744 != Native-V1 664.
```

Sacrifice cycles, spare BRAM/LUT/DSP, and peak tok/s to get the chain to print `pred=664`. Do not sacrifice FPGA-owned winner/address/token or teacher-off authority.

### Close hierarchy (locked)

```text
P0  fence XSim (one unknown / gate, PROGRAM=NO)
P1  licensed live-RTL fence merge + composition XSim (PROGRAM=NO)
P2  new bit + new com12_authorized_gate + Cursor program + UART pred=664
    → human NATIVE_V1_EXISTENCE_BOARD_PASS
P3  encoder stability / geometry / BOARD   (silicon only after P2)
P4  KIDI20 / KIDI40_TEACHER_OFF
P5  A1  03E → 01R → 02M
P6  memory scale ladder (20 … 800k) — do not jump
P7  LM-06 in output path + teacher-off + reset/retrain
    → human NATIVE_V1_MINI_AI_BOARD_PASS
P8  GlassBox observe-only
```

`graph_late_materialize_00` stays **QUEUED / DEFERRED** (`deferred_by=EXISTENCE_BEFORE_QUALITY`). Not an existence gate. Do not Task it.

---

## 1. Trees, owners, one board

| Role | Path | Branch | Who | Board |
|------|------|--------|-----|-------|
| Authority / STATUS / encoder 03E | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm` | `master` | mailbox | no |
| Cursor silicon | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board` | `native-v1-board-lane-stage0` | **owns JTAG/COM12** | **YES** until `pred=664` |
| Grok-orch (this) | `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` | `research/native-ai-v1-grok-orch-00` | XSim / plan / encoder research | **PROGRAM=NO** |
| Leftover — do not use | `*-codex-ng05`, `*-codex-phase2`, `*-board-research-e2r-cfix-00` | other | — | no |

**One physical Arty A7-100T.**

| Port | Serial | Owner until `pred=664` |
|------|--------|------------------------|
| JTAG FTDI A | `210319BE776EA` | Cursor board tree |
| UART B COM12 | `210319BE776EB` | Cursor; arm capture **before** program |

`lock.owner=grok` (R6) is the mailbox lock. It does **not** license Grok `open_hw_manager`. Grok must not steal JTAG/COM12 while Cursor holds the board.

### Board windows

| Window | Owner | Allowed | Forbidden |
|--------|-------|---------|-----------|
| **W0 now** until UART `pred=664` | **Cursor** on board tree | Fence XSim; program **only** with a **fresh** `com12_authorized_gate` matching the new existence bit; arm COM12 first | Leftover LONGBOOT / two-pass as hang-fix; dual-read; pin-POS; `SIM_FULL=1` on silicon |
| **W0 now** Grok-orch | Grok | XSim / docs / encoder **read** of MAIN `results/A7-EAM-03E`; draft next prereg; independent VERIFY_ONLY | `open_hw_manager`; merge into Cursor dirty `rtl/`; duplicate implementer on a DISPATCHED gate |
| **W1** after human `NATIVE_V1_EXISTENCE_BOARD_PASS` | Human names next token | Encoder silicon, Kidi, A1 | Not before W1 |
| Plug ≠ program | — | COM12 present is not a license | `com12_authorized_gate=null` or leftover consume |

UART: arm COM12 before `program_hw_devices`. 0-byte capture → recapture before design FAIL.

---

## 2. Snapshot of fact (2026-08-29T19:55+07)

### Existence

| Claim | Status | Class |
|-------|--------|-------|
| UART `pred=664` | **ABSENT** | FACT |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **NO** | FACT |
| Stage A XSim `pred=664` (`A-FAST-LM-BOARD-LANE-00`) | PASS (sim) | XSim ≠ board |
| Two-pass EMB XSim `pred=664` | PASS_NARROW | XSim ≠ board; bit inventory only |
| LONGBOOT UART | CLASS=`STILL_STALL` 2470 s / 593 B; `PRED_LINES=NONE`; `CORE_DONE=False` | BOARD, authorize **consumed** |

### Fence composition (XSim, not existence)

| Gate | Class | One unknown | PROGRAM |
|------|-------|-------------|---------|
| `E2R-OWNER-FENCE-XSIM-00` | **AB_COMPOSE** | unowned `m_go` issues + `FALSE_AR` | NO |
| `E2R-OWNER-ISSUE-GATE-00` | **ISSUE_GATED** | `cmd_wr_en && m_owner` | NO |
| `E2R-OWNER-POP-GATE-00` | **POP_GATED** | `cmd_rd_en && s_owner` | NO |
| `E2R-OWNER-FENCE-CFIX-SNAP-00` | **UNSTABLE** | live files rewritten mid-snap | NO |
| `E2R-OWNER-FENCE-CFIX-SNAP-01` | **ISSUE_GATED** | unowned blocked on snap copies; ready-gate **not** elaborated | NO |
| `E2R-OWNER-READY-SNAP-00` | **READY_GATED** | owned AR then drop; `OWNED_AR=1` `DROP_AR_ADVANCE=0` `DROP_ST=4` | NO |
| `E2R-OWNER-READY-OPEN-CTRL-00` | **OPEN / DISPATCHED** | same park/drop/raise, **ungated** `arready` | NO |

READY-SNAP auditor MINOR: `DROP_AR_ADVANCE` has no same-protocol ungated CONTROL. That is why OPEN-CTRL exists. `MUX_FALSE_AR=1` with `DROP_ST=4` is informational occupancy, **not** the discriminator.

### Live board-tree dirt (HOLD)

Sealed POP / SNAP-01 HOLD hashes (do not stack another live implementer):

| File | HOLD SHA256 prefix |
|------|--------------------|
| `rtl/board/a7ng_wdma_cdc.sv` | `C02F0D54…` |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | `3C2BE8B4…` |
| `rtl/lm/weight_tile803k.sv` | `9EE30702…747…` |
| `rtl/ddr/ddr_tile_dma.sv` | `20BAE36E…` (CONTROL, MATCH) |
| `rtl/lm/tiny_gpt803k_core.sv` | `355182A7…` two-pass candidate (prior gate; not this unknown) |

Concurrent unlicensed C-FIX moved live files (`DIRT_E2R_OWNER_FENCE_CFIX.md`). **STOP RTL** on live `rtl/` until human DECIDE + dirt freeze. SNAP bags are the DUT, not live.

### Encoder (MAIN `results/A7-EAM-03E`) — research only until W1

| Experiment | Verdict | Do not |
|------------|---------|--------|
| A0.3 signed `h` | XSim + silicon exact | re-open arithmetic |
| S2 Wh-clamp | **FALSIFIED** | tighten clamp |
| E1 ungated DIFF `eam03e-a03-ungated-diff-v1` 100k | **NO-GO 11/11** (rank collapse, `unique_d1→1`) | re-run as first medicine |
| E2-A S1 rate÷16 | FAIL 11/11 | treat as next silicon |
| Standing candidate | triplet hinge + S3 `>>3` (rank holds; peak ~0.75 then drifts) | glue 01R/02M/LM-06 onto collapsed encoder |

H5 gate *description* is correct (71% DIFF suppressed). H5-as-sole-cause is **falsified**. Next encoder unknown is **not** existence-critical-path.

---

## 3. DAG

```text
                    ┌─────────────────────────────────────────┐
                    │  FORBIDDEN until UART pred=664           │
                    │  graph_late_materialize_00               │
                    │  HS-02 / 800k / GlassBox / encoder Si    │
                    │  Kidi / A1 / Mini-AI claim               │
                    │  leftover 9DC0F8DF / 15B0E502 hang-fix   │
                    └─────────────────────────────────────────┘

W0  PROGRAM=NO
    │
    ▼
[G0] E2R-OWNER-READY-OPEN-CTRL-00     ← NOW (DISPATCHED 19:55; bag not sealed)
    XSim · no rtl/ · same park/drop/raise · ungated arready
    Cursor implementer (board tree) · Grok VERIFY_ONLY / no re-dispatch
    │
    ├─ CLASS=READY_OPEN  (H_CANDIDATE: discriminator live)
    │     ▼
    │  [G1] E2R-OWNER-RELEASE-QUIESCE-00   P0-D one wire
    │     grant drop only when cmd_empty && DMA IDLE && AR/R outstanding==0
    │     XSim · PROGRAM=NO · one unknown
    │
    └─ CLASS=DISCRIMINATOR_DEAD
          ▼
       [G1'] E2R-OWNER-AR-LEAVE-DIAG-00
          why DMA cannot leave AR even with raw arready
          do NOT C-FIX ready-gate from READY_GATED alone
    │
    ▼
[G2] E2R-OWNER-LEVEL-MGO-00            P0-C  (only if still needed after G1)
    level m_go × FIFO multiply · one unknown · PROGRAM=NO
    skip if one owned command already explains hang
    │
    ▼
[G3] E2R-OWNER-DIRT-FREEZE-00
    hash live rtl/ · STOP concurrent editors · human DECIDE
    │
    ▼
[G4] E2R-OWNER-FENCE-LIVE-00
    apply ONLY wires already UNIT_PASS on snap/composition
    issue m_owner · pop s_owner · ready-gate if CONTROL live
    + release quiesce if G1 PASS
    NOT the six-item list in one hunk unless DECIDE says combined confirmation
    │
    ▼
[G5] E2R-OWNER-FENCE-LIVE-XSIM-00
    composition + (if possible) integrated existence vehicle pred=664
    still PROGRAM=NO
    │
    ▼
W1 BOARD — Cursor only — needs NEW com12_authorized_gate
    │
[G6] impl: WNS>=0 TNS=0 · BRAM≤135 · new bit SHA archive
    FORBIDDEN bits: LONGBOOT 9DC0F8DF… · two-pass 15B0E502…
    │
[G7] arm COM12 → program NEW bit → UART
    PASS iff NATIVE_V1_EXIST_ROW,pred=664
    empty UART → recapture, not FAIL
    AI does not stamp PASS — human does
    │
    ▼
NATIVE_V1_EXISTENCE_BOARD_PASS (human)
    │
    ▼
W2  encoder Si → Kidi → A1 → scale → Mini-AI → GlassBox
    (see §6; do not pull left of this node)
```

---

## 4. Next three executable gates

These are the only gates that may start without a new human architecture decision. One unknown each. `PROGRAM=NO` until G6/G7.

### Gate A — `E2R-OWNER-READY-OPEN-CTRL-00`  **NOW**

| Field | Value |
|-------|-------|
| Owner | Cursor board-tree implementer `a7-ng-scientific` (already **DISPATCHED** 19:55:30). Grok-orch: **do not re-dispatch**. VERIFY_ONLY replica allowed on copies in this tree. |
| Board | **NO.** No JTAG. No COM12. |
| RTL | **NONE.** DUT = READY-SNAP-00 `snap/a7ng_wdma_cdc.sv` + `snap/ddr_tile_dma.sv`. Do not xvlog ready-gate slice. Do not xvlog live `rtl/`. |
| Unknown | After same park / drop / raise, with **raw** `arready` into DMA, does `DROP_AR_ADVANCE` fire? |
| H_CANDIDATE | `OWNED_AR=1` `DROP_AR_ADVANCE=1` → CLASS=`READY_OPEN` (discriminator live) |
| H_RIVAL | `DROP_AR_ADVANCE=0` → CLASS=`DISCRIMINATOR_DEAD` |
| Prereg | MAIN `STATUS/E2R_OWNER_READY_OPEN_CTRL_00_PREREG.md` (sealed 19:55) |
| PASS | SHA MATCH + TB finished. **Not** existence. **Not** a C-FIX license. **Not** a program license. |

Keep `go && wdma_owner_ui` so owned start still works. Label `$time` as **ps**.

### Gate B — branch after A (prereg **after** A's CLASS; do not start in parallel)

**If A = READY_OPEN → `E2R-OWNER-RELEASE-QUIESCE-00` (P0-D)**

| Field | Value |
|-------|-------|
| Owner | Cursor board XSim **or** Grok-orch XSim on copies. Parent orchestrator dispatches once. |
| Board | **NO.** |
| Unknown | Does AND of quiesce (`cmd_empty` && DMA IDLE && AR/R outstanding==0) on grant **drop** stop the READY-SNAP park (`DROP_ST=4` after owner drop) without starving a later owned start? |
| Why this next | READY-SNAP already left DMA in AR after drop. Ready-gate stopped AR→R. P0-D is that remaining hole. One wire. |
| Must not | Ready-gate re-edit; P0-C in the same hunk; live dirt; program. |

**If A = DISCRIMINATOR_DEAD → `E2R-OWNER-AR-LEAVE-DIAG-00`**

| Field | Value |
|-------|-------|
| Owner | same as B |
| Board | **NO.** |
| Unknown | Why DMA cannot leave AR even with ungated `arready` on this vehicle. |
| Must not | Treat READY_GATED as C-FIX license. Do not patch four fence items. |

**If A = INCONCLUSIVE** (`OWNED_AR=0`): stop. Fix the TB/vehicle. Do not classify P0-B.

### Gate C — `E2R-OWNER-DIRT-FREEZE-00` then licensed live apply

Start **only after** Gate B UNIT_PASS (or explicit skip of P0-C). Still `PROGRAM=NO`.

| Step | Owner | Action |
|------|-------|--------|
| C1 dirt freeze | Cursor board tree + Grok VERIFY hash | Re-hash live `rtl/`. STOP other editors. Record CONTROL SHA table. |
| C2 human DECIDE | Human | License **which** already-proven wires may enter live RTL. Not six items unless labeled combined confirmation. |
| C3 live apply | Cursor only (board `rtl/`) | One implementer. Grok proposes the patch text; does **not** merge into dirty tree. |
| C4 live XSim | Cursor or Grok-orch copies | Composition TB on **live** hashes, not only snap. Still not existence. |

P0-C `E2R-OWNER-LEVEL-MGO-00` is **optional** and **serial**: run before C3 only if Gate B did not already explain a single unowned/owned command hang. Do not fold C into C3.

After C4 PASS_NARROW: G6 impl + G7 board (new authorize). That is **not** in the next-three set because it needs a new `com12_authorized_gate`.

---

## 5. Grok-orch may / must-not **now**

### May (this tree, this session)

1. Keep this DAG; draft **Gate B** prereg **after** OPEN-CTRL CLASS (do not seal pass/fail before the unit).
2. Independent **VERIFY_ONLY** xvlog of sealed SNAP / OPEN-CTRL bags on **this** checkout (copy DUT, do not edit board `rtl/`).
3. Read MAIN `results/A7-EAM-03E` and write encoder **research notes** under `results/A7-NATIVE-GRAPH/GROK-ORCH-00/` — including that E1 ungated is already NO-GO.
4. Propose fence law text (issue / pop / ready / release) as a **patch draft**. Not a merge.
5. XSim two-pass / tile / owner-fence replicas on this checkout (`PROGRAM=NO`).

### Must not

- `open_hw_manager` / program / `REQUEST_COM12`
- Re-dispatch `E2R-OWNER-READY-OPEN-CTRL-00` (already has an implementer line)
- Merge into Cursor dirty `rtl/`
- Program leftover LONGBOOT `9DC0F8DF…498F951B` or two-pass `15B0E502…` as hang-fix
- Dual-read / pin-POS / `SIM_FULL=1` on silicon
- Task `graph_late_materialize_00`
- Edit frozen 01R / 02M / LM-06 / A0.3 artifacts
- Change `a7lm06_expected.txt` (744)
- Mix 744 into Native-V1 664 evidence
- Glue encoder to 01R/02M/LM-06
- Re-run ungated DIFF as if H5 were untested
- Tighten S2 clamp
- Stamp `BOARD_PASS` / existence PASS / Mini-AI PASS
- Start encoder silicon, Kidi, A1, 800k, GlassBox
- Four C-FIX in one gate
- Treat `UNIT_PASS` / `READY_GATED` / XSim `pred=664` as UART existence

---

## 6. After existence (W2) — do not pull left

Order is the roadmap. Encoder silicon waits for W1 even though twin research is allowed now.

```text
human EXISTENCE PASS
  → encoder freeze (stability + geometry on preregistered seeds; long horizon)
  → new encoder law_id + RTL + XSim exact + WNS/TNS + new bit + silicon
  → KIDI-20 (FPGA encode/learn/bind; host no cue/winner)
  → KIDI-40 teacher-off held-out
  → A1 glue 03E → 01R → 02M (do not retune frozen router to rescue encoder)
  → scale 20, 40, 256, 4096, 16384, 65536, 262144, 800000
  → LM-06 in FPGA output path (HS-22); host_next_token=0
  → teacher-off + reset/retrain
  → human NATIVE_V1_MINI_AI_BOARD_PASS
  → GlassBox observe-only (must not change the law)
```

Encoder note for Grok research (not a silicon gate): standing measured candidate is **triplet + S3 `>>3`**. Remaining scientific problem is **leaving the ~0.75 AUC peak**, not “cannot learn” and not “H5 gate is the bottleneck.” One unknown per later twin. No S2. No glue.

---

## 7. Forbidden actions (global)

| Ban | Why |
|-----|-----|
| Leftover LONGBOOT bit `9DC0F8DF…` as hang-fix | Authorize consumed; CLASS=`STILL_STALL`; no `pred` |
| Two-pass bit `15B0E502…` as hang-fix | Inventory; does **not** patch P0-A/B |
| `graph_late_materialize_00` as existence | DEFERRED under EXISTENCE BEFORE QUALITY |
| Invert encoder / Kidi / A1 / 800k / GlassBox before UART 664 | Charter + existence law |
| Mix LM-06 `pred=744` with Native-V1 `pred=664` | Different machines |
| Host gradient / update / next-token / CE / winner / address | HS-01 / HS-22 |
| Semantic ROM / teacher-on EVAL sold as Mini-AI | HS-02 / HS-03 |
| Overwrite frozen A0.3 / 01R / 02M / LM-06 bits | HS-20 |
| Hand-edit MIG `mig.prj` / native `app_*` | standing program lock |
| Two unknowns in one silicon gate | HS-25 |
| AI self-stamp BOARD_PASS | human only |
| Empty UART as design FAIL | recapture first |
| Dual-read, pin-POS, `SIM_FULL=1` on silicon | charter |
| Steal Cursor JTAG/COM12 from this tree | one board |

---

## 8. Ownership matrix (compressed)

| Phase | Cursor (board tree) | Grok-orch (this) | Human |
|-------|---------------------|------------------|-------|
| G0 OPEN-CTRL XSim | implementer (in flight) | no re-dispatch; VERIFY_ONLY | — |
| G1 P0-D or diag | implement **or** leave to Grok XSim | XSim on copies; draft prereg | — |
| G3 dirt freeze | stop editors; hash live | independent hash check | — |
| G4 live RTL | **only** writer | patch draft only | DECIDE which wires |
| G6 impl / G7 program | **only** programmer | PROGRAM=NO | new `com12_authorized_gate` |
| Stamp existence | evidence pack | report only | **stamp** |
| Encoder Si / Kidi / A1 | after W1 token | research notes now; Si after W1 | names W2 token |
| Mini-AI / GlassBox | after Mini-AI freeze | observe | stamp Mini-AI |

---

## 9. Evidence required for existence board pack (G7)

Not a substitute for `pred=664`. Required **with** it:

- New bitstream + SHA256 (not `9DC0F8DF`, not `15B0E502`)
- Git SHA + tool SHA + `COMMANDS.txt`
- Timing: core WNS≥0 TNS=0 on the **declared** clock (CLOCK80 / 12.5 MHz sealed for E1; do not lie 100 MHz)
- BRAM36 ≤ 135
- COM12 raw UART + text with `NATIVE_V1_EXIST_ROW,pred=664`
- `host_next_token=0` / teacher=0 / external_LLM=0 during response window
- Auditor + HLB on **that** bit
- JTAG id `210319BE776EA` matched

Stage A XSim 664 and two-pass XSim 664 stay in the archive as **XSim**. They do not close G7.

---

## 10. Stop lines

```text
EXISTENCE: NO until UART pred=664.
PROGRAM this tree: NO.
lock.owner: grok (mailbox). JTAG/COM12: Cursor until existence.
Next executable: E2R-OWNER-READY-OPEN-CTRL-00 (do not re-dispatch).
Then: P0-D release-quiesce XOR AR-leave diagnostic, not both, not with P0-C.
Then: dirt freeze + human DECIDE + live apply of proven wires.
Then: new bit + new authorize + arm COM12 + program.
graph_late_materialize_00: DEFERRED.
Encoder/Kidi/A1/800k/GlassBox: after existence.
```

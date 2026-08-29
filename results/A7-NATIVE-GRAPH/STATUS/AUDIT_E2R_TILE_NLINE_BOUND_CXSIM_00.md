# AUDIT — E2R-TILE-NLINE-BOUND-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28T14:24:00+07:00  
**Gate:** `E2R-TILE-NLINE-BOUND-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** board `results/A7-NATIVE-GRAPH/E2R-TILE-NLINE-BOUND-CXSIM-00/CLOSEOUT.md`  
**Dispatch:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_NLINE_BOUND_CXSIM_DISPATCH.md`  
**Implementer Task:** `a7-ng-xsim-verify` `8276b8cf-e79d-498d-b46e-9b0afd494f4b` (not parent RTL)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=REGION_DONE: stall=0 ∧ dest4_cnt == nline == 128 (POS hold_rg=1)
H_CANDIDATE STALL_HOLD: falsified on this tile+completable-stub only
dest4_cnt=128  nline=128  stall_end=0  stall0_cyc=36610
C_FIX: NONE
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
SILICON ATOM1 dest=5 + LONG SILENT: not closed
```

XSim PASS / `CLASS=REGION_DONE` / `C_FIX=NONE` is file-backed. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR. Forbidden PASS routes not taken. Measured nline=128 (POS `hold_rg=1`) is a class input, not a FAIL: dest4_cnt == nline == 128. Silicon ATOM1 dest=5 + LONG listen SILENT remains open.

`VERDICT: PASS_NARROW` because the claim is XSim tile+completable-stub one-region refill only (n=1 UNIT). Same-clk DMA, no MIG, no WDMA CDC, no leftover grant.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` (not the closeout table). Re-hash of `xsim.log` matches the claimed SHA.

| Metric | Raw log | Closeout | Class |
|--------|---------|----------|-------|
| Vehicle | `VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB_EVERY_GO` | tile-only completable stub | EVIDENCE (XSim) |
| Elab | `weight_tile803k(SIM_FULL=1'b0)` | `SIM_FULL=0` | EVIDENCE |
| nline law | `RG_NLINE_LAW POS_rg1=128 else=1024` | POS→128 else 1024 | EVIDENCE |
| First go | `SNAP_GO_BURST cyc=7 burst=1 … nline_h=128 hold_rg=1 dest4=0` | first burst | EVIDENCE |
| dest4_1 | `SNAP_D4_1 cyc=18 dest=4 … dest4=1 nline_h=128 hold_rg=1` | first dest=4 | EVIDENCE |
| dest4_2 CONTROL | `SNAP_D4_2 cyc=304 dest=4 … dest4=2 … CONTROL_CHUNK2` stall=1 | CHUNK2_GO exact | EVIDENCE |
| dest4=32/64/96 | `cyc=8884/18036/27188 dest4=32/64/96 stall=1` | mid-refill stall=1 | EVIDENCE |
| dest4=128 | `SNAP_D4 cyc=36340 dest4=128 dest=4 bst=4 stall=1 … ch=127 burst=128` | last chunk | EVIDENCE |
| stall=0 | `SNAP_STALL0 cyc=36610 dest=0 bst=0 dest4=128 burst=128 nline_h=128 nline_meas=128 hold_rg=1 cur_rg=1` | stall0_cyc=36610 | EVIDENCE |
| CLASS | `CLASS=REGION_DONE` | REGION_DONE | EVIDENCE |
| Counts | `DEST4_CNT=128 DMA_GO_BURST=128 DMA_GO_CYC=384 STALL0_CYC=36610 STALL_END=0 BST_END=0` | same | EVIDENCE |
| nline | `NLINE_MEAS=128 NLINE_H=128 NLINE_LAW_HOLD=128 HOLD_RG=1 CUR_RG=1` | measured 128 POS | EVIDENCE |
| Marker | `E2R_TILE_NLINE_BOUND_CXSIM_00_XSIM_PASS class=REGION_DONE … dest4_cnt=128 … nline=128 stall_end=0 stall0_cyc=36610` | same | EVIDENCE |
| C_FIX / PROGRAM / claims | `C_FIX=NONE` `PROGRAM=NO` `BOARD_PASS=not_claimed` `EXISTENCE=not_claimed` | NONE / NO / not claimed | EVIDENCE |
| Timeout | `TIMEOUT_CAP=1000000` unused; `$finish` 366215 ns / cyc=36610 | unused | EVIDENCE |

TB class law (`tb_e2r_tile_nline_bound_cxsim_00.sv`): on first `stall==0` with `dest4_cnt>0`, emit `REGION_DONE` iff `dest4_cnt == nline_meas`, else `EARLY_IDLE`. Timeout → `STALL_HOLD` (or `ACK_HOLD` if dest stays 5). Does not stop at dest4_2. Matches the log.

Independent dest4 cadence (not trusting the last-line counter alone): dest4=1 at 18, dest4=2 at 304 (Δ=286). Then dest4=32/64/96/128 at 8884/18036/27188/36340. Each +32 dest4 steps is +9152 dest-clk = 32×286. Last dest4 at 36340 = 18 + 127×286. dest4_cnt=128 is reconstructible from the snap grid.

nline=128 is measured: every snap prints `nline_h=128 hold_rg=1`. RTL `rg_nline(rg==1)→128`. `OFF_POS=131072`; `rg_of(OFF_POS)` is POS (1) because `OFF_POS ≤ a < OFF_L0`. Dispatch expected 1024 unless measured; this run measured POS. dest4_cnt==nline==128 → not a FAIL.

`DMA_GO_CYC=384` = 128 bursts × 3 dest-clk. Rising dest==4 count = burst count = measured nline.

n = 1 tile miss, one POS region. Not a cycle farm. No inferential test.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `29285B79C56965FE0AC3CE9681C622081D323CDF42DCBB33146BF0E23143EA49` | **match** (4012 bytes) |
| TB (`tests/xsim` and archive copy) | `EAD56CE37FAA03EF777171722F869295E50E8193AF3C3F448A0B3E953883090B` | **match** (identical) |
| `rtl/lm/weight_tile803k.sv` (board) | `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` | **match** (same as CHUNK2_GO bag; last git write 2026-08-27; not dirty) |

`xsim_stdout.txt` transcript body agrees with `xsim.log` (same SNAP/CLASS/marker lines).

---

## Adversarial checks (requested)

| Check | Result |
|-------|--------|
| CLASS=`REGION_DONE` on tile-only completable stub | **PASS.** `stall=0` at dest-clk 36610 and dest4_cnt==nline==128. |
| dest4_cnt / nline / stall=0 from raw log | **128 / 128 / stall_end=0 at 36610.** Cadence 286 dest-clk/dest4 reconstructs dest4=128 at 36340. |
| nline=128 vs dispatch default 1024 | **Not a FAIL.** Measured POS `hold_rg=1`. dest4_cnt==nline==128. |
| H_CANDIDATE `STALL_HOLD` (timeout still stall=1) | **Falsified on this vehicle.** Timeout unused. |
| XSim ≠ board; silicon ATOM1 dest=5 + LONG SILENT not closed | **Held.** Closeout: does not prove silicon finishes a region or emits `CORE_DONE`. |
| Silicon time nline×MIG ms | **ENGINEERING_INFERENCE only.** Closeout / PREREGISTER label it; not sold as EVIDENCE. |
| Existence / BOARD_PASS | **not claimed.** `pred=664` absent. |
| No C-FIX / program / RTL edit | **Held.** Log `C_FIX=NONE` `PROGRAM=NO`. Tile SHA unchanged vs CHUNK2_GO. New files are TB/tcl/archive only. `sources.f` has no `soc_top`. |

Main-tree `weight_tile803k.sv` SHA `C7BEB34C…` is a different tree; this UNIT compiled the board file.

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| dest4_cnt=128, nline=128, stall=0 at dest-clk 36610 on this stub | EVIDENCE (XSim) |
| `STALL_HOLD` falsified on this vehicle | EVIDENCE (XSim) |
| XSim ≠ board; same-clk stub ≠ MIG / WDMA CDC | declared; held |
| silicon finishes a region / emits `CORE_DONE` / `pred=664` | **not claimed**; stays NEEDS_EXPERIMENT |
| silicon ATOM1 dest=5 + LONG SILENT | **not claimed**; LONG listen still SILENT |
| wall-clock refill = nline × assumed MIG ms/chunk | ENGINEERING_INFERENCE (stub ≠ MIG) |

No averaging of XSim with board. Marker is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen |
| Test deleted / skipped / nline forced to 1024 | not seen; nline taken from `nline_h` / `hold_rg` |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path |
| Hold-busy after first done | not used; stub returns `ST_IDLE` after every go |
| Stop at dest4_2 | not used; watch to stall=0 or 1e6 |
| `SIM_FULL=1` (stall hardcoded 0) | xelab `SIM_FULL=1'b0`; mid-refill stall printed 1 |
| Leftover grant bags / `soc_top` / MIG | not in `sources.f` |
| C-FIX / force dest or bst | hierarchical observe only (`dut.TILE.dst/bst/nline_h/hold_rg/ch`) |
| Product RTL this gate | tile SHA unchanged vs 2026-08-27 CHUNK2_GO bag |
| Board / bitstream / JTAG | no `vivado.exe` impl; xsim 14:17:04–14:17:07 |
| `BOARD_PASS` / existence PASS | explicitly not claimed |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last implementer line (255): `gate=E2R-TILE-NLINE-BOUND-CXSIM-00` `agent=a7-ng-xsim-verify` `result=PASS_NARROW` `class=REGION_DONE` `sha256=29285B79…` `existence=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

`lock.owner=grok` unchanged. No RTL. No program. No C-FIX.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=REGION_DONE` file-backed stall=0 ∧ dest4_cnt==nline? | **Yes.** dest4_cnt=128 nline=128 stall_end=0 at 36610. |
| nline=128 vs expected 1024 a FAIL? | **No.** Measured POS `hold_rg=1`. |
| `STALL_HOLD` falsified only on this stub? | **Yes.** |
| Silicon ATOM1 dest=5 + LONG SILENT closed? | **No.** |
| Silicon time nline×MIG as EVIDENCE? | **No.** ENGINEERING_INFERENCE. |
| `C_FIX=NONE` / PROGRAM=NO / RTL unedited? | **Yes.** |
| `xsim.log` SHA match? | **Yes.** `29285B79C56965FE0AC3CE9681C622081D323CDF42DCBB33146BF0E23143EA49` |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |

---

## Parent dispatch

Parent **may** dispatch the next **no-board** existence side-lane (PROGRAM=NO; not `graph_late_materialize_00`). This PASS_NARROW does **not** authorize program, C-FIX, or a silicon close of ATOM1 dest=5 + LONG SILENT.

---

## NOT VERIFIED

- Board UART recapture after this XSim (none claimed; COM12 not used).
- Silicon live dest after first ACK / whether a region finishes on MIG (ATOM1 dest=5 + LONG SILENT remain the silicon unknown).
- Whether CDC / mux / MIG R / core explain the 300 s hang (out of this UNIT).
- Per-cycle dest==4 rising-edge dump of all 128 events (log prints 1, 2, then every 32 plus last; cadence 286 reconstructs 128).
- `xvlog.log` / `xelab.log` scanned for `ERROR` / `CRITICAL WARNING` (none). Full warning catalogs not re-read line-by-line.
- Main-tree dirty SOA RTL / untracked integrate files are pre-existing and outside this gate.
- Parent Task id `8276b8cf-e79d-498d-b46e-9b0afd494f4b` accepted as stated; transcript not re-opened here.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell silicon dest=5 + SILENT as `STALL_HOLD` closed. Do not convert nline×MIG ms into a board time bound. Next silicon unknown stays ATOM1 dest=5 ∧ no `CORE_DONE` / `pred=664`, not this stub.

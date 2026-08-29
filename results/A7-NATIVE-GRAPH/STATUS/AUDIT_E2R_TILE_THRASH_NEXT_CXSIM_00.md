# AUDIT — E2R-TILE-THRASH-NEXT-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-29T14:03:00+07:00  
**Gate:** `E2R-TILE-THRASH-NEXT-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** board `results/A7-NATIVE-GRAPH/E2R-TILE-THRASH-NEXT-CXSIM-00/CLOSEOUT.md`  
**Dispatch:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_THRASH_NEXT_CXSIM_DISPATCH.md`  
**Implementer Task:** `a7-ng-xsim-verify` `4f882908-ac36-4674-973b-12a236d0292e` (not parent RTL)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=THRASH_NEXT: dest=4 after POS stall=0 TOK switch
dest4 128→129  dest4_after_switch=1  dest4_post_cyc=36628
CONTROL stall=0 dest4=128 cur_rg=1 at 36610 (NLINE-BOUND match)
H_RIVAL HIT_HOLD: falsified on this tile+completable-stub only
C_FIX: NONE
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
1.18e6 DMA: ENGINEERING_INFERENCE (n=1)
```

XSim PASS / `CLASS=THRASH_NEXT` / `C_FIX=NONE` is file-backed on `weight_tile803k #(.SIM_FULL(0))` tile+completable-stub only. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, **not** silicon thrash for ~1.18e6 DMA, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR. Forbidden PASS routes not taken. `HIT_HOLD` (stall stays 0; no second dest=4) is falsified on this vehicle: dest=4 at dest-clk 36628, dest4_cnt 128→129. Silicon ~1.18e6 DMA remains ENGINEERING_INFERENCE (n=1 switch on stub).

`SNAP_SWITCH_TOK` miss=0 at cyc=36610 is same-cycle TB sample (`addr_a` and `dbg_miss` in one blocking slot). `SNAP_GO_BURST` at 36617 prints miss=1. Classification uses dest=4 after switch, not that same-cycle miss. **Not a second unknown. Not a FAIL.**

`VERDICT: PASS_NARROW` because the claim is XSim tile+completable-stub POS-then-TOK miss only (n=1 UNIT). Same-clk DMA, no MIG, no WDMA CDC, no leftover grant. Stub ≠ board.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` (not the closeout table). Re-hash of `xsim.log` matches the claimed SHA.

| Metric | Raw log | Closeout | Class |
|--------|---------|----------|-------|
| Vehicle | `VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB_EVERY_GO` | tile-only completable stub | EVIDENCE (XSim) |
| Elab | `weight_tile803k(SIM_FULL=1'b0)` | `SIM_FULL=0` | EVIDENCE |
| nline law | `RG_NLINE_LAW POS_rg1=128 else=1024` | POS→128 else 1024 | EVIDENCE |
| First go | `SNAP_GO_BURST cyc=7 burst=1 … nline_h=128 hold_rg=1 dest4=0 switched=0` | first burst | EVIDENCE |
| dest4_1 | `SNAP_D4_1 cyc=18 dest=4 … dest4=1 nline_h=128 hold_rg=1` | first dest=4 | EVIDENCE |
| dest4_2 CONTROL | `SNAP_D4_2 cyc=304 dest=4 … dest4=2 … CONTROL_CHUNK2` stall=1 | CHUNK2_GO exact | EVIDENCE |
| dest4=32/64/96 | `cyc=8884/18036/27188 dest4=32/64/96 stall=1` | mid-refill stall=1 | EVIDENCE |
| dest4=128 | `SNAP_D4 cyc=36340 dest4=128 dest=4 bst=4 stall=1 … ch=127 burst=128 switched=0` | last POS chunk | EVIDENCE |
| stall=0 before switch | `SNAP_STALL0_BEFORE_SWITCH cyc=36610 dest=0 bst=0 dest4=128 burst=128 nline_h=128 nline_meas=128 hold_rg=1 cur_rg=1 miss=0 stall=0 addr_a=131072` | CONTROL REGION_DONE | EVIDENCE |
| TOK switch | `SNAP_SWITCH_TOK cyc=36610 addr_a=0 OFF_TOK=0 dest4=128 cur_rg=1 miss=0 stall=0 dest=0` | same-cycle miss=0 sample | EVIDENCE |
| first go after switch | `SNAP_GO_BURST cyc=36617 burst=129 dest=1 … stall=1 nline_h=1024 hold_rg=0 cur_rg=1 miss=1 dest4=128 switched=1` | new dma_go | EVIDENCE |
| dest=4 after switch | `SNAP_D4_AFTER_SWITCH cyc=36628 dest=4 bst=4 stall=1 dest4=129 dest4_after=1 nline_h=1024 hold_rg=0 cur_rg=1 miss=1 burst=129` | dest4_after_switch=1 | EVIDENCE |
| CLASS | `CLASS=THRASH_NEXT` | THRASH_NEXT | EVIDENCE |
| Counts | `DEST4_CNT=129 DEST4_AT_SWITCH=128 DEST4_AFTER_SWITCH=1 DMA_GO_BURST=129 DMA_GO_CYC=387` | same | EVIDENCE |
| Cycles | `STALL0_CYC=36610 SWITCH_CYC=36610 DEST4_POST_CYC=36628 STALL_END=1 BST_END=4` | same | EVIDENCE |
| Marker | `E2R_TILE_THRASH_NEXT_CXSIM_00_XSIM_PASS class=THRASH_NEXT … dest4_cnt=129 dest4_after_switch=1 … dest4_post_cyc=36628` | same | EVIDENCE |
| C_FIX / PROGRAM / claims | `C_FIX=NONE` `PROGRAM=NO` `BOARD_PASS=not_claimed` `EXISTENCE=not_claimed` | NONE / NO / not claimed | EVIDENCE |
| Timeout | `TIMEOUT_AFTER=500000` unused; `$finish` 366395 ns / dest4_post_cyc=36628 | unused | EVIDENCE |

TB class law (`tb_e2r_tile_thrash_next_cxsim_00.sv`): after first `stall==0`, set `addr_a=OFF_TOK`. Emit `THRASH_NEXT` on first dest=4 after switch. Timeout-after → `HIT_HOLD` (or `ACK_HOLD` if dest stays 5). Does not require TOK region to finish. Matches the log.

Independent dest4 cadence (not trusting the last-line counter alone): dest4=1 at 18, dest4=2 at 304 (Δ=286). dest4=32/64/96/128 at 8884/18036/27188/36340. Each +32 dest4 steps is +9152 dest-clk = 32×286. Last POS dest4 at 36340 = 18 + 127×286. dest4_cnt=128 at CONTROL is reconstructible from the snap grid (same as NLINE-BOUND).

After switch: dest4_at_switch=128 (snap + summary). Next dest=4 increments dest4_cnt to **129**. `dest4_after_switch = 129 − 128 = 1`. `dest4_post_cyc=36628` is the cycle of that rising dest=4. Δ from switch = 36628 − 36610 = **18** dest-clk.

CONTROL match vs NLINE-BOUND bag: dest4=128 stall=0 at cyc=36610, dest4_2 at 304, dest4=128 at 36340 — identical until the TOK switch. `DMA_GO_CYC=387` = prior 384 + 3 dest-clk of the first TOK `dma_go` pulse.

n = 1 POS refill then 1 TOK address. Descriptive class only. Not a cycle farm. No inferential test.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `7222BDAF8137D7BA3AB9AFE17203C955B6B3F11286982680E857EAD54A075924` | **match** (4947 bytes) |
| TB (`tests/xsim` and archive copy) | `D4ED74316CB1633D347BC9E549253439855EF1D4FD5CC5969D9DD7B32AA491F4` | **match** (identical) |
| TCL (`tests/xsim` and archive copy) | — | `B0E48C65BA9CA4FBA2A26DD13A6ED1306A21B3ECDD0BBEACE425F088BD1A6133` (identical) |
| `rtl/lm/weight_tile803k.sv` (board) | `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` | **match** (same as NLINE-BOUND bag; last git write 2026-08-27; not dirty) |

`xsim_stdout.txt` transcript body agrees with `xsim.log` (same SNAP / CLASS / marker lines). `$finish` path is `tests/xsim/tb_e2r_tile_thrash_next_cxsim_00.sv` line 205.

---

## Adversarial checks (requested)

| Check | Result |
|-------|--------|
| CLASS=`THRASH_NEXT` after POS stall=0 dest4=128 cur_rg=1 | **PASS.** dest=4 at 36628; dest4_after_switch=1. |
| dest4 128→129 and dest4_post_cyc from raw log | **129 / 36628.** 129−128=1. |
| SNAP_SWITCH miss=0 vs miss=1 at 36617 | **Not a FAIL.** Same-cycle sample; class uses dest=4 after switch. |
| H_RIVAL `HIT_HOLD` | **Falsified on this stub only.** Timeout unused. |
| XSim ≠ board; 1.18e6 DMA | **Held.** Closeout labels ENGINEERING_INFERENCE (n=1). |
| Existence / BOARD_PASS | **not claimed.** `pred=664` absent. |
| No C-FIX / program / product RTL | **Held.** Log `C_FIX=NONE` `PROGRAM=NO`. Tile SHA unchanged vs NLINE-BOUND. New files are TB/tcl/archive only. `sources.f` has no `soc_top`. |
| LOOP_STATE.next = `graph_late_materialize_00` | **Not a FAIL.** Existence side-lane exemption. |

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| dest4_cnt 128→129, dest4_after_switch=1, dest4_post_cyc=36628 on this stub | EVIDENCE (XSim) |
| `HIT_HOLD` falsified on this vehicle | EVIDENCE (XSim) |
| XSim ≠ board; same-clk stub ≠ MIG / WDMA CDC | declared; held |
| silicon thrashes for ~1.18e6 DMA beats | ENGINEERING_INFERENCE (n=1 switch; stub ≠ MIG) |
| UART emits `pred=664` / existence | **not claimed**; stays NEEDS_EXPERIMENT |
| `BOARD_PASS` | **not claimed** |

No averaging of XSim with board. Marker is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen |
| Test deleted / skipped / dest4 forced | not seen; dest4 counted on rising dest==4 |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path |
| Hold-busy after first done | not used; stub returns `ST_IDLE` after every go |
| Switch before first `stall=0` | stall0 and switch both cyc=36610 after dest4=128 |
| `SIM_FULL=1` | xelab `SIM_FULL=1'b0`; mid-refill stall printed 1 |
| Leftover grant bags / `soc_top` / MIG | not in `sources.f` |
| C-FIX / force dest or bst | hierarchical observe only (`dut.TILE.dst/bst/nline_h/hold_rg/ch`) |
| Product RTL this gate | tile SHA unchanged vs 2026-08-27 NLINE-BOUND bag |
| Board / bitstream / JTAG | no `vivado.exe` impl; xsim 13:57:38–13:57:41 |
| `BOARD_PASS` / existence PASS | explicitly not claimed |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |
| SNAP_SWITCH miss=0 sold as HIT_HOLD | not sold; closeout classifies from dest=4 after switch |

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last implementer line (270): `gate=E2R-TILE-THRASH-NEXT-CXSIM-00` `agent=a7-ng-xsim-verify` `result=PASS_NARROW` `class=THRASH_NEXT` `sha256=7222BDAF…` `existence=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

`lock.owner=grok` unchanged. No RTL. No program. No C-FIX.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=THRASH_NEXT` file-backed dest=4 after switch? | **Yes.** dest4_after_switch=1 at 36628. |
| dest4 128→129 / dest4_post_cyc re-derived? | **Yes.** 129 and 36628 from raw snaps. |
| SNAP_SWITCH miss=0 a FAIL / second unknown? | **No.** Same-cycle sample; miss=1 at 36617. |
| `HIT_HOLD` falsified only on this stub? | **Yes.** |
| 1.18e6 DMA as EVIDENCE? | **No.** ENGINEERING_INFERENCE. |
| `C_FIX=NONE` / PROGRAM=NO / product RTL unedited? | **Yes.** |
| `xsim.log` SHA match? | **Yes.** `7222BDAF8137D7BA3AB9AFE17203C955B6B3F11286982680E857EAD54A075924` |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |

---

## Parent dispatch

Parent **may** dispatch the next **no-board** existence side-lane (PROGRAM=NO; not `graph_late_materialize_00`). This PASS_NARROW does **not** authorize program, C-FIX, or a silicon close of ~1.18e6 DMA / UART `pred=664`.

---

## NOT VERIFIED

- Board UART recapture after this XSim (none claimed; COM12 not used).
- Silicon TOK/POS refill under MIG / WDMA CDC (stub ≠ MIG; same-clk DMA).
- Whether 1024 TOK chunks × assumed MIG ms/chunk maps to wall time (ENGINEERING_INFERENCE; n=1).
- Per-cycle dest==4 rising-edge dump of all 129 events (log prints 1, 2, every 32, last POS, then first after switch; cadence 286 reconstructs POS 128).
- `xvlog.log` / `xelab.log` scanned for `ERROR` / `CRITICAL WARNING` (none). Full warning catalogs not re-read line-by-line.
- Board-tree dirty `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` is pre-existing E2R ladder work and is **not** in this gate `sources.f`.
- Main-tree dirty SOA RTL / untracked integrate files are pre-existing and outside this gate.
- Parent Task id `4f882908-ac36-4674-973b-12a236d0292e` accepted as stated; transcript not re-opened here.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell ~1.18e6 DMA as EVIDENCE. Do not open a second unknown on SNAP_SWITCH miss=0. Next existence unknown stays UART `pred=664`, not this stub.

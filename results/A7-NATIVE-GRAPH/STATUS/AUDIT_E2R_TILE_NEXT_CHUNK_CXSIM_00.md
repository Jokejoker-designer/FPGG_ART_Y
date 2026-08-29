# AUDIT — E2R-TILE-NEXT-CHUNK-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28T14:09:00+07:00  
**Gate:** `E2R-TILE-NEXT-CHUNK-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** board `results/A7-NATIVE-GRAPH/E2R-TILE-NEXT-CHUNK-CXSIM-00/CLOSEOUT.md`  
**STATUS seal:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_NEXT_CHUNK_CXSIM_CLOSEOUT.md`  
**Dispatch:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_NEXT_CHUNK_CXSIM_DISPATCH.md`  
**Implementer Task:** `a7-ng-xsim-verify` `134bd536-47ca-4298-a206-790edddcbc2b` (not parent RTL)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=CHUNK2_GO: file-backed dest=0 after first ACK ∧ second dest=4
H_CANDIDATE ACK_HOLD: falsified on this tile+completable-stub only
C_FIX: NONE
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
SILICON ATOM1 dest=5 + LONG SILENT: not closed
```

XSim PASS / `CLASS=CHUNK2_GO` / `C_FIX=NONE` is file-backed. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR. Forbidden PASS routes not taken. CHUNK2_GO uses dest-after-ACK=0 and second dest=4 only. Silicon ATOM1 dest=5 + LONG listen SILENT remains open.

`VERDICT: PASS_NARROW` because the claim is XSim tile+completable-stub chunk-2 start only (n=1 UNIT). Same-clk DMA, no MIG, no WDMA CDC, no leftover grant.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` (not the closeout table). Re-hash of `xsim.log` matches the claimed SHA.

| Metric | Raw log | Closeout / STATUS | Class |
|--------|---------|-------------------|-------|
| Vehicle | `VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB_EVERY_GO` | tile-only completable stub | EVIDENCE (XSim) |
| Elab | `weight_tile803k(SIM_FULL=1'b0)` | `SIM_FULL=0` | EVIDENCE |
| SNAP_D4_1 | `cyc=18 dest=4 dbg_dst=3 bst=4 stall=1 … go_n=3` | first dest=4 | EVIDENCE |
| SNAP_D5_1 | `cyc=20 dest=5 dbg_dst=4 bst=4 stall=1 … go_n=3` | first dest=5 | EVIDENCE |
| SNAP_IDLE | `cyc=28 dest=0 dbg_dst=5 bst=5 stall=1 req=0 go_n=3` | dest=0 after first ACK; `bst=B_WAITACK` | EVIDENCE |
| SNAP_GO chunk2 | `cyc=293 go_n=4 dest=1 … busy=0` then `294–295` | second `dma_go` burst | EVIDENCE |
| SNAP_D4_2 | `cyc=304 dest=4 dbg_dst=3 bst=4 stall=1 … go_n=6` | second dest=4 | EVIDENCE |
| CLASS | `CLASS=CHUNK2_GO` | CHUNK2_GO | EVIDENCE |
| Marker | `E2R_TILE_NEXT_CHUNK_CXSIM_00_XSIM_PASS class=CHUNK2_GO … dest5=1 dest0=1 dest4_2=1 dma_go_cnt=6 … stall_d4_2=1` | same | EVIDENCE |
| C_FIX | `C_FIX=NONE` | NONE | EVIDENCE |
| BOARD_PASS | `BOARD_PASS=not_claimed` | not claimed | EVIDENCE |
| EXISTENCE | `EXISTENCE=not_claimed` | not claimed | EVIDENCE |
| PROGRAM | `PROGRAM=NO` | NO | EVIDENCE |
| Timeout | `TIMEOUT_CAP=20000` unused; `$finish` 3155 ns / cyc=304 | unused | EVIDENCE |

TB class law (`tb_e2r_tile_next_chunk_cxsim_00.sv`): after `saw_d5_1`, `dest_live==D_IDLE` then `dest_live==D_WAITDONE` → `CHUNK2_GO`. No `stall==0` conjunct. Matches the log.

Marker field `dest_after_ack=4` / `bst_after_ack=4` is dest/bst **at classify** (second `D_WAITDONE`), not dest immediately after first ACK. Dest after first ACK is SNAP_IDLE dest=0 bst=5. Closeout discloses this. CLASS does not depend on that field name.

`dma_go_cnt=6` is dest-clk with `dma_go=1`, not six isolated pulses. Two bursts: cyc 7–9 and cyc 293–295.

n = 1 tile miss, chunk1 then chunk2. Not a cycle farm.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `6D371C0377FB335D391B5F4D0ADB8E19E797B39960D5DCBE48FF619985684D9F` | **match** (2992 bytes) |
| TB (`tests/xsim` and archive copy) | `A96218DA3C30B95CDCF9D6E1D2C8F40081016D6A11A93D2B36C5AB86C56190D8` | **match** (identical) |
| `rtl/lm/weight_tile803k.sv` | `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` | **match** (same as CHUNK_ACK bag; last git write 2026-08-27; not dirty) |

`xsim_stdout.txt` transcript body agrees with `xsim.log` (same SNAP/CLASS/marker lines).

---

## Adversarial checks (requested)

| Check | Result |
|-------|--------|
| CHUNK2_GO only if dest=0 after first ACK **and** second dest=4 | **PASS.** SNAP_IDLE dest=0 cyc=28; SNAP_D4_2 dest=4 cyc=304. |
| H_CANDIDATE `ACK_HOLD` (dest stays 5; no second go) | **Falsified on this vehicle.** Dest left 5; second `dma_go` burst at cyc=293. |
| Fail if they required stall=0 | **Not required.** `stall_d4_2=1`. Dispatch: do not require `stall=0`. |
| XSim ≠ board; silicon ATOM1 dest=5 + LONG SILENT not closed | **Held.** Closeout: does not prove silicon starts chunk 2. LONG listen SILENT stays sealed. |
| `ACK_HOLD` falsified only on this stub | **Held.** Closeout / STATUS: “on this tile+stub”. Silicon hang remains a different unknown. |
| No C-FIX / program / RTL edit | **Held.** Log `C_FIX=NONE` `PROGRAM=NO`. `weight_tile803k.sv` SHA unchanged vs CHUNK_ACK. New files are TB/tcl/archive only. `sources.f` has no `soc_top`. |
| Re-hash `xsim.log` | **match** `6D371C0377FB335D391B5F4D0ADB8E19E797B39960D5DCBE48FF619985684D9F` |

Dirty board `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` is pre-existing and **not** in this compile list. Main-tree `weight_tile803k.sv` SHA `C7BEB34C…` is a different tree; this UNIT compiled the board file.

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| dest 5→0 (cyc=28, bst=5) then second dest=4 (cyc=304) on this stub | EVIDENCE (XSim) |
| `ACK_HOLD` falsified on this vehicle | EVIDENCE (XSim) |
| XSim ≠ board; same-clk stub ≠ MIG / WDMA CDC | declared; held |
| silicon dest left 5 / started chunk 2 | **not claimed**; stays NEEDS_EXPERIMENT |
| silicon ATOM1 dest=5 + LONG SILENT / no `pred=664` | **not claimed**; LONG listen still SILENT |
| ~273 dest-clk gap = refill law (`B_STORE`/`B_SWAIT`) | ENGINEERING_INFERENCE (XSim bst path; not silicon) |

No averaging of XSim with board. Marker is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen |
| Test deleted / skipped / stall=0 required | not seen; `ACK_HOLD` / `IDLE_NO_GO` / `NO_ACK` still legal |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path |
| Hold-busy after first done | not used; stub returns `ST_IDLE` after every go |
| Stop at first dest=5 | not used; watch past dest=5 |
| `SIM_FULL=1` (stall hardcoded 0) | xelab `SIM_FULL=1'b0`; stall printed 1 |
| Leftover grant bags / `soc_top` / MIG | not in `sources.f` |
| C-FIX / force dest or bst | hierarchical observe only (`dut.TILE.dst/bst/ack`) |
| Product RTL this gate | tile SHA unchanged vs 2026-08-27 CHUNK_ACK bag |
| Board / bitstream / JTAG | no `vivado.exe` impl; xsim 14:02:01–14:02:04 |
| `BOARD_PASS` / existence PASS | explicitly not claimed |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last implementer line (252): `gate=E2R-TILE-NEXT-CHUNK-CXSIM-00` `agent=a7-ng-xsim-verify` `result=PASS_NARROW` `class=CHUNK2_GO` `sha256=6D371C03…` `existence=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

`lock.owner=grok` unchanged. No RTL. No program. No C-FIX.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=CHUNK2_GO` file-backed dest=0 after ACK ∧ second dest=4? | **Yes.** cyc=28 dest=0; cyc=304 dest=4. |
| stall=0 required? | **No.** `stall_d4_2=1`. |
| `ACK_HOLD` falsified only on this stub? | **Yes.** |
| Silicon ATOM1 dest=5 + LONG SILENT closed? | **No.** |
| `C_FIX=NONE` / PROGRAM=NO / RTL unedited? | **Yes.** |
| `xsim.log` SHA match? | **Yes.** `6D371C0377FB335D391B5F4D0ADB8E19E797B39960D5DCBE48FF619985684D9F` |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |

---

## Parent dispatch

Parent **may** dispatch the next **no-board** existence side-lane (PROGRAM=NO; not `graph_late_materialize_00`). This PASS_NARROW does **not** authorize program, C-FIX, or a silicon close of ATOM1 dest=5 + LONG SILENT.

---

## NOT VERIFIED

- Board UART recapture after this XSim (none claimed; COM12 not used).
- Silicon live dest after first ACK (ATOM1 dest=5 + LONG SILENT remain the silicon unknown).
- Whether CDC / mux / MIG R / core explain the 300 s hang (out of this UNIT).
- `xvlog.log` / `xelab.log` scanned for `ERROR` / `CRITICAL WARNING` (none). Full warning catalogs not re-read line-by-line.
- Main-tree dirty SOA RTL / untracked integrate files are pre-existing and outside this gate.
- Parent Task id `134bd536-47ca-4298-a206-790edddcbc2b` accepted as stated; transcript not re-opened here.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell silicon dest=5 + SILENT as `ACK_HOLD` closed. Next silicon unknown stays ATOM1 dest=5 ∧ no `CORE_DONE` / `pred=664`, not this stub.

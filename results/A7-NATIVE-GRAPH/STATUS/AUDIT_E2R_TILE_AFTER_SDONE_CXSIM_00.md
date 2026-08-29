# AUDIT — E2R-TILE-AFTER-SDONE-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28  
**Gate:** `E2R-TILE-AFTER-SDONE-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** board `results/A7-NATIVE-GRAPH/E2R-TILE-AFTER-SDONE-CXSIM-00/CLOSEOUT.md`  
**STATUS seal:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_AFTER_SDONE_CXSIM_CLOSEOUT.md`  
**Dispatch:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_AFTER_SDONE_CXSIM_DISPATCH.md`  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=CHUNK_ACK: file-backed dest=5 ∧ bst=5 (B_WAITACK)
stall_after=1: not treated as stuck; stall=0 not required
H_CANDIDATE ACK_STUCK: falsified on this tile+completable-stub only
C_FIX: NONE
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
SILICON STILL_STALL: not closed
```

XSim PASS / `CLASS=CHUNK_ACK` / `C_FIX=NONE` is file-backed. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR. Forbidden PASS routes not taken. CHUNK_ACK uses dest+bst only. Silicon `STILL_STALL` remains open.

`VERDICT: PASS_NARROW` because the claim is XSim tile+completable-stub first-chunk handshake only (n=1 UNIT). Same-clk DMA, no MIG, no WDMA CDC, no leftover grant.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` (not the closeout table). Re-hash of `xsim.log` matches the claimed SHA.

| Metric | Raw log | Closeout / STATUS | Class |
|--------|---------|-------------------|-------|
| Vehicle | `VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB` | tile-only completable stub | EVIDENCE (XSim) |
| Elab | `weight_tile803k(SIM_FULL=1'b0)` | `SIM_FULL=0` | EVIDENCE |
| SNAP_D4 | `cyc=18 dest=4 dbg_dst=3 bst=4 stall=1 … busy=1 done=0` | dest=4, `B_REQ`, stall=1 | EVIDENCE |
| SNAP_D5 | `cyc=20 dest=5 dbg_dst=4 bst=4 stall=1 … busy=0 done=0 ack=0` | dest=5, still `B_REQ` | EVIDENCE |
| SNAP_BST_AFTER | `cyc=24 dest=5 dbg_dst=5 bst=5 bst_max=5 stall=1 req=1 ack=1 watch=5` | dest=5, `B_WAITACK` | EVIDENCE |
| CLASS | `CLASS=CHUNK_ACK` | CHUNK_ACK | EVIDENCE |
| Marker | `E2R_TILE_AFTER_SDONE_CXSIM_00_XSIM_PASS class=CHUNK_ACK … dest4=1 dest5=1 bst_after=5 stall_after=1` | same | EVIDENCE |
| C_FIX | `C_FIX=NONE` | NONE | EVIDENCE |
| BOARD_PASS | `BOARD_PASS=not_claimed` | not claimed | EVIDENCE |
| EXISTENCE | `EXISTENCE=not_claimed` | not claimed | EVIDENCE |
| PROGRAM | `PROGRAM=NO` | NO | EVIDENCE |
| $finish | `355 ns` TB line 157 | 355 ns | EVIDENCE |

TB class law (`tb_e2r_tile_after_sdone_cxsim_00.sv`): `saw_d5` (`TILE.dst==D_ACK`=5) ∧ `bst_live >= B_WAITACK` (5) → `CHUNK_ACK`. No `stall==0` conjunct. Matches the log.

RTL enums (`weight_tile803k.sv` TILE generate): `D_WAITDONE`=4, `D_ACK`=5; `B_REQ`=4, `B_WAITACK`=5, `B_STORE`=6. `stall = (bst != B_IDLE) || miss`. First dest=5 snap still `B_REQ` is the `dbg_dst` / ack CDC lag; class waits for `bst>=5`.

n = 1 tile miss, first chunk. Not a cycle farm.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `F660793B12EB2749C6E4F4C41F8136C322D017311E240F07D6A7ED98D375B034` | **match** |
| TB (`tests/xsim` and archive copy) | `0DEEFEC9CE468047F0CCD0C506A6FEDEA26DC2030BDCC49373691D02F437BB45` | **match** (identical) |
| `rtl/lm/weight_tile803k.sv` | `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` | **match** (not edited this gate) |

`xsim_stdout.txt` transcript body agrees with `xsim.log` (same SNAP/CLASS/marker lines).

---

## Adversarial checks (requested)

| Check | Result |
|-------|--------|
| CHUNK_ACK only if dest=5 ∧ bst reached `B_WAITACK` or `B_STORE` | **PASS.** dest=5 and `bst=5`. `bst_max=5` (not `B_STORE`; not required). |
| Fail if they required stall=0 | **Not required.** `stall_after=1`. TB comment + dispatch falsifier: one-chunk stall=1 is refill law. |
| XSim ≠ board; CHUNK_ACK must not close silicon `STILL_STALL` | **Held.** Closeout: does not prove silicon `bst` left `B_REQ`. REARM `STILL_STALL` stays sealed. UART `TILE_BST=4` treated as first-seen latch. |
| `ACK_STUCK` falsified only on this stub | **Held.** Closeout / STATUS: “on this tile+completable-stub vehicle”. Silicon hang remains a different unknown. |
| No C-FIX / program / RTL edit | **Held.** Log `C_FIX=NONE` `PROGRAM=NO`. `weight_tile803k.sv` SHA unchanged; git last write 2026-08-27. New files are TB/tcl/archive only. |
| Re-hash `xsim.log` | **match** `F660793B…D375B034` |

MASTER_PREFLIGHT “Silicon 300 s hang is **not** ‘ack never leaves B_REQ’ **on that vehicle**” is scoped to the stub. It does **not** reclassify REARM (`STILL_STALL` remains). Do not promote that sentence into a silicon close.

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| dest 4→5 then `bst=5` (`B_WAITACK`), `ack=1`, `stall=1` on this stub | EVIDENCE (XSim) |
| `ACK_STUCK` falsified on this vehicle | EVIDENCE (XSim) |
| XSim ≠ board; same-clk stub ≠ MIG / WDMA CDC | declared; held |
| silicon `bst` left `B_REQ` | **not claimed**; stays NEEDS_EXPERIMENT |
| silicon `STILL_STALL` / no `CORE_DONE` / `pred=664` | **not claimed**; REARM observer still `STILL_STALL` |
| UART `TILE_BST=4` compatible with first dest=5 still `B_REQ` | ENGINEERING_INFERENCE (first-seen latch vs later `bst`) |

No averaging of XSim with board. Marker is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen |
| Test deleted / skipped / stall=0 required | not seen; `ACK_STUCK` / `DEST_STUCK` / `NO_MISS` still legal |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path |
| Hold-busy after 8 R | not used; stub pulses `dma_done` and clears busy |
| `SIM_FULL=1` (stall hardcoded 0) | xelab `SIM_FULL=1'b0`; stall printed 1 |
| Leftover grant bags / `soc_top` / MIG | not in `sources.f` |
| C-FIX / force dest or bst | hierarchical observe only (`dut.TILE.dst/bst/ack`) |
| Product RTL this gate | SHA unchanged vs 2026-08-27 |
| Board / bitstream / JTAG | no `vivado.exe` impl; xsim 12:28:03–12:28:07 |
| `BOARD_PASS` / existence PASS | explicitly not claimed |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last implementer line (244): `gate=E2R-TILE-AFTER-SDONE-CXSIM-00` `agent=a7-ng-xsim-verify` `result=PASS_NARROW` `class=CHUNK_ACK` `sha256=F660793B…` `existence=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=CHUNK_ACK` file-backed dest=5 ∧ `B_WAITACK`/`B_STORE`? | **Yes.** dest=5, `bst=5`. |
| stall=0 required? | **No.** `stall_after=1`. |
| `ACK_STUCK` falsified only on this stub? | **Yes.** |
| Silicon `STILL_STALL` closed? | **No.** |
| `C_FIX=NONE` / PROGRAM=NO / RTL unedited? | **Yes.** |
| `xsim.log` SHA match? | **Yes.** `F660793B12EB2749C6E4F4C41F8136C322D017311E240F07D6A7ED98D375B034` |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |

---

## NOT VERIFIED

- Board UART recapture after this XSim (none claimed; COM12 not used).
- Silicon live `bst` after dest=5 (UART `TILE_BST` is first-seen only).
- Whether later chunks / CDC / mux / core explain the 300 s hang (out of this UNIT).
- `xvlog.log` / `xelab.log` scanned for `ERROR` / `CRITICAL WARNING` (none). Full warning catalogs not re-read line-by-line.
- Main-tree dirty SOA RTL / untracked integrate files are pre-existing and outside this gate.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell silicon `STILL_STALL` as `ACK_STUCK` closed. Next silicon unknown stays dest=5 ∧ no `CORE_DONE` / `pred=664`, not this stub.

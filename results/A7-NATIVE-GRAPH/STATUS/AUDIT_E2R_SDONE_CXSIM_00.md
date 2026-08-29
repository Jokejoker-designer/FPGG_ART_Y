# AUDIT — E2R-SDONE-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial)  
**Date:** 2026-08-28  
**Gate:** `E2R-SDONE-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SDONE_CXSIM_CLOSEOUT.md`  
**Agent archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-SDONE-CXSIM-00/`  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: 1 FINDING
VERDICT: PASS_NARROW
CLASS=SDONE_ROSE: file-backed on completable mux+stub
H_CANDIDATE SDONE_NEVER: falsified on this vehicle only
LEFTOVER SET FORBIDS DONE ON COMPLETABLE STUB: NO (XSim)
HOLD-BUSY: not used
C_FIX: NONE
EXISTENCE: NO
BOARD_PASS: not_claimed
SILICON SDONE=0: not answered
```

Parent STATUS XSim PASS / `CLASS=SDONE_ROSE` / `C_FIX=NONE` is file-backed. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: 1 FINDING` — MINOR on the **agent** closeout’s “print-time” residual for silicon UART `SDONE=0`. Parent STATUS already says sequential `SDONE=0` is **not answered**. No CRITICAL. No MAJOR. Forbidden PASS routes not taken.

---

## Finding

```
[MINOR] Agent Interpretation lists “print-time” as a silicon-SDONE residual
  where     : arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-SDONE-CXSIM-00/CLOSEOUT.md:105
  claim      : “Sequential UART SDONE=0 remains compatible with
               still-in-R / print-time / stub≠board.”
  evidence   : SoC UART SDONE is not the live s_done pulse.
               arty_a7_ng_native_v1_ab_soc_top.sv:
                 wdma_dbg_sdone = CDC dbg_s_done_sticky
                   (OR-set on s_done; clears on s_rst_n only)
                 latched_sdone_f1t <= wdma_dbg_sdone
                   while sticky_qgo_ui && core_busy_ui (ui_clk)
                 UART row 6'd56 prints hex_nib(sdone_lat_100)
               Pulse-already-consumed “print-time” does not apply to that latch.
               If sticky rose during core_busy_ui, the printed SDONE row
               should be 1. Silicon SDONE=0 is then a miss of the sticky in
               the latch window, or true never, or still-in-R (ATOM dma_st=5).
               This vehicle: no soc_top, no UART, no MIG.
  why it matters: A reader could reuse the SGO GRANT-skew mistake and treat
               board SDONE=0 as “pulse already gone.” Parent STATUS does
               not do that — keep it that way.
  fix        : Drop “print-time” from the silicon residual list.
               Keep still-in-R / stub≠board. Do not close silicon SDONE.
```

Parent STATUS “Sequential `SDONE=0` not answered” / “still-in-R” is **correct**. Silicon UART `SDONE=0` **may not** be sold as answered, and **may not** be sold as pulse print-time.

H_RIVAL as a **preregistered vehicle hypothesis** (“done rises after complete beats”) is OK and file-backed. The extra “print-time” word in the agent Interpretation is the only overclaim.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` / `probe_table.csv` (not the closeout table).

| Metric | Raw log / CSV | Parent STATUS | Class |
|--------|---------------|---------------|-------|
| First dest (UNIT snap) | `FIRST_TILE_DST=4` `snap_cyc=355` | dest=4 | EVIDENCE |
| Live dest at FIRST_DESTWAIT dump | `dst=5` t=29640000 | later burst; documented | EVIDENCE |
| grant / idle at snap | grant=1 idle=0 | grant=1 idle=0 | EVIDENCE |
| leftover | fifo=4 c_rvalid=1 n_hot=2 mask=0110 | fifo=4 c_rvalid=1 SET | EVIDENCE |
| `s_go` ever | `SGO_EVER=1` | ever=1 | EVIDENCE |
| live `s_done` at dest-wait dump | `s_done=0` | pulse gone | EVIDENCE |
| `s_done` ever | `S_DONE_EVER=1` | ever=1 | EVIDENCE |
| `dbg_s_done_sticky` dest=4 | `SNAP_SDONE sdone_st=1` / `S_DONE_STICKY_AT_DEST4=1` | sticky=1 | EVIDENCE |
| sticky at end | `S_DONE_STICKY_END=1` | 1 | EVIDENCE |
| snap `w_st` | `wst=0` (W_IDLE) | first burst already complete | EVIDENCE |
| live dest-wait `w_st` | `wst=3` `rleft=8` dest=5 | later burst in R | EVIDENCE |
| `s_busy` dest=4 / end | 1 / 1 (`m_busy=0`) | same | EVIDENCE |
| CLASS | `CLASS=SDONE_ROSE` + marker | SDONE_ROSE | EVIDENCE |
| C_FIX | `C_FIX=NONE` | NONE | EVIDENCE |
| BOARD_PASS | `BOARD_PASS=not_claimed` | not claimed | EVIDENCE |
| EXISTENCE | `EXISTENCE=not_claimed` | Existence NO | EVIDENCE |

TB class law (`tb_e2r_sdone_cxsim_00.sv`): dest=4 seen ∧ (`snap_sdone_st` ∨ `end_sdone_st` ∨ ever bits) → `SDONE_ROSE`. Matches.

`leftover_ctrl=AMBIGUOUS` in the TB is the single-wire namer (`n_hot≠1`). ATOM `SET` = dest=4 idle=0 and >1 leftover constituent. n_hot=2 (fifo + c_rvalid) is that SET. Not a contradiction.

WDMA_GO t=26760000: dest=0 `m_go=1` `s_go=0` stickies 0 — pulse not yet crossed CDC. Dest-wait later has `sgo_ever=1` and `sdone_ever=1`. One query, `snap_cyc=355`. Not a cycle farm.

Snap `w_st=0` means the **first** completable 8-R burst had already returned to idle before the dest=4 latch. Leftover SET was still present (fifo + `c_rvalid`) and did not prevent that done. A later burst was already in R on the live dump. That occupancy is **not** silicon ATOM dest=4 ∧ `dma_st=5(R)`.

---

## Hold-busy / completable responder

CONTROL MUX TB `tb_e2r_sgo_cxsim_mux_00.sv` `W_HOLD`:

```text
s_dma_busy <= 1'b1;
s_dma_done <= 1'b0;
```

This TB `W_HOLD`:

```text
s_dma_busy <= 1'b0;
s_dma_done <= 1'b1;
w_st       <= W_IDLE;
```

Vehicle banner: `COMPLETABLE_RESPONDER`. `s_dma_idle` stays `1'b0`. No force dest. No `assign r_path_idle=1`. No `soc_top` / MIG in `sources.f`. Hold-busy **was not used**.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `DF55ACF49B11E170DFBC6E38E1B302128EB9F6D7433F0D08A4B7A02495118520` | **match** |
| TB (`tests/xsim` and archive copy) | `7A9C01D4BA6E2AB3477C82C0AD3E77B78A0AD888DF84FA931B3EBB7649E320C8` | **match** (identical) |
| `a7ng_wdma_cdc.sv` | `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` | **match** (not edited this gate) |

`xsim_stdout.txt` SHA256 `FF5CFAC9B26C168B9713CC599805BEFB52DCC7412916FA0FB47D142818FA736F` (not claimed; transcript agrees with `xsim.log` body).

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| mux+stub dest=4 grant=1 idle=0 leftover fifo+c_rvalid; `s_done` ever=1; sticky=1 at dest=4 | EVIDENCE (XSim) |
| leftover SET does not forbid done on this completable responder | EVIDENCE (XSim) |
| `SDONE_NEVER` falsified on this vehicle | EVIDENCE (XSim) |
| XSim ≠ board; stub ≠ MIG; first-burst-done ≠ silicon still-in-R | declared; held |
| silicon `s_done` rose | **not claimed**; stays NEEDS_EXPERIMENT |
| silicon `SDONE=0` answered / pulse print-time | FALSE_OR_OVERCLAIM if sold; parent does not sell it; agent “print-time” word is the MINOR |

No averaging of XSim with board. Marker `E2R_SDONE_CXSIM_00_XSIM_PASS` is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen |
| Test deleted / skipped / tolerance widened | not seen; `SDONE_NEVER` / `FAIL_NO_DESTWAIT` still legal |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path |
| Hold-busy after 8 R | not used; completable `W_HOLD` |
| C-FIX / A2 / LiteScope / force dest / `r_path_idle=1` / retie `s_dma_idle` | log `C_FIX=NONE`; TB `s_dma_idle=1'b0`; no `soc_top` / MIG in `sources.f` |
| Product RTL this gate | TB + tcl + archive only; CDC SHA unchanged vs SGO-MUX |
| Board / bitstream / JTAG | no `vivado.exe` impl; xsim 00:10:07–00:10:09 |
| `BOARD_PASS` / existence PASS | explicitly not claimed |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |

Board-tree `soc_top.sv` is dirty from the prior F1/ATOM probe ladder, not from this XSim (vehicle does not instantiate it). This gate did not apply a product C-FIX.

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last line (219): `gate=E2R-SDONE-CXSIM-00` `agent=a7-ng-xsim-verify` `result=DISPATCHED` `board=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00; completable responder; no hold-busy`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the last jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=SDONE_ROSE` file-backed on completable stub? | **Yes.** Log + CSV + TB law. |
| Leftover SET forbid done on completable stub? | **No.** dest=4 leftover SET ∧ `s_done` ever=1 ∧ sticky=1. |
| `H_CANDIDATE SDONE_NEVER` falsified only on this vehicle? | **Yes.** Parent scopes “on this stub”. Silicon still-in-R remains open. |
| Hold-busy used? | **No.** Completable `W_HOLD` pulses done and clears busy. |
| `C_FIX=NONE`? | **Yes.** |
| Silicon `SDONE=0` sold as answered? | **No** (parent). Agent must not use “print-time” as a silicon close. |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |
| Occupancy = silicon ATOM dest=4 ∧ `dma_st=5(R)`? | **No.** Snap `w_st=0`; silicon ATOM is still-in-R. |

---

## NOT VERIFIED

- Board UART recapture after this XSim (none claimed; COM12 not used).
- Whether silicon `dbg_s_done_sticky` is 0 for the whole `core_busy_ui` window vs rose after `core_busy_ui` dropped (latch-window miss). Parent did not close that UNKNOWN.
- Whether dirty board-tree `soc_top.sv` bytes beyond the F1/ATOM probe path differ from the programmed bit (out of this gate’s claim).
- `xvlog.log` / `xelab.log` scanned for `ERROR` / `CRITICAL WARNING` (none). Full warning catalogs not re-read line-by-line.
- Main-tree dirty SOA RTL / untracked integrate files are pre-existing and outside this gate.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell silicon `SDONE=0` as answered or as pulse print-time. Next silicon unknown stays dest=4 ∧ still-in-R, not this stub.

# AUDIT — E2R-SDONE-STILLR-CXSIM-00

**Auditor:** `a7-evidence-auditor` (adversarial)  
**Date:** 2026-08-28  
**Gate:** `E2R-SDONE-STILLR-CXSIM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SDONE_STILLR_CXSIM_CLOSEOUT.md`  
**Agent archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-SDONE-STILLR-CXSIM-00/`  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=SNAP_DONE0: file-backed on still-in-R-then-complete mux+stub
dest=4 + in-R + sticky=0 at UNIT snap: YES
sticky=1 after later complete: YES (secondary)
ROSE bag used as this vehicle: NO
C_FIX: NONE
EXISTENCE: NO
BOARD_PASS: not_claimed
SILICON SDONE=0: compatible with still-in-R, not proven
```

Parent STATUS closeout **already exists** (`STATUS/E2R_SDONE_STILLR_CXSIM_CLOSEOUT.md`). Auditor did not rewrite it. XSim PASS / `CLASS=SNAP_DONE0` / `C_FIX=NONE` is file-backed. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR. Forbidden PASS routes not taken. Silicon `SDONE=0` is not sold as proven. ROSE completable bag was not this vehicle.

`VERDICT: PASS_NARROW` because the claim is XSim-stub occupancy only (n=1 query). Grant-rose vs sequential silicon `GRANT=0` remains a disclosed MUX deviation. Leftover AND stays `fifo`+`c_rvalid` (`n_hot=2`).

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` / `probe_table.csv` (not the closeout table). UNIT = first dest=4 NBA snap (`SNAP_*`), not the later live `FIRST_DESTWAIT` dump.

| Metric | Raw log / CSV | Agent closeout / STATUS | Class |
|--------|---------------|-------------------------|-------|
| Vehicle banner | `STILLR_THEN_COMPLETE s_dma_idle=0` | still-in-R then complete | EVIDENCE |
| First dest (UNIT snap) | `DEST4=1` `FIRST_TILE_DST=4` `snap_cyc=355` | dest=4 | EVIDENCE |
| grant / idle at snap | `SNAP … grant=1` `idle=0` | grant=1 idle=0 | EVIDENCE |
| leftover | `fifo=4 c_rvalid=1` `AND_MASK … 0110 n_hot=2` | fifo + `c_rvalid` SET | EVIDENCE |
| in-R/busy at snap | `SNAP_SDONE … s_busy=1 m_busy=1 wst=3` `IN_R_AT_SNAP=1` | in-R (`W_R`=3) | EVIDENCE |
| `s_go` ever | `SGO_EVER=1` | ever=1 | EVIDENCE |
| `dbg_s_done_sticky` at dest=4 | `SNAP_SDONE sdone_st=0` `S_DONE_STICKY_AT_DEST4=0` | sticky=0 | EVIDENCE |
| `s_done` ever at dest=4 | `SNAP_SDONE sdone_ever=0` | 0 at snap | EVIDENCE |
| sticky after later complete | `END_SDONE sdone_st=1` `S_DONE_AFTER_COMPLETE=1` | 1 | EVIDENCE |
| Live `FIRST_DESTWAIT` (not UNIT) | t=29640000 dst=4 `sdone_st=1` `wst=3` `rleft=3` | one `core_clk` later; after-snap complete | EVIDENCE |
| CLASS | `CLASS=SNAP_DONE0` + marker | SNAP_DONE0 | EVIDENCE |
| C_FIX | `C_FIX=NONE` | NONE | EVIDENCE |
| BOARD_PASS | `BOARD_PASS=not_claimed` | not claimed | EVIDENCE |
| EXISTENCE | `EXISTENCE=not_claimed` | Existence NO | EVIDENCE |

TB class law (`tb_e2r_sdone_stillr_cxsim_00.sv`): dest=4 seen ∧ (`snap_wst==W_R`) ∧ `snap_sbusy_dma` ∧ `!snap_sdone_st` → `SNAP_DONE0`. Matches.

`snap_sdone_st <= sdone_st_m2 | dbg_s_done_sticky` — live sticky is OR-ed in. Snap=0 means sticky was 0 on the dest=4 posedge, not a 2-FF miss of a prior done.

Live `FIRST_DESTWAIT` is after `@(posedge core_clk)` once `destwait_seen` is true (TB). Same `$time` as ROSE dest-wait dump (29640000); occupancy differs. That row already has `sdone_st=1` / `sdone_ever=1` because `dest4_seen_ui` (2-FF on `ui_clk`) unblocks `W_HOLD` inside one 80 ns `core_clk`. Closeout correctly refuses that row as the UNIT.

`leftover_ctrl=AMBIGUOUS` is the single-wire namer (`n_hot≠1`). ATOM `SET` = dest=4 idle=0 and >1 leftover constituent. n_hot=2 is that SET. Not a contradiction.

One query, `snap_cyc=355`. Not a cycle farm.

---

## ROSE bag was not this vehicle

| | ROSE `E2R-SDONE-CXSIM-00` | This `E2R-SDONE-STILLR-CXSIM-00` |
|--|---------------------------|----------------------------------|
| TB | `tb_e2r_sdone_cxsim_00.sv` SHA `7A9C01D4…` | `tb_e2r_sdone_stillr_cxsim_00.sv` SHA `013BA2A8…` (tests ≡ archive) |
| xvlog / xelab | `tb_e2r_sdone_cxsim_00` | `tb_e2r_sdone_stillr_cxsim_00` snapshot `e2r_sdone_stillr_cxsim_00` |
| Banner | `COMPLETABLE_RESPONDER` | `STILLR_THEN_COMPLETE` |
| `xsim.log` SHA | `DF55ACF4…` (CONTROL, not re-run) | `4F71A710…` |
| UNIT snap | `wst=0` sticky=1 | `wst=3` sticky=0 |
| Live dest-wait dump | dst=**5** (later burst) | dst=**4** |
| CLASS | `SDONE_ROSE` | `SNAP_DONE0` |

ROSE `W_R` completes on last beat (`w_st <= W_HOLD` immediately). This TB’s one change: stay in `W_R` with `busy=1` until `dest4_seen_ui`, then `W_HOLD` pulse. Completing before dest=4 is the ROSE FALSIFIER; it was not used.

---

## Silicon `SDONE=0` not sold as proven

Agent Interpretation and parent STATUS: this bag **shares a still-in-R occupancy class** with ATOMIC-SGO dest=4 `dma_st=5(R)` and is **compatible** with sequential UART `SDONE=0`. Explicitly **not** a silicon measurement. XSim stub+CDC ≠ board UART / MIG. No `soc_top` in `sources.f`. No `vivado.exe` impl. No COM / bit / JTAG.

H_CANDIDATE text (“silicon `SDONE=0` can be same-cycle still-in-R”) is the **hypothesis**, not the verdict. Verdict: **supported on this vehicle**. Silicon remains NEEDS_EXPERIMENT (`E2R-ATOMIC-SDONE-PROBE-00`).

Disclosed residuals (do not close them here): `GRANT_ROSE_BEFORE_DESTWAIT=1` vs sequential silicon `GRANT=0`; leftover `n_hot=2`.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `4F71A710F5899FBA1E45AD53C7FED59274CF0018073D8861FB395A6DFA7CABD7` | **match** |
| TB (`tests/xsim` and archive copy) | `013BA2A8006786B7F844E38DD4EF180DBD82E0DBF425314CB4BA0E3AD5FD1A62` | **match** (identical) |
| ROSE CONTROL `E2R-SDONE-CXSIM-00/xsim.log` | `DF55ACF49B11E170DFBC6E38E1B302128EB9F6D7433F0D08A4B7A02495118520` | **match** (not re-run) |
| ROSE TB | `7A9C01D4…` | **match** (different file) |
| `rtl/board/a7ng_wdma_cdc.sv` | `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` | **match** (not edited this gate) |

`xsim_stdout.txt` SHA256 `3ACA28F0053CBB7B194750455BE6E5DE04838135C52BE9702B30416EC7892A55` (not claimed; transcript agrees with `xsim.log` body).

xvlog / xelab: no `ERROR` / `CRITICAL WARNING` in stdout. `$finish` from `tests/xsim/tb_e2r_sdone_stillr_cxsim_00.sv` line 845.

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| dest=4 grant=1 idle=0 leftover fifo+`c_rvalid`; in-R (`w_st=3`,`s_busy=1`); sticky=0 at snap; sticky=1 after complete | EVIDENCE (XSim) |
| `SNAP_DONE0` on this still-in-R vehicle; `SNAP_DONE1` not supported here | EVIDENCE (XSim) |
| ROSE occupancy (done before dest=4) is a different bag | EVIDENCE (XSim CONTROL SHA `DF55ACF4…`) |
| XSim ≠ board; stub ≠ MIG; `w_st=3` ≠ silicon `dma_st` encoding identity | declared; held |
| silicon `dbg_s_done_sticky` was 0 at dest=4 | **not claimed**; stays NEEDS_EXPERIMENT |
| silicon `SDONE=0` proven / answered | FALSE_OR_OVERCLAIM if sold; parent and agent do not sell it |

No averaging of XSim with board. Marker `E2R_SDONE_STILLR_CXSIM_00_XSIM_PASS` is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen; `SNAP_DONE0` and `SNAP_DONE1` both legal PASS markers |
| Test deleted / skipped / tolerance widened | not seen; `FAIL_NOT_IN_R` / `FAIL_NO_DESTWAIT` still legal |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path |
| Complete-before-dest=4 (ROSE) | not used; snap `wst=3` sticky=0 |
| Hold-busy forever after dest=4 (MUX) | not used; `W_HOLD` pulses done; `S_DONE_AFTER_COMPLETE=1` |
| C-FIX / A2 / LiteScope / force dest / `r_path_idle=1` / retie `s_dma_idle` | log `C_FIX=NONE`; TB `s_dma_idle=1'b0`; `tile_dst` from `dbg_tile_dst_o` |
| Product RTL this gate | TB + tcl + archive only; CDC SHA unchanged vs ROSE / SGO-MUX |
| Board / bitstream / JTAG | no `vivado.exe` impl; xsim 00:24:14–00:24:16 |
| `BOARD_PASS` / existence PASS | explicitly not claimed; no `pred=664` |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |

`sources.f` compiles `a7ng_cue_soa_mig_top` (graph wrapper, same as ROSE) and does **not** instantiate `arty_a7_ng_native_v1_ab_soc_top` or Digilent MIG IP.

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last line (221): `gate=E2R-SDONE-STILLR-CXSIM-00` `agent=a7-ng-xsim-verify` `result=DISPATCHED` `board=false` `board_pass=false` `note=existence side-lane; not graph_late_materialize_00; still-in-R at dest=4 matching silicon dma_st=5`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the last jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=SNAP_DONE0` file-backed? | **Yes.** dest=4 ∧ in-R ∧ sticky=0 at UNIT snap. |
| sticky=1 after later complete? | **Yes.** Secondary metric. |
| ROSE bag used as this vehicle? | **No.** Different TB, SHA, banner, snap occupancy, class. |
| `C_FIX=NONE`? | **Yes.** |
| Silicon `SDONE=0` sold as proven? | **No.** Compatible with still-in-R only. |
| `BOARD_PASS` / existence? | **not claimed** / **NO**. `pred=664` absent. |
| Occupancy encoding = silicon `dma_st=5`? | **No.** Class is still-in-R, not bit-identical DMA state. |

---

## Parent STATUS closeout

Present before this audit: `results/A7-NATIVE-GRAPH/STATUS/E2R_SDONE_STILLR_CXSIM_CLOSEOUT.md`.  
Log SHA, `SNAP_DONE0`, `C_FIX=NONE`, “compatible … not proven”, ROSE called a different occupancy — all match the raw bag. Auditor left it in place.

---

## NOT VERIFIED

- Board UART recapture after this XSim (none claimed; COM12 not used).
- Whether silicon `dbg_s_done_sticky` is 0 for the whole `core_busy_ui` latch window at dest=4 ∧ `dma_st=5` (next bind, not this bag).
- Whether dirty board-tree `soc_top.sv` bytes beyond the F1/ATOM probe path differ from the programmed bit (out of this gate’s claim).
- Full xvlog/xelab warning catalogs line-by-line (no ERROR / CRITICAL WARNING in stdout).
- Main-tree dirty SOA RTL / untracked integrate files are pre-existing and outside this gate.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell silicon `SDONE=0` as answered. Next silicon unknown stays dest=4 ∧ still-in-R on COM12, not this stub.

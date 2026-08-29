# AUDIT — E2R-SGO-CXSIM-MUX-00

**Auditor:** `a7-evidence-auditor` (adversarial)  
**Date:** 2026-08-27  
**Gate:** `E2R-SGO-CXSIM-MUX-00` (existence side-lane; not `LOOP_STATE.next`)  
**Claim graded:** `results/A7-NATIVE-GRAPH/STATUS/E2R_SGO_CXSIM_MUX_CLOSEOUT.md`  
**Agent archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-SGO-CXSIM-MUX-00/`  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: 1 FINDING
VERDICT: PASS_NARROW
CLASS=SGO_ROSE: file-backed on mux+stub
H_CANDIDATE SGO_NEVER: falsified on this vehicle only
EXISTENCE: NO
BOARD_PASS: not_claimed
SILICON SGO=0 AS GRANT-STYLE UART-SKEW: FORBIDDEN
```

Parent STATUS XSim PASS / `CLASS=SGO_ROSE` / `C_FIX=NONE` is file-backed. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: 1 FINDING` — MAJOR on the **agent** closeout’s silicon UART inference. Parent STATUS already rejects that inference. No CRITICAL. Forbidden PASS routes not taken.

---

## Finding

```
[MAJOR] Agent closeout sells sequential UART SGO=0 as GRANT-style print-time skew
  where     : arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-SGO-CXSIM-MUX-00/CLOSEOUT.md:20
              and Interpretation § lines 92–96
  claim      : H_RIVAL “UART SGO=0 is print-time like GRANT skew”;
               “Sequential UART SGO=0 is compatible with print-time
               (pulse already consumed), like GRANT skew vs ATOM.”
  evidence   : SoC UART SGO is not the live s_go pulse.
               arty_a7_ng_native_v1_ab_soc_top.sv:
                 wdma_dbg_sgo = CDC dbg_s_go_sticky (OR-set on s_go_r; clears on s_rst_n only)
                 latched_sgo_f1u <= wdma_dbg_sgo while sticky_qgo_ui && core_busy_ui (ui_clk)
                 UART row 6'd60 prints hex_nib(sgo_lat_100) from that latch
               GRANT UART-SKEW (E2R-UART-SKEW-CXSIM-00) was sequential pack of
               live-sampled dest vs grant/idle from different cycles.
               GRANT latch (F1v) overwrites latched_wdma_grant_f1v <= wdma_owner_grant
               while core_busy (can fall). SGO latch overwrites with a sticky that
               does not fall once set.
               This vehicle: no soc_top, no UART, no MIG. Live s_go at dest=4 = 0
               and sticky = 1 is XSim pulse-vs-sticky, not silicon UART law.
  why it matters: A reader of the agent CLOSEOUT would treat board SGO=0 as
               the same class as sequential GRANT=0 vs ATOM grant=1, and close
               “s_go rose on silicon.” If sticky rose during core_busy_ui,
               the printed SGO row should be 1. Silicon SGO=0 is then a miss
               of the sticky in the latch window (or a true miss), not
               “pulse already consumed.”
  fix        : Keep H_RIVAL support scoped to mux+stub sticky=1.
               Do not apply “print-time like GRANT” to silicon UART SGO.
               Parent STATUS already states this — do not weaken it.
```

Parent STATUS “Do not treat as GRANT-skew” is **correct vs SoC RTL**. Silicon sequential `SGO=0` **may not** be sold as GRANT-style UART-SKEW.

H_RIVAL as a **preregistered vehicle hypothesis** (“sticky=1 at dest=4”) is OK. The silicon-UART clause attached to that rival is the overclaim.

---

## Independent re-derivation (headline numbers)

Source: `xsim.log` / `xsim_stdout.txt` / `probe_table.csv` (not the closeout table).

| Metric | Raw log / CSV | Parent STATUS | Class |
|--------|---------------|---------------|-------|
| First dest | `FIRST_DESTWAIT dst=4` t=29640000 | dest=4 | EVIDENCE |
| grant / idle | grant=1 idle=0 | grant=1 idle=0 | EVIDENCE |
| leftover | fifo=4 c_rvalid=1 n_hot=2 mask=0110 | fifo=4 c_rvalid=1 | EVIDENCE |
| live `s_go` at snap | `s_go=0` | pulse gone | EVIDENCE |
| `s_go` ever | `sgo_ever=1` | ever=1 | EVIDENCE |
| `dbg_s_go_sticky` dest=4 | `sgo_st=1` / `SGO_STICKY_AT_DEST4=1` | sticky=1 | EVIDENCE |
| sticky at end | `SGO_STICKY_END=1` | 1 | EVIDENCE |
| `m_go_sticky` / cmd | mgo_st=1 cmd_st=2 cmd_rd=1 | same | EVIDENCE |
| CLASS | `CLASS=SGO_ROSE` + marker | SGO_ROSE | EVIDENCE |
| C_FIX | `C_FIX=NONE` | NONE | EVIDENCE |
| BOARD_PASS | `BOARD_PASS=not_claimed` | not claimed | EVIDENCE |

TB class law (`tb_e2r_sgo_cxsim_mux_00.sv`): dest=4 seen ∧ `snap_sgo_st` → `SGO_ROSE`. Matches.

`leftover_ctrl=AMBIGUOUS` in the TB is the single-wire namer (`n_hot≠1`). ATOM `SET` = dest=4 idle=0 and >1 leftover constituent. n_hot=2 (fifo + c_rvalid) is that SET. Not a contradiction.

WDMA_GO t=26760000: dest=0 `m_go=1` `s_go=0` stickies 0 — pulse not yet crossed CDC. Dest-wait later has sticky=1. One query, `snap_cyc=355`. Not a cycle farm.

---

## SHA256 (independent)

| Artifact | Claimed | Recomputed |
|----------|---------|------------|
| `xsim.log` | `68B3280522FAEB1FBA67E89E96C17BC608AB0D7337B8752216420F09ADA3E189` | **match** |
| TB (`tests/xsim` and archive copy) | `FE7CD3878A6AB4B56601C9227AD747DD41A3B47DE7D9D314B8E7201F3DB1684D` | **match** |
| `a7ng_wdma_cdc.sv` | `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` | **match** (not edited this gate) |

`xsim_stdout.txt` SHA256 `B03FA1AAC2676CD2D26A9257BB440A4C3225CD61BDD5FD075C0543BF4D22CDC6` (not claimed; transcript agrees with `xsim.log` body).

---

## Evidence class / provenance

| Assertion | Class |
|-----------|-------|
| mux+stub dest=4 grant=1 idle=0 leftover fifo+c_rvalid; sticky=1 | EVIDENCE (XSim) |
| `SGO_NEVER` falsified on this vehicle | EVIDENCE (XSim) |
| stub vehicle can issue `s_go` on ATOM-like leftover | EVIDENCE (XSim) |
| XSim ≠ board; stub ≠ MIG | declared; held |
| silicon `s_go` rose | **not claimed** by parent; must stay NEEDS_EXPERIMENT |
| silicon `SGO=0` = pulse print-time / GRANT-SKEW | FALSE_OR_OVERCLAIM (agent Interpretation); rejected by parent |

No averaging of XSim with board. Marker `E2R_SGO_CXSIM_MUX_00_XSIM_PASS` is an XSim marker only.

---

## Forbidden PASS routes

| Route | Result |
|-------|--------|
| Golden / expected edited to match DUT | not seen |
| Test deleted / skipped / tolerance widened | not seen; `SGO_LATE` still non-PASS |
| Seed shopping | n=1 preregistered UNIT |
| Host computes answer / winner / cue | no EVAL path |
| C-FIX / A2 / LiteScope / force dest / `r_path_idle=1` / retie `s_dma_idle` | log `C_FIX=NONE`; TB `s_dma_idle=1'b0`; no `soc_top` / MIG in `sources.f` |
| Product RTL this gate | TB + tcl + archive only; CDC clean |
| Board / bitstream / JTAG | no `vivado.exe` impl; xsim 21:12:16–21:12:20 |
| `BOARD_PASS` / existence PASS | explicitly not claimed |
| Frozen A0.3 / 01R / 02M / LM-06 bits overwritten | not touched |

Board-tree `soc_top.sv` is dirty (+141/−4) from the prior F1/ATOM probe ladder, not from this XSim (vehicle does not instantiate it). This gate did not apply a product C-FIX.

---

## Dispatch / loop law

`DISPATCH_LOG.jsonl` last line (213): `gate=E2R-SGO-CXSIM-MUX-00` `agent=a7-ng-xsim-verify` `result=DISPATCHED` `board=false` `board_pass=false` `note=existence side-lane XSim; not graph_late_materialize_00`.

`LOOP_STATE.next` / first unfinished main id remains `graph_late_materialize_00` (**QUEUED**, `deferred_by=EXISTENCE_BEFORE_QUALITY`). Agent matches pipeline `a7-ng-xsim-verify`. Side-lane exemption is on the last jsonl line. Does **not** void this XSim class. Does **not** advance the graph loop.

---

## Grade answers

| Question | Answer |
|----------|--------|
| `CLASS=SGO_ROSE` file-backed on mux+stub? | **Yes.** Log + CSV + TB law. |
| `H_CANDIDATE SGO_NEVER` falsified only on this vehicle? | **Yes.** Parent scopes “on mux+stub”. Silicon miss remains open. |
| Parent: do not treat silicon `SGO=0` as GRANT-style UART-SKEW because UART SGO is sticky-latched. Correct vs SoC RTL? | **Yes.** `latched_sgo_f1u <= wdma_dbg_sgo` while `core_busy_ui`. |
| Agent H_RIVAL “UART SGO=0 is print-time like GRANT” | **Overclaim** when applied to silicon UART. OK only as “sticky rose on this XSim vehicle.” |
| `C_FIX=NONE`, no product RTL this gate, no board, no `BOARD_PASS` | **Held.** |
| Existence remains NO | **Held.** `pred=664` absent. |
| May silicon `SGO=0` be sold as skew? | **No.** |

---

## NOT VERIFIED

- Board UART recapture after this XSim (none claimed; COM12 not used).
- Whether silicon `dbg_s_go_sticky` is 0 for the whole `core_busy_ui` window vs rose after `core_busy_ui` dropped (latch-window miss). Parent did not close that UNKNOWN.
- Whether dirty board-tree `soc_top.sv` bytes beyond the F1u/F1v/ATOM probe path differ from the programmed bit (out of this gate’s claim).
- `xvlog.log` / `xelab.log` scanned for `ERROR` / `CRITICAL WARNING` (none). Full warning catalogs not re-read line-by-line.
- Main-tree dirty SOA RTL / untracked integrate files are pre-existing and outside this gate.

---

**Stop:** do not promote `BOARD_PASS`. Do not treat this PASS_NARROW as existence. Do not sell silicon `SGO=0` as GRANT-style UART-SKEW.

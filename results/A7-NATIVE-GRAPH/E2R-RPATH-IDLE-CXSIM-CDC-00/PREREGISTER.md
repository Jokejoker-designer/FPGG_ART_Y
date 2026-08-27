# E2R-RPATH-IDLE-CXSIM-CDC-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_CDC_DISPATCH.md` (main)  
**Class:** C-XSIM CDC (unit XSim only)  
**Board:** NOT used. No COM12. No program. No bitstream. No `vivado.exe` impl writer.  
**Product RTL:** not edited.  
**Forbidden:** `assign r_path_idle=1` absent.

## Prior bags (not repeated as the only bag)

| Bag | Vehicle | Named |
|-----|---------|-------|
| `E2R-RPATH-IDLE-CXSIM-00` | isolated `a7ng_ddr_soa_axi_bridge` complete drain | `NONE` |
| `E2R-RPATH-IDLE-CXSIM-INT-00` | stub-integrated SOA-done (`a7ng_cue_soa_mig_top`) | `NONE` |

This bag inserts **`a7ng_axi_read_cdc`** between the SOA bridge `m_axi` and a dual-clock slave. Isolated same-clock drain and stub-INT (no CDC) are **controls**, not the UNIT.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Isolated + stub-INT C-XSIM: `r_path_idle=1` after SOA-complete. Silicon late-latch: `RPATH_IDLE=0` while `core_busy`. |
| UNKNOWN | After one completed AR/R through `a7ng_axi_read_cdc` into `a7ng_ddr_soa_axi_bridge`, does CDC keep a leftover so bridge `r_path_idle=0`? |
| H_CANDIDATE | CDC `m_rvalid_r` / `m_r_hold` / R FIFO (`!r_empty` or `m_r_pend`) / AR hold (`s_ar_hold` or `ar_m_st!=IDLE`) after last beat holds idle=0. |
| H_RIVAL | CDC quiet after UNIT settle; idle=1. Leftover is mux/tile only → no C-FIX. |
| FALSIFIER | UNIT idle=1 **and** CDC quiet **or** exactly one named leftover wire. |
| UNIT | One 4-beat AR/R query-equivalent through CDC into the SOA bridge, then 32 `m_clk` settle. Not a cycle farm. Not isolated no-CDC drain. Not stub-INT. |
| CONTROL | Silicon late-latch `RPATH_IDLE=0` while `core_busy`. Stub-INT idle=1 without CDC. Isolated idle=1 without CDC. Dual clocks 12.5 MHz / 100 MHz (proven CDC TBs). |
| METRICS | XSIM compile+run; UNIT snapshot of idle + four bridge wires + CDC `m_rvalid_r` / `m_r_hold` / `r_empty` (+ `m_r_pend`, `s_ar_hold`, `ar_m_st`); named `WIRE_THAT_HOLDS_IDLE_0`; `C_FIX_CONSTITUENT`. |

## Vehicle (one change)

| Item | Value |
|------|-------|
| TB | `tests/xsim/tb_e2r_rpath_idle_cxsim_cdc_00.sv` |
| DUT | `a7ng_ddr_soa_axi_bridge` (m_clk) + `a7ng_axi_read_cdc` (m_clk↔s_clk) |
| Slave | behavioral AXI read responder on `s_clk` (not MIG, not isolated same-clock slave) |
| Consumer | `r_ready_i=1` (always-ready; not wavefront) |
| Probe | `r_path_idle_o` + hierarchical `r_drain_hold`, `fifo_cnt`, `m_axi_rvalid`, `tr_cnt` + CDC `m_rvalid_r`, `m_r_hold`, `r_empty` |
| Stop | last consumer beat + 32 `m_clk` settle |
| TILE_DST | **absent** (not faked) |

Idle law (frozen bridge):  
`r_path_idle = !r_drain_hold && (fifo_cnt==0) && !m_axi_rvalid && (tr_cnt==0)`.  
CDC `m_axi_rvalid` **is** `m_rvalid_r`.

CDC quiet (UNIT):  
`m_rvalid_r==0 && m_r_hold==0 && r_empty==1 && m_r_pend==0 && s_ar_hold==0 && ar_m_st==AR_M_IDLE`.

## Protocol (confirmatory; locked before run)

1. Dual reset; XPM recovery (20 `m_clk` + 40 `s_clk`). Snapshot RESET.
2. One `metric_clear` pulse; wait idle (owner-like start). Snapshot POST_CLEAR.
3. One 4-beat AR on `m_clk` into the bridge. Slave on `s_clk` accepts AR and returns exact 4 beats.
4. Wait consumer `r_valid_o` 4-beat complete (includes `r_last`). Snapshot R_CONSUMED (exploratory).
5. **UNIT:** +32 `m_clk` settle. Snapshot idle + four bridge + CDC rvalid/hold/empty/AR.
6. If UNIT idle=0: leave-one-dirty isolation (bridge four + CDC `m_rvalid_r`). Independent-holder count names the wire or `AMBIGUOUS`.
7. Phase C (CONTROL, not UNIT): force-clean then force `m_rvalid_r=1` → expect idle=0 (CDC rvalid is in the idle law). Restore.

## Decision rule (do not rewrite after peeking)

| UNIT snapshot | `WIRE_THAT_HOLDS_IDLE_0` | `C_FIX_CONSTITUENT` |
|---------------|--------------------------|---------------------|
| Idle=1, dirty=0, CDC quiet | `NONE` | `NONE` |
| Idle=0, unique CDC leftover (`m_rvalid_r` / `m_r_hold` / `!r_empty` / AR hold) | that CDC wire | that CDC wire |
| Idle=0, unique bridge leftover, CDC quiet | that bridge wire | that bridge wire |
| Idle=0, independent count ≠ 1 | `AMBIGUOUS` | `NONE` |
| Idle=1, CDC not quiet (AR unwind / lag) | `NONE` | `NONE` (note exploratory; does not hold idle) |

- Unique CDC leftover + idle=0 → H_CANDIDATE **supported**.
- UNIT idle=1 and CDC quiet → H_CANDIDATE **falsified** on this CDC path; H_RIVAL **supported**; leftover is mux/tile only → no C-FIX.
- `XSIM=PASS` iff xvlog/xelab/xsim succeed and probes are recorded (including `NONE`).
- `XSIM=FAIL` iff compile/elab/run fails or probes missing.
- No EXISTENCE. No BOARD_PASS. No `assign r_path_idle=1`.

## Evidence class

`XSIM` only. XSim ≠ board. Dual-clock stub ≠ MIG. Always-ready consumer ≠ tile dest-wait.

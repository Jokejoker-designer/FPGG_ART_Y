# E2R-RPATH-IDLE-CXSIM-INT-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_INTEGRATED_DISPATCH.md` (main)  
**Prior bag:** `E2R-RPATH-IDLE-CXSIM-00` isolated complete-drain named `NONE` — **not** repeated as the only bag  
**Class:** C-XSIM integrated (unit XSim only)  
**Board:** NOT used. No COM12. No program. No bitstream. No `vivado.exe` impl writer.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Isolated bridge C-XSIM: idle=1 after complete drain. Silicon B-FIX/F1w: `RPATH_IDLE=0` at `TILE_DST=4`. |
| UNKNOWN | In the **integrated** native-v1-ab SOA path, after SOA-done (dest-wait analog), which leftover holds `r_path_idle=0`? |
| H_CANDIDATE | Incomplete consumer / leftover `m_axi_rvalid` or `tr_cnt` after SOA while the next owner would wait. |
| H_RIVAL | Second `metric_clear` / boot overlap holds `r_drain_hold` (not a four-wire leftover of the first SOA). |
| FALSIFIER | Integrated snapshot at SOA-done+settle with idle=1 (then silicon leftover is outside this TB) **or** exactly one of the four wires holds. |
| UNIT | One query to SOA-done / dest-wait analog. Not a cycle farm. Not isolated 4-beat complete-drain. |
| CONTROL | Silicon `RPATH_IDLE=0` at `TILE_DST=4`. Isolated C-XSIM idle=1 after complete drain. XSim ≠ board. Stub ≠ MIG. |
| METRICS | XSIM compile+run; four-wire snapshot at UNIT; `metric_clear` pulse count; leave-one-dirty if idle=0; named `WIRE_THAT_HOLDS_IDLE_0`; `C_FIX_CONSTITUENT`. |

## MIG TB bound (declared before run)

`tb_a7ng_native_v1_ab_mig.sv` instantiates the same `a7ng_native_v1_ab_core` but:

- waits MIG `init_calib_complete` then AXI-preload through MIG
- wall timeout `#5000ms` plus LM bind (up to 50e6 UI cycles)
- ties `.r_path_idle_o()`

That is **not** a bounded C-XSIM for dest-wait. This bag does **not** run MIG / `vivado.exe` impl.

## Vehicle (one change)

Fastest integrated TB that still includes the SOA AXI bridge **and** the real consumer (wavefront `r_ready` + termgen + NG02 + global Top-K) and the owner `metric_clear` FSM inside `a7ng_cue_soa_mig_top` (the `u_soa` block of native-v1-ab).

| Item | Value |
|------|-------|
| TB | `tests/xsim/tb_e2r_rpath_idle_cxsim_int_00.sv` |
| DUT | `a7ng_cue_soa_mig_top` + `a7ng_axi_soa_mem_stub` |
| Slave | behavioral AXI stub (not MIG, not isolated always-ready 4-beat slave) |
| Probe | `r_path_idle_o` + hierarchical `r_drain_hold`, `fifo_cnt`, `m_axi_rvalid`, `tr_cnt` |
| Stop | first `soa_done` + 16 clk settle |
| TILE_DST | **not present** in this DUT (no LM dest FSM). **Not faked** as 4. |
| Product RTL | **not edited** |
| Forbidden | `assign r_path_idle=1` absent |

Idle law (frozen DUT, SHA from isolated bag):  
`r_path_idle = !r_drain_hold && (fifo_cnt==0) && !m_axi_rvalid && (tr_cnt==0)`.

`metric_clear` (1-cycle, owner OWN_CLEAR) sets `r_drain_hold<=1` and zeros fifo/tr. Hold releases when `!m_axi_rvalid && fifo==0 && tr==0`.

## Protocol (confirmatory; locked before run)

1. Reset + preload 64-candidate SOA planes via stub `poke128`. Wait `owner_ready`. Snapshot RESET / OWNER_READY.
2. One `start` pulse (one query). Count `metric_clear` pulses.
3. Wait `soa_done` ≤ 200000 clk. If not reached → `XSIM=LIMIT`, dump last snapshot, do not invent TILE_DST=4.
4. **UNIT:** `soa_done` + 16 clk settle. Snapshot four wires + idle + `metric_clear` count + consumer `r_valid`/`r_ready`.
5. If UNIT idle=0: leave-one-dirty isolation (force the other three clean). Independent-holder count names the wire or `AMBIGUOUS`.
6. Mid-query rows (running / first idle=0) are exploratory, not UNIT.

## Decision rule (do not rewrite after peeking)

| UNIT snapshot | `WIRE_THAT_HOLDS_IDLE_0` | `C_FIX_CONSTITUENT` |
|---------------|--------------------------|---------------------|
| Idle=1, dirty_count=0 | `NONE` | `NONE` |
| Idle=0, exactly one independent dirty | that wire | that wire |
| Idle=0, independent count ≠ 1 | `AMBIGUOUS` | `NONE` |
| SOA-done not reached in bound | last observed or `AMBIGUOUS` | `NONE` |

- Unique leftover `m_axi_rvalid` or `tr_cnt` or `fifo_cnt` → H_CANDIDATE **supported** (consumer / orphan / track).
- Unique leftover `r_drain_hold` **and** `metric_clear` count ≥ 2 after start → H_RIVAL **supported**.
- Unique leftover `r_drain_hold` **and** count == 1 → first-clear hold did not release (name `r_drain_hold`; H_RIVAL not uniquely supported).
- UNIT idle=1 → H_CANDIDATE **falsified** on this integrated stub path; H_RIVAL **not observed**; silicon leftover is outside this TB.
- `XSIM=PASS` iff xvlog/xelab/xsim succeed and probes are recorded (including `NONE` / `AMBIGUOUS` / `LIMIT`).
- `XSIM=FAIL` iff compile/elab/run fails or probes missing.
- `XSIM=LIMIT` iff SOA-done not reached in the declared bound (still record last snapshot).
- No EXISTENCE. No BOARD_PASS. No `assign r_path_idle=1`.

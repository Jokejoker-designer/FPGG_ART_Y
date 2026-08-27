# E2R-CDC-AR-XSIM-BOARDSEQ-00 (F1h) — PREREGISTER

**Date:** 2026-08-26  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_F1H_DISPATCH.md` (main repo)  
**Board:** NOT used (observation XSim only; COM12 not touched)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Ideal XSim PASS (F1f); silicon M_ARF without HOLD; F1g `M_RST_LO=NO` `S_RST_LO=NO` |
| UNKNOWN | Does board-accurate reset/boot sequencing prevent AR FIFO drain in the same RTL? |
| H_CANDIDATE | Sequencing (s then m / m then s; AR after both released) loses beat |
| H_RIVAL | Pure silicon (clock stop / XPM silicon err) — board-seq TB still PASS |
| FALSIFIER | TB still sees `s_axi_arvalid` within 50 s_clk after m accept (both orders) |
| UNIT | One AR after sequenced boot |
| CONTROL | F1f ideal TB PASS (simultaneous reset release) |
| METRICS | s_cycles_after_m; saw_s_arv; ar_empty (per order) |

## ONE UNKNOWN

With board-like staggered reset release (s→m and m→s), does one post-release m AR still produce `s_axi_arvalid` within 50 s_clk?

## DUT freeze (observation)

| Item | Value |
|------|-------|
| File | `rtl/board/a7ng_axi_read_cdc.sv` |
| SHA256 | `272026EC609FA51E20DF7293A28AC083DD10EAB65B151A247C65251C9392679F` |
| AR FIFO rst | `!(m_rst_n && s_rst_n)` (asserted until **both** released) |
| Present | `s_axi_arvalid = s_rst_n && !ar_empty` (F1e direct FWFT) |

## Protocol

1. Instantiate only `a7ng_axi_read_cdc` (+ Vivado `xpm` + `glbl`).
2. `m_clk` = 80 ns; `s_clk` = 10 ns.
3. Case A: hold both low → release `s_rst_n` → later release `m_rst_n` → wait → one AR.
4. Case B: hold both low → release `m_rst_n` → later release `s_rst_n` → wait → one AR.
5. **TB PASS** iff both cases see `s_axi_arvalid` within 50 s_clk after m accept; **FAIL** if either order loses the beat.
6. No product RTL edit; no board program.

## Interpretation (post-run)

| TB result | Favored hypothesis | Next |
|-----------|--------------------|------|
| FAIL (either order) | H_CANDIDATE (seq loses beat) | CLOSEOUT may recommend single F1i RTL fix |
| PASS (both orders) | H_RIVAL (pure silicon) | Continue silicon/clock investigation — not CDC seq |

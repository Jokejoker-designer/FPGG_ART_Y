# P2-WDMA-RELEASE-CDC-AUDIT-03 — preregistration (before data)

**PROGRAM=NO.** No COM12 / JTAG / board / Gate14 / Teacher-Off / BOARD_PASS.  
Preserve CDC-CLOSURE-02 bit `D5B725CF44614E6D90EDF997435E6051BE66723037E9B5DE688E799306D22C22` and parent bits `F06C6E84…` / `2E18B144…`. Do not overwrite D5B.

## One unknown

Are the two remaining post-route Critical CDC-10 rows into `u_wdma_rel_sync/meta_reg[0]/[1]` a **synchronizer metadata false-positive** (already-safe 2-FF, only missing ASYNC_REG) **or** an **actual multi-bit / control crossing**?

Evidence order (this bag):

1. Exact start/end/payload from CDC-CLOSURE-02 `report_cdc_details_post.rpt`.
2. Same class on COFIT-00 details (pre-existing).
3. RTL of `async_in` packing and dest AND used to drop `wdma_owner_grant`.
4. Classify. Do **not** add `set_false_path` / extra `set_clock_groups`.
5. If already-safe: prove structure; no RTL; no new bit.
6. If actual unsafe: register combo sources on `ui_clk`, collapse to one AND, request/ack toggle + ASYNC_REG 3-flop; dual-clock randomized unit (reset skew, exactly-once release, stable payload, no premature owner grant); then G1–G5 / AFAST249 / persist AXI/collision/CDC + full P&R. New uniquely named bit only if `candidate_logic` unsafe=0 except documented clock-gen, and route/timing/resource clean.

## Must not

- Edit MIG generated RTL / `.xci`.
- Edit G4 `a7ng_persist_gen_fast.sv` SHA `D1BF0340…`.
- Edit G1 / G2 / G3 / G5 glue / TinyGPT / WMEM / law / persist bridge (unless unused).
- Cover logic CDC with false-path.
- Overwrite bit `D5B725CF…` / `F06C6E84…` / `2E18B144…`.
- Program the board. COM12 still absent.

## Physical gates (same as CDC-CLOSURE-02)

route errors 0. WNS≥0 TNS=0 WHS≥0 THS=0. BRAM36-eq≤135. DSP≤240.  
free<256 RISK. free<64 FAIL.  
`candidate_logic` Critical unsafe = 0 required for a new bit (clock-gen documented falsepath may remain). Persist CDC Critical must stay 0.

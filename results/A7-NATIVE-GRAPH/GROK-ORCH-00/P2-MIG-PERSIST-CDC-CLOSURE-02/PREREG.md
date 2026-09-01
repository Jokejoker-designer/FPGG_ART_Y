# P2-MIG-PERSIST-CDC-CLOSURE-02 — preregistration (before data)

**PROGRAM=NO.** No COM12 / JTAG / board / Gate14 / Teacher-Off / BOARD_PASS.  
Preserve MIG-PERSIST-01 bit `F06C6E846369B30AE721E32758BEB56FE0216106024F05948B7A16B20C482489` and all parent bags / bits (`2E18…` included).

## One unknown

Does the MIG-PERSIST-01 CDC increase (candidate_logic 2→3; `core_clk↔clk_pll_i` Unsafe rows) contain a **persist bridge / persist core↔ui** crossing?

If **yes**: close that persist unsafe with a request-toggle or async-FIFO handshake plus **stable payload** and **ack synchronizer**. Do **not** false-path over logic. Then prove with unit (random phase clocks, reset skew, backpressure, exactly-once write/read/ACK, payload stable) + AXI/collision/G1–G5/AFAST249 + full P&R. New uniquely named bit only if persist CDC unsafe=0 **and** route/timing/resource gates match COFIT/MIG-PERSIST.

If **no**: prove with hierarchy/netlist startpoint/endpoint/net vs COFIT-00. Keep the numeric finding. Do **not** invent a persist RTL change. No new bit unless a persist unsafe was actually closed.

## Must not

- Edit MIG generated RTL / `.xci`.
- Edit G4 `a7ng_persist_gen_fast.sv` SHA `D1BF0340…`.
- Edit G1 / G2 / G3 / G5 glue / TinyGPT / WMEM / law.
- Cover logic CDC with `set_false_path` / `set_clock_groups` as the “fix”.
- Overwrite bit `F06C6E84…` or `2E18B144…`.
- Program the board.

## Physical gates (same as MIG-PERSIST-01 / COFIT-00)

route errors 0. WNS≥0 TNS=0 WHS≥0 THS=0. BRAM36-eq≤135. DSP≤240.  
free<256 RISK. free<64 FAIL.  
Persist CDC unsafe (core↔ui persist hierarchy) = 0 required for a new bit.  
Pre-existing non-persist candidate_logic may remain as FINDING if proven not persist.

## Evidence order

1. Verbose `report_cdc -details` from persist post-route DCP.
2. Same dump from COFIT-00 DCP.
3. Exact startpoint / endpoint / net for each Critical Unsafe.
4. Diff. Classify persist vs not.
5. Only then RTL (if persist).

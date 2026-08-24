# DDR-CUE-SOA-00R-AXI-LIVENESS — repair gate

**TYPE:** repair gate  
**EVIDENCE:** engineering + MIG_XSIM  
**Authority:** human `/GATE` 2026-08-23  
**Supersedes:** `ddr_cue_soa_00` attempt2 ad-hoc retry (transport repair only)

## PURPOSE

Repair the failed AXI transport of `ddr_cue_soa_00` without changing the SOA semantic descriptor, retrieval law, TermGen law, scorer, Top-K law, 01R, 02M, LM06, or TRAIN law.

**ONE UNKNOWN (unchanged):** Can the frozen 104-bit lawful candidate descriptor be delivered using exactly **832 DDR bytes / 64-candidate query**?

Do NOT optimize anything else.

## 0. CURRENT FAILURE

Read:

- `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/CLOSEOUT.md`
- all `xsim_ddr_cue_soa*.log`
- RTL: `a7ng_soa_plane_fetch.sv`, `a7ng_cue_soa_wavefront.sv`, `a7ng_ddr_soa_axi_bridge.sv`, `a7ng_cue_soa_mig_top.sv`
- proven DDR feeder / wavefront AR-R engines

Treat current FAIL as **transport/liveness FAIL**. Do NOT call SOA falsified.

## 1. PROVE FAILURE CLASS

Instrument at AXI boundary:

- `ar_fire = m_axi_arvalid && m_axi_arready`
- `r_fire  = m_axi_rvalid  && m_axi_rready`

Trace bounded around final prior address `0x03000030`: ARVALID, ARREADY, ARADDR, ARLEN, RVALID, RREADY, RLAST, RRESP, `accepted_txns`, `accepted_beat_credit`, `returned_beats`, `outstanding_txns`, `fetch_issued`, `fetch_returned`, `ar_pending_r`, `phase`, `plane`, `fifo_level`.

Classify exactly: **A_DUPLICATE_AR_ACCEPT**, **B_RREADY_DEADLOCK**, **C_R_FIRE_ACCOUNTING**, **D_COMPLETION_FSM**.

Do not infer AXI AR retries from DDR physical command logs.

## 2. FIX AXI WIDTH WARNINGS

Resolve every custom AXI width mismatch (e.g. `s_axi_rresp` actual 1 vs formal 2). Vendor-model warnings documented separately.

## 3. TRANSPORT ARCHITECTURE

Do NOT grow SOA-specific AXI FSM. Reuse proven read transaction engine if compatible; else create generic `a7ng_axi_read_stream`. SOA supplies descriptors `{base_addr, beats, plane_id}` only.

## 4. TRANSACTION PLAN

128-bit AXI = 16 B/beat. 64 candidates × 13 B = **832 B = 52 beats**.

Contiguous INCR bursts: ID 16 beats, CUE 16+16 beats, PRIOR 4 beats → **4 AR transactions**, **52 R beats**, **832 bytes**. Never cross 4-KB burst boundary.

## 5. AXI LAW

AR stable while `ARVALID && !ARREADY`. Only `AR_FIRE` advances descriptor state. R accepted only on `R_FIRE`. No timeout reissue. No global `do_ar/do_r` mutual exclusion.

## 6. R SKID FIFO

2–4 entry 128-bit FIFO: MIG R → skid → SOA unpacker. `m_axi_rready` from registered capacity/FIFO-full only — not combinatorial on phase/plane/raw RVALID/TermGen/TopK/done_o. Record RDATA/RRESP/RLAST on R_FIRE.

## 7. SCOREBOARD

Independent counters: `accepted_txns`, `accepted_beat_credit`, `returned_beats`, `returned_transactions`, `outstanding_transactions`, `unpack_beats`, `candidate_count`. Rules per human spec §7. Invariant: `returned_beats <= accepted_beat_credit`.

## 8. PLANE COMPLETION / DONE

Plane completes only after planned beats accepted, R handshaken, FIFO unpacked. DONE when: `accepted_txns==4`, `accepted_beat_credit==52`, `returned_beats==52`, `unpack_beats==52`, `candidate_count==64`, `outstanding_txns==0`, AR pending 0, R FIFO empty, unpacker idle → pulse `done_o`.

## 9. PRELOAD OWNERSHIP

Audit preload handoff. Owner switch only after BLOCK_NEW / DRAIN_AR / DRAIN_R / outstanding==0 / OWNER_SWITCH. Never switch RREADY mid-transaction.

## 10. PROTOCOL CHECKER

AMD AXI Protocol Checker or equivalent SVA: `pc_asserted==0` for full gate.

## 11. FAST UNIT TEST (engineering only)

Randomized ARREADY/RVALID/RREADY delays + directed last-prior cases. Cannot close gate — MIG XSim required.

## 12. MIG XSIM GATE

Patterns 1 & 2. Marker `A7NG_DDR_CUE_SOA_XSIM_PASS`. `axi_read_bytes/query=832`, `r_beats/query=52`, 64/64 conservation, lawful Top-1, global Top-K vs AOS oracle.

## 13. CONTROL

AOS 1024 B/query control unchanged. Require SOA result == AOS result and 832 < 1024.

## 14. FORBIDDEN

No schema/TermGen/HIT_MAX/01R/02M/LM06/encoder/NPU/BRAM/HS02/board changes. No sleep/delay pass hacks. No host winner/address.

## 15. PASS / FAIL

PASS only if protocol compliant, liveness bounded, 52/52 beats, 832 B/query, 64/64 conservation, AOS==SOA, both patterns, marker observed.

**After closeout: STOP** (no further optimization in same gate).

## 16. Attempt 6 — cs249r dataflow (2026-08-23)

Authority: `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/00R/ATTEMPT6_CS249R_DATAFLOW_PLAN.md`

Implement plane-stationary stage gating (ID→CUE→PRIOR byte credits), §9 preload OWNER_SWITCH, scoreboard byte ledger. MIG must show ID bank0 ARs before PRIOR `0x03000030`.

**Attempt 6 result:** FAIL — plane gates delivered; prior-first unchanged. See `00R/FAILURE_CLASSIFICATION.md` attempt 6 addendum.

## 17. Attempt 7 — clone proven wavefront engine (2026-08-23)

1. Waveform `araddr_f`/`phase`/`id_bcnt` @ first query AR (`126072466 ps`)
2. Replace layered plane_fetch orchestration with `a7ng_cue_wavefront`-class AR/R path (ddr_wavefront_00 PASS)
3. TB AR monitor on first 4 AR addresses vs DDR model
4. Defer `feed_en` until OWNER_SWITCH complete

## 18. Attempt 8 — phase/base-address lock (2026-08-23)

Attempt 7 falsified “clone plane engine alone.” Focus:

1. Waveform/TB probe: `phase`, `pf_base`, `pf_ar_addr` at first AR (`126085966 ps`)
2. Hard lock: no AR until `owner_ready` + `phase==SOA_FETCH_ID` + `pf_base==id_plane_base`
3. A/B: feed-bridge passthrough R on MIG path vs current bridge
4. Audit `metric_clear` / stale R advancing phase before ID AR

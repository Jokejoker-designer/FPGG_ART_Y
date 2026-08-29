# AUDIT — E2R-ATOMIC-DGR-PROBE-00

**Auditor:** `a7-evidence-auditor` (adversarial)  
**Date:** 2026-08-27  
**Gate:** `E2R-ATOMIC-DGR-PROBE-00` (existence side-lane; not `LOOP_STATE.next`)  
**Author claim:** PASS (`a7-vivado-gate`) — ATOM rows captured and decoded  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: 1 FINDING
VERDICT: PASS_NARROW
CLASS=SET: supported
EXISTENCE: NO
BOARD_PASS: not_claimed
```

Gate PASS (rows captured and decoded) is file-backed. This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: 1 FINDING` — MINOR process only. No CRITICAL/MAJOR. Forbidden PASS routes not taken.

---

## Finding

```
[MINOR] DISPATCH_LOG last line is DISPATCHED and omits the side-lane process note
  where     : results/A7-NATIVE-GRAPH/STATUS/DISPATCH_LOG.jsonl:211
  claim      : Native-graph closeout law checks last jsonl `gate` vs LOOP_STATE first OPEN;
               this brief required a process note that the gate is existence side-lane,
               not graph_late_materialize_00
  evidence   : Last line is
               {"ts":"2026-08-27T18:45:30+07:00","gate":"E2R-ATOMIC-DGR-PROBE-00",
                "agent":"a7-vivado-gate","result":"DISPATCHED","board":true,"board_pass":false}
               — no `note`, no PASS result. LOOP_STATE.next / first OPEN remains
               graph_late_materialize_00 (QUEUED, DEFERRED). Sibling E2R C-XSIM
               DISPATCHED lines carried `note":"... not graph_late_materialize_00"`.
               The exemption IS written in E2R_ATOMIC_DGR_PROBE_DISPATCH.md,
               MASTER_PREFLIGHT.md, LOOP_STATE.note, and the STATUS/board closeouts.
  why it matters: A reader of DISPATCH_LOG alone would treat last-line ≠ first-OPEN
               as a dispatch FAIL, or miss that this PASS is not a graph-loop advance.
  fix        : Append one jsonl line:
               gate=E2R-ATOMIC-DGR-PROBE-00, agent=a7-vivado-gate, result=PASS_NARROW,
               board=true, board_pass=false, existence=false,
               note="existence side-lane; not graph_late_materialize_00"
```

This does **not** void the probe PASS. The side-lane exemption is file-backed in STATUS; `agent` matches `a7-vivado-gate`.

---

## Independent re-derivation (headline numbers)

### ATOM pack (preregistered bits)

`0x0000059C` = bits set {2, 3, 4, 7, 8, 10} → dest=4, owner=1, grant=1, idle=0, drain=0, fifo_ne=1, c_rvalid=1, tr_nz=0, mgo=1, hi=0.  
`0x0000059D` = ATOM0 + 1 → dest=5, all other fields unchanged.

Matches `uart_capture.txt` lines `ATOM0=0000059C` / `ATOM1=0000059D`, `CLASSIFICATION.txt`, board `CLOSEOUT.md`, and STATUS seal.

### Timing (Design Timing Summary, not `e2r_metrics.txt` NA)

| Metric | Report | Closeout | Class |
|--------|--------|----------|-------|
| WNS | 0.265 ns | 0.265 ns | EVIDENCE |
| TNS | 0.000 ns | 0.000 ns | EVIDENCE |
| WHS | 0.016 ns (design; `clk_pll_i` intra) | 0.016 ns | EVIDENCE |
| THS | 0.000 ns | 0.000 ns | EVIDENCE |
| core_WNS | 10.582 ns (`core_clk` intra) | 10.582 ns | EVIDENCE |
| ui_WNS | 2.505 ns (`clk_pll_i` intra) | 2.505 ns | EVIDENCE |
| BRAM36 | 103 (post-route hier) | 103 | EVIDENCE |

`e2r_metrics.txt` printed `WNS=NA` (regex miss). Closeout disclosed this and signed off from `report_timing_summary.rpt`. Not a finding.

### Bit / UART SHA

| Artifact | Claimed | Independent SHA256 |
|----------|---------|-------------------|
| `arty_a7_ng_native_v1_atomic_dgr_probe_00.bit` | `77116381…C48EA` | **MATCH** |
| `uart_capture.txt` | `6378125A…E6C9C2` | **MATCH** |
| UART payload bytes | 593 | 593 LF-only; file 658 = 593 + 65 CR |
| CONTROL B-FIX bit | `6023D9A3…28A1` | **MATCH** (board `E2R-WDMA-BFIX-00-EXCL`) |

### Frozen LM-06

| Path | SHA256 | mtime UTC |
|------|--------|-----------|
| main `build/out/arty_a7_lm06.bit` | `67C37DD5…E3BA` MATCH | 2026-08-18 |
| main `build/out/arty_a7_lm06c3.bit` | `222F8043…884C6` MATCH | 2026-08-18 |

Probe bit is a **new** name/SHA. Frozen LM-06 files were not overwritten. Board `build/out/` has no `arty_a7_lm06*.bit` (absent, not replaced).

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| ATOM0=`0000059C` dest=4 owner=1 grant=1 idle=0 fifo_ne=1 c_rvalid=1 mgo=1 | **FACT** | Re-derived from UART hex + pack map |
| ATOM1=`0000059D` dest=5 grant=1 (same leftover pair) | **FACT** | dest+1; fifo_ne/c_rvalid still 1 |
| CLASS=SET (two idle constituents: fifo_ne, c_rvalid) | **FACT** (class rule) | dest=4, idle=0, >1 of {drain,fifo_ne,c_rvalid,tr_nz} high. OCC_400 requires grant=0 — not this query |
| Sequential UART GRANT=0 vs ATOM grant=1 = UART-SKEW **control** | Sequential mismatch = **FACT**; “UART-SKEW” label = **ENGINEERING_INFERENCE** | Supported by prior E2R-UART-SKEW-CXSIM **SKEW** + this ATOM. Not a same-cycle occupancy row |
| Sequential SGO=0 DMA_ST=0 is **not** same-cycle FACT | **FACT** | Present in UART (`DMA_ST=0` `SGO=0`); correctly excluded from class |
| C_FIX=NONE | **FACT** | SOURCE_SHA256, CLASSIFICATION, RTL B1 hold law unchanged; no leftover clear |
| pred=664 absent → EXISTENCE=NO | **FACT** (this capture) | No `pred=` line. Capture script stops at ATOM0+ATOM1; later pred not collected. Existence is **not PASS** either way |
| No LiteScope/ILA in this bit | **FACT** | `BSCANE2` used=0; no `dbg_hub`/`ila`/`litescope` in route reports |
| Frozen LM-06 not overwritten | **FACT** | SHA/mtime above |
| H_CANDIDATE dest=4 grant=0 idle=0 | **not supported** | ATOM0 grant=1 |
| H_RIVAL dest=4 idle=1 | **falsified** | ATOM0 idle=0 |
| Same-cycle pack is core_clk | **FACT** (RTL) | Latch on `core_clk`; hierarchical `u_ab.u_soa.u_br` on `clk`=`core_clk`; `wdma_dbg_mgo` sticky on `m_clk`=`core_clk` |
| n=1 descriptive | **FACT** | One boot query |

Idle-law consistency (not a new measurement):  
`r_path_idle = !drain && fifo_cnt==0 && !c_rvalid && tr_cnt==0`.  
fifo_ne=1 and c_rvalid=1 **require** idle=0. ATOM idle=0 matches. SET names those two leftovers; it does **not** name a single C-FIX wire.

---

## Forbidden PASS routes (searched)

| Route | Result |
|-------|--------|
| Self-declared BOARD_PASS / NATIVE_V1_*_BOARD_PASS | **absent** — `BOARD_PASS=not_claimed` in board CLOSEOUT, CLASSIFICATION, STATUS seal, MASTER_PREFLIGHT |
| Sequential TILE_DST/GRANT/IDLE sold as same-cycle class | **absent** — classified from ATOM rows only |
| C-FIX from SET | **absent** — C_FIX=NONE |
| A2 while ATOM grant=1 | **absent** — A2 not applied; GRANT_STUCK class not met (idle≠1) |
| XSim occupancy sold as board ATOM | **absent** — UART hex is the class source; XSim ≠ board stated |
| Golden/expected edited to match | **absent** — hex printed by FPGA; host only decodes |
| Host winner/answer/pred | **absent** — no pred; probe-only UART |
| H5 / S2 clamp / 01R-02M-LM06 glue onto collapsed encoder | **absent** — not an encoder gate |

---

## Dispatch vs LOOP_STATE (process)

| Item | Value |
|------|--------|
| `LOOP_STATE.next` / first OPEN | `graph_late_materialize_00` QUEUED, `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| DISPATCH_LOG last `gate` | `E2R-ATOMIC-DGR-PROBE-00` |
| last `agent` | `a7-vivado-gate` (matches this probe) |
| last `result` | `DISPATCHED` (no PASS line) |
| last `board_pass` | false |
| Side-lane exemption | Written in DISPATCH.md / MASTER_PREFLIGHT / LOOP_STATE.note / closeouts; **missing on jsonl last line** (MINOR above) |

Do **not** promote this PASS to a `graph_late_materialize_00` close.

---

## CLASS=SET — supported?

**Yes.** Preregistered rule: dest=4, idle=0, >1 leftover constituent high.  
ATOM0: dest=4, idle=0, fifo_ne=1, c_rvalid=1. Exactly two idle-equation constituents.  
OCC_400 / SKEW_IDLE1 / GRANT_STUCK / NO_DST4 do not fit (grant=1, idle=0, dest=4 present).

SET does **not** justify C-FIX or A2. Leftover occupancy is real **and** grant is already 1 — H_CANDIDATE (grant=0 leftover) is not supported.

---

## Existence / BOARD_PASS

| Item | Value |
|------|--------|
| EXISTENCE | **NO** — `pred=664` absent from `uart_capture.txt` |
| BOARD_PASS | **not_claimed** |
| NATIVE_V1_MINI_AI_BOARD_PASS | **not claimed** |
| NATIVE_V1_EXISTENCE_BOARD_PASS | **not claimed** |

---

## NOT VERIFIED

- Live JTAG uniqueness at program time (only `PROGRAM_UART_RESULT.txt` `JTAG=210319BE776EA single_target`).
- Whether a later UART `pred=` would have appeared if capture had continued past ATOM (script stops at ATOM0+ATOM1; file already includes `W_STALL` / `PHASE=01` and still no pred). Existence remains NO on this artifact.
- `unsafe_cdc=0` is the **filtered** `user_unsafe` parser (MIG `c166_raw` false-path Unsafe=1 excluded). Raw CDC Critical rows exist; they are User Ignored. Not used as a silicon-health claim beyond that parser.
- Parent-chat RTL authorship (board worktree probe latch is present; this audit does not reconstruct the Task transcript).
- Replication: n=1. No second query.

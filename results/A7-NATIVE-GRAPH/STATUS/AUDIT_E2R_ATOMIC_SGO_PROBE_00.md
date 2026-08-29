# AUDIT — E2R-ATOMIC-SGO-PROBE-00

**Auditor:** `a7-evidence-auditor` (adversarial)  
**Date:** 2026-08-27  
**Gate:** `E2R-ATOMIC-SGO-PROBE-00` (existence side-lane; not `LOOP_STATE.next`)  
**Author claim:** PASS / CLASS=`SGO_HIT` (`a7-vivado-gate` [76866d70](76866d70-bded-4f08-b56e-4fd25c57b822))  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: 2 FINDINGS
VERDICT: PASS_NARROW
CLASS=SGO_HIT: supported
EXISTENCE: NO
BOARD_PASS: not_claimed
```

Gate PASS (ATOM rows captured and decoded) is file-backed.  
`unsafe_cdc=3` is a FINDING. It does **not** void `SGO_HIT` (class bit is 1-bit `sgo_sticky` / bit7).  
This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: 2 FINDINGS` — both MINOR. No CRITICAL/MAJOR. Forbidden PASS routes not taken. Sequential `SGO=0` / `DMA_ST=0` / `WDMA_OWN_UI=0` is not the class.

---

## Findings

```
[MINOR] unsafe_cdc=3 on clk_pll_i→core_clk (3-bit dma_st sync_bits)
  where     : board report_cdc.rpt:20; e2r_metrics.txt; board CLOSEOUT.md:45;
              STATUS/E2R_ATOMIC_SGO_PROBE_CLOSEOUT.md:16
  claim      : user_unsafe=3 vs F1x same pair Unsafe=0; attributed to requested
               WIDTH=3 dma_st UI→core sync_bits; class bit is sgo_sticky bit7
  evidence   : F1x DGR report_cdc: clk_pll_i→core_clk Warning Safe=52 Unsafe=0.
               This probe: Critical Endpoints=57 Safe=54 Unsafe=3.
               RTL: sync_bits WIDTH=1 for latch/sticky/own_ui; WIDTH=3 for
               wdma_dbg_st. report_cdc.rpt is summary-only (no named endpoints).
               Exclusive build Tcl still treats unsafe_cdc!=0 as GATE_FAIL /
               SKIP_BITSTREAM; bit was written from DCP by a second Tcl that
               does not re-check CDC. dma_st=5 is labeled (R) and is not the class.
  why it matters: A torn 3-bit CDC sample can invent a false dma_st. A reader
               who treats dma_st=5 as same-cycle FACT, or who treats
               e2r_metrics gate_pass=1 as CDC-clean, would over-read occupancy.
  fix        : Keep dma_st as reported-only. Do not use it for class or C-FIX.
               Do not sell gate_pass=1 as unsafe_cdc=0. Next observer that
               needs a safe dma_st must Gray/xpm the 3b bus or sample on ui_clk.
```

This does **not** void `SGO_HIT`. Bit7 is a WIDTH=1 `sync_bits` of sticky `s_go`.

```
[MINOR] DISPATCH_LOG last line is DISPATCHED and has no PASS result
  where     : results/A7-NATIVE-GRAPH/STATUS/DISPATCH_LOG.jsonl:217
  claim      : Native-graph closeout law checks last jsonl `gate` vs LOOP_STATE
               first OPEN; this brief is existence side-lane
  evidence   : Last line is
               {"ts":"2026-08-27T22:25:30+07:00","gate":"E2R-ATOMIC-SGO-PROBE-00",
                "agent":"a7-vivado-gate","result":"DISPATCHED","board":true,
                "board_pass":false,"note":"existence side-lane; not
                graph_late_materialize_00; human plugged board; com12 this gate only"}
               — note is present (better than F1x DGR), but no PASS / CLASS line.
               LOOP_STATE.next / first OPEN remains graph_late_materialize_00
               (QUEUED, DEFERRED).
  why it matters: A reader of DISPATCH_LOG alone cannot see the sealed class
               or that the author PASS is not a graph-loop advance.
  fix        : Append one jsonl line:
               gate=E2R-ATOMIC-SGO-PROBE-00, agent=a7-vivado-gate,
               result=PASS_NARROW, class=SGO_HIT, atom0=00001B9C,
               board=true, board_pass=false, existence=false,
               note="existence side-lane; not graph_late_materialize_00"
```

This does **not** void the probe PASS. `agent` matches `a7-vivado-gate`. Side-lane exemption is written in DISPATCH.md / LOOP_STATE.note / closeouts.

---

## Independent re-derivation (headline numbers)

### ATOM pack (preregistered bits, `[31:13]=0`)

`0x00001B9C` = bits `{2,3,4,7,8,9,10,12}`  
→ dest=4, owner=1, grant=1, idle=0, sgo_latch=0, **sgo_sticky=1**, own_ui=1, dma_st=5, mgo=1, hi=0.

`0x00001B9D` = ATOM0 + 1 → dest=5, all other fields unchanged.

Matches `uart_capture.txt` `ATOM0=00001B9C` / `ATOM1=00001B9D`, live COM12 decode in terminal 76244, `CLASSIFICATION.txt`, `CLASS.txt`, board `CLOSEOUT.md`, and STATUS seal.

First-match class on ATOM0: dest=4 and (bit6 or bit7)=1 → **SGO_HIT**.  
OWN_UI0 / SGO_MISS / SET do not apply (sticky=1; SET needs both SGO=1 and own_ui=0 — `SET_COND=false`).

### UART sequential vs ATOM (same capture)

| Print | UART sequential | ATOM0 | Grade |
|-------|-----------------|-------|-------|
| dest | `TILE_DST=4` | 4 | both FACT; sequential is later print-path |
| SGO | `SGO=0` | latch bit6=0, **sticky bit7=1** | UART `SGO=` is F1u **latch** (`sgo_lat_100` ← `latched_sgo_f1u`). Not live sticky. **FACT** |
| DMA_ST | `DMA_ST=0` | 5 (R) reported | sequential latch CONTROL; ATOM dma_st = unsafe 3b CDC **reported** |
| OWN_UI | `WDMA_OWN_UI=0` | 1 | sequential F1r latch CONTROL; ATOM own_ui is 1-bit sync |
| GRANT | `WDMA_GRANT=0` | 1 | known UART-SKEW vs ATOM (F1x CONTROL) |

RTL (`arty_a7_ng_native_v1_ab_soc_top.sv` msg 60): `SGO=` prints `sgo_lat_100`, not `wdma_dbg_sgo`.  
ATOM bit7 prints `atom_sgo_sticky_core` ← `sync_bits(wdma_dbg_sgo)`.  
Latch=0 and sticky=1 in the same ATOM0 word is internally consistent with that split. Sequential `SGO=0` must not be the class row — it was not.

### Timing / util (Design Timing Summary + Intra Clock Table)

| Metric | Report | Closeout | Class |
|--------|--------|----------|-------|
| WNS | 0.406 ns (line 141) | 0.406 ns | EVIDENCE |
| TNS | 0.000 ns | 0.000 ns | EVIDENCE |
| WHS | 0.021 ns | 0.021 ns | EVIDENCE |
| THS | 0.000 ns | 0.000 ns | EVIDENCE |
| core_WNS | 8.796 ns (`core_clk` intra) | 8.796 ns | EVIDENCE |
| ui_WNS | 1.709 ns (`clk_pll_i` intra) | 1.709 ns | EVIDENCE |
| BRAM36 | 103 (post-route) | 103 | EVIDENCE |
| LUT / FF / DSP | 55269 / 56725 / 19 | same | EVIDENCE |
| Route | 102569/102569, 0 errors | same | EVIDENCE |
| BSCANE2 | 0 | no ILA | EVIDENCE |

Reports are pre-regex-abort (23:19) / DCP (23:20). Bit from that DCP (23:45). Timing numbers are not from a later re-route.

### Bit / program / UART SHA

| Artifact | Claimed | Independent |
|----------|---------|-------------|
| `arty_a7_ng_native_v1_atomic_sgo_probe_00.bit` | `832E55E2…6385D2` | **MATCH** (3826011 B, 23:45:23) |
| `BIT_SHA256.txt` | same | **MATCH** |
| write Tcl `BIT_OK` (terminal 76243) | same | **MATCH** |
| UART payload bytes | 593 | 593 LF-only; file 658 = 593 + 65 CR |
| CONTROL F1x bit | `77116381…C48EA` | **MATCH** (unchanged mtime 19:59) |
| SoC RTL SHA | `98537190…A6CEA9` | **MATCH** `SOURCE_SHA256.txt` |
| `a7ng_wdma_cdc.sv` | `FE13D1BB…BF92D7` | **MATCH** |

### First exclusive abort, then DCP bit — still file-backed?

**Yes.**

1. Exclusive `build_e2r_atomic_sgo_probe_00_excl.tcl` routed, wrote `e2r_post_route.dcp` + timing/CDC reports, then died on Vivado Tcl `regexp {…[\s\S]…}` (`vivado_46952.backup.log:3606–3616`, exit 23:20:17). That abort is **before** `write_bitstream`, not a failed bitgen of a different netlist.
2. DCP `write_bitstream` #1 failed NSTD-1/UCIO-1 on unconstrained `ja[7:0]` (terminal 76241).
3. DCP `write_bitstream` #2 (after post-route `read_xdc` ja) failed RTSTAT partial route (terminal 76242).
4. DCP `write_bitstream` #3 waived ja-only NSTD-1/UCIO-1, no ja XDC re-read: `write_bitstream completed successfully`, `BIT_OK` SHA `832E55E2…` (terminal 76243). F1x exclusive list also omitted `e2r_la_pmod_ja.xdc`. `BSCANE2=0`.
5. COM12 armed 23:51:25 (terminal 76244) **before** program 23:51:43. JTAG `HW_TARGETS=localhost:3121/xilinx_tcf/Digilent/210319BE776EA` only. `E2R_ATOMIC_SGO_PROBE_00_EXCL_PROGRAM_PASS` of the SHA-matched path. `PROGRAM_EXIT=0`.

SHA and program bind to the on-disk bit written from the routed DCP. Not a paper SHA.

### Frozen LM-06

| Path | SHA256 | mtime |
|------|--------|-------|
| main `build/out/arty_a7_lm06.bit` | `67C37DD5…E3BA` MATCH | 2026-08-18 |
| main `build/out/arty_a7_lm06c3.bit` | `222F8043…884C6` MATCH | 2026-08-18 |

Probe bit is a **new** name/SHA. F1x `77116381…` not overwritten.

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| ATOM0=`00001B9C` dest=4 owner=1 grant=1 idle=0 latch=0 sticky=1 own_ui=1 mgo=1 | **FACT** | Re-derived from UART hex + pack map |
| ATOM1=`00001B9D` dest=5 (next core cycle) | **FACT** | dest+1; sticky stays 1 |
| CLASS=`SGO_HIT` (bit7) | **FACT** (class rule) | dest=4 and bit7=1. First match. |
| Sequential `SGO=0` is latch, not sticky | **FACT** | RTL print vs ATOM bit6/bit7 |
| Sequential `SGO=0` `DMA_ST=0` `OWN_UI=0` is CONTROL, not class | **FACT** | Present in UART; excluded from class |
| dma_st=5 (R) | **reported field** / ENGINEERING_INFERENCE | Enum R=5 is correct **if** bits intact; 3-bit CDC is Unsafe |
| H_CANDIDATE `SGO_MISS` | **not supported** | sticky=1 |
| H_RIVAL `SGO_HIT` | **supported** (this unit) | dest=4 ∧ synced sticky=1. Means sticky was already 1 at first dest=4∧owner, not that `s_go` rose on that exact cycle |
| C_FIX=NONE | **FACT** | SOURCE_SHA256, CLASS, RTL B1 hold law unchanged |
| pred=664 absent → EXISTENCE=NO | **FACT** (this capture) | No `pred=` line. Script stops at ATOM0+ATOM1; file has `W_STALL` / `PHASE=01` |
| No LiteScope/ILA | **FACT** | BSCANE2=0; ja waived, not an ILA core |
| Frozen LM-06 / F1x not overwritten | **FACT** | SHA/mtime above |
| n=1 descriptive | **FACT** | One boot query |
| BOARD_PASS not claimed | **FACT** | board CLOSEOUT, CLASS.txt, STATUS seal, MASTER_PREFLIGHT |

`s_go_sticky` clears only on `s_rst_n` (`a7ng_wdma_cdc.sv`). It is the WDMA CDC `s_go`, not `u_wmem_boot`. Combined with dest=4∧owner and own_ui=1, this is the query WDMA path — still n=1, still not existence.

---

## Forbidden PASS routes (searched)

| Route | Result |
|-------|--------|
| Self-declared BOARD_PASS / NATIVE_V1_*_BOARD_PASS | **absent** |
| Sequential SGO/DMA/OWN_UI sold as class | **absent** — ATOM rows only |
| C-FIX / A2 / force dest / LiteScope | **absent** |
| XSim occupancy sold as board ATOM | **absent** — UART hex is the class source |
| Golden/expected edited to match | **absent** — FPGA printed hex; host only decodes |
| Host winner/answer/pred | **absent** — no pred |
| H5 / S2 clamp / 01R-02M-LM06 glue | **absent** |
| F1x / frozen LM-06 overwrite | **absent** |
| `graph_late_materialize_00` promoted | **absent** — DEFERRED |

---

## Dispatch vs LOOP_STATE (process)

| Item | Value |
|------|--------|
| `LOOP_STATE.next` / first OPEN | `graph_late_materialize_00` QUEUED, `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| DISPATCH_LOG last `gate` | `E2R-ATOMIC-SGO-PROBE-00` |
| last `agent` | `a7-vivado-gate` (matches pipeline `character_id` and Task) |
| last `result` | `DISPATCHED` (no PASS line) — MINOR above |
| last `board_pass` | false |
| last `note` | existence side-lane; not `graph_late_materialize_00` |

Do **not** promote this PASS to a `graph_late_materialize_00` close.

---

## CLASS=SGO_HIT — supported?

**Yes.** Preregistered rule: dest=4 and (bit6 or bit7)=1.  
ATOM0 dest=4, bit7=`sgo_sticky` synced=1.  
Sequential `SGO=0` is the F1u latch print (bit6=0), not occupancy.

`unsafe_cdc=3` does **not** falsify bit7. It limits `dma_st=5` to a reported field.

---

## Existence / BOARD_PASS

| Item | Value |
|------|--------|
| EXISTENCE | **NO** — `pred=664` absent from `uart_capture.txt` |
| BOARD_PASS | **not_claimed** |
| NATIVE_V1_MINI_AI_BOARD_PASS | **not claimed** |
| NATIVE_V1_EXISTENCE_BOARD_PASS | **not claimed** |
| C_FIX | **NONE** |

---

## NOT VERIFIED

- Live JTAG uniqueness at program time beyond `PROGRAM_UART_RESULT.txt` / terminal 76245 `HW_TARGETS=…210319BE776EA` (single target printed).
- Named CDC endpoints for the 3 Unsafe bits (`report_cdc.rpt` has no details section). Attribution to `u_atom_dma_st_core` is ENGINEERING_INFERENCE from RTL WIDTH=3 vs F1x Unsafe=0.
- Whether a later UART `pred=` would have appeared if capture continued past ATOM (script stops at ATOM0+ATOM1; file already includes `W_STALL` / `PHASE=01` and still no pred). Existence remains NO.
- Replication: n=1. No second query.
- Whether `s_go` rose on the dest=4 cycle vs earlier in the same boot after `s_rst_n` (sticky, not a pulse). Class does not require the rise cycle.

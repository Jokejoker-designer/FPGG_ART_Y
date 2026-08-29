# AUDIT — E2R-ATOMIC-SDONE-PROBE-00 (BUILD_PASS only)

**Auditor:** `a7-evidence-auditor` (adversarial)  
**Date:** 2026-08-28  
**Gate:** `E2R-ATOMIC-SDONE-PROBE-00` (existence side-lane; not `LOOP_STATE.next`)  
**Author claim:** `BUILD_PASS` · `PROGRAM=NO` (`a7-vivado-gate`)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
SCOPE: BUILD_PASS only (PROGRAM=NO)
UNKNOWN: not answered
EXISTENCE: NO
BOARD_PASS: not_claimed
C_FIX: NONE
```

`BUILD_PASS` is file-backed (bit SHA + post-route WNS/TNS).  
This is **not** silicon class, **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR that would change the BUILD_PASS claim.  
Forbidden PASS routes not taken. Packed s_done UNKNOWN remains open.

---

## Independent re-derivation (headline numbers)

### Bit SHA

| Artifact | Claimed | Independent |
|----------|---------|-------------|
| `arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` | **MATCH** (Get-FileHash SHA256; 3826011 B; 2026-08-28 01:55:44) |
| `BIT_SHA256.txt` | same | **MATCH** |
| `e2r_metrics.txt` / DISPATCH_LOG `BUILD_PASS` | same | **MATCH** |
| `vivado_excl.log` | `write_bitstream completed successfully` | **FACT** — no `program_device` / `open_hw_manager` / `hw_server` |

Bit is a **new** name/SHA. Not a paper hash.

### Timing (post-route, not synth)

`report_timing_summary.rpt` header: **Design State : Physopt postRoute** (2026-08-28 01:54:43).  
Synth util report is a different file (`report_utilization.rpt`, Design State : Synthesized, LUT 56240). Closeout numbers match the **post-route** Design Timing Summary + Intra Clock Table, not the synth estimate.

| Metric | Report (re-read) | Closeout | Class |
|--------|------------------|----------|-------|
| WNS | 0.372 ns (Design Timing Summary line 141) | 0.372 ns | EVIDENCE |
| TNS | 0.000 ns | 0.000 ns | EVIDENCE |
| WHS | 0.013 ns | 0.013 ns | EVIDENCE |
| THS | 0.000 ns | 0.000 ns | EVIDENCE |
| core_WNS | 9.354 ns (`core_clk` intra) | 9.354 ns | EVIDENCE |
| core_TNS | 0.000 ns | 0.000 ns | EVIDENCE |
| ui_WNS | 1.276 ns (`clk_pll_i` intra) | 1.276 ns | EVIDENCE |
| ui_TNS | 0.000 ns | 0.000 ns | EVIDENCE |
| BRAM36 | 103 (post-route util) | 103 | EVIDENCE |
| LUT / FF | 55264 / 56713 (post-route) | same | EVIDENCE |
| DSP | 19 (post-route SoC) | 19, labelled SoC not encoder DSP=0 | EVIDENCE |
| Route | 102555/102555 nets, 0 errors | same | EVIDENCE |
| Constraints | "All user specified timing constraints are met." | claimed | EVIDENCE |
| BSCANE2 | 0 | no ILA / LiteScope | EVIDENCE |

Chip WNS 0.372 is the **default** path-group on `clk_pll_i` (1 endpoint), not a synth estimate and not the intra-clock 1.276 ns.

### CDC grade (`report_cdc.rpt`, Design State : Physopt postRoute)

| Pair | This run | SGO CONTROL (`E2R-ATOMIC-SGO-PROBE-00`) |
|------|----------|----------------------------------------|
| `clk_pll_i` → `core_clk` | Warning · Endpoints=53 · Safe=53 · **Unsafe=0** · No ASYNC_REG=4 | Critical · Endpoints=57 · Safe=54 · **Unsafe=3** · No ASYNC_REG=8 |

Tcl `e2r_parse_unsafe_cdc` counts user-unsafe only; MIG `c166_raw` False-Path Critical rows (clk_div2 / clk_pll_i / mmcm_ps) are excluded as `mig_benign`. That scoped `unsafe_cdc=0` **matches** the `clk_pll_i→core_clk` row.

**Grade:** prior 3-unsafe FINDING was the packed 3-bit `dma_st` UI→core sync. This pack does **not** include `dma_st`. New crossings are WIDTH=1 `sync_bits` (`ASYNC_REG` on `meta`) for `latched_sdone_f1t` and `wdma_dbg_sdone`. Claim "FINDING none on new 1-bit s_done syncs" is supported for **Unsafe=0** on that pair.

Residual **No ASYNC_REG=4** on the same pair is leftover sequential UART probes (F1t/F1u still sync `latched_dma_st_f1u`), not the ATOM pack. Not a BUILD_PASS void. Not sold as chip-wide CDC-clean.

### ATOM pack (RTL, not silicon)

`atom_now` = `{21'd0, mgo, core_done, w_stall, sticky_sync, latch_sync, idle, grant, owner, dest[2:0]}`.  
No `[11:9] dma_st`. Trigger unchanged: first `dest==4 && owner`, then next core cycle. **EVIDENCE** (RTL). No UART hex this run — pack is **not** a silicon answer.

### PROGRAM=NO

| Check | Result |
|-------|--------|
| `BRIDGE.json` `board.com12_authorized_gate` | **`E2R-ATOMIC-SGO-PROBE-00`** (consumed; not this id) |
| UART / CLASS / `PROGRAM_UART_RESULT` in this archive | **absent** |
| Vivado log program / hw_server | **absent** |
| Closeout CLASS | `not classified (no UART this run)` |
| Sequential `SDONE=` sold as class | **absent** |

### Frozen artifacts (independent SHA + mtime)

| Path | SHA256 | mtime | Grade |
|------|--------|-------|-------|
| SGO `…/E2R-ATOMIC-SGO-PROBE-00/arty_a7_ng_native_v1_atomic_sgo_probe_00.bit` | `832E55E26232B4F2A5D84199EB86AEA1C7EBEEFEF30E51842BC44D8BB16385D2` | 2026-08-27 23:45:23 | **unchanged** |
| F1x DGR `…/E2R-ATOMIC-DGR-PROBE-00/arty_a7_ng_native_v1_atomic_dgr_probe_00.bit` | `771163814B6914CECB872839A36BD95ED0249E839038E16C46D48755E66C48EA` | 2026-08-27 19:59:09 | **unchanged** |
| main `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F8…E3BA` | 2026-08-18 | **unchanged** |
| main `build/out/arty_a7_eam01r.bit` | `57D1DF1B…F6CF` | 2026-08-19 | **unchanged** |
| main `build/out/arty_a7_eam02m.bit` | `DB3BC58A…E696` | 2026-08-19 | **unchanged** |
| main `build/out/arty_a7_eam03e_a03.bit` | `05E478FF…EC09` | 2026-08-20 | **unchanged** |
| SoC RTL `arty_a7_ng_native_v1_ab_soc_top.sv` | `8298376E…A2CF0` | matches `SOURCE_SHA256.txt` | **MATCH** |
| `rtl/board/a7ng_wdma_cdc.sv` | `FE13D1BB…BF92D7` | matches `SOURCE_SHA256.txt` | **MATCH** (C_FIX NONE) |

Exclusive Tcl refuses overwrite of SGO / F1x / `*lm06*.bit` paths. JA `e2r_la_pmod_ja.xdc` omitted. No `[\s\S]`.

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| BUILD_PASS (exclusive bit, WNS≥0 TNS=0) | **FACT** | SHA + post-route summary |
| PROGRAM=NO | **FACT** | authorize still SGO; no UART/JTAG in this archive |
| UNKNOWN (packed s_done at dest=4∧owner) **not answered** | **FACT** | no ATOM rows |
| C_FIX=NONE / no A2 / no LiteScope | **FACT** | SOURCE SHA, BSCANE2=0, ja xdc omitted |
| BOARD_PASS / EXISTENCE / pred=664 | **not claimed** / **NO** | explicit |
| DSP=19 | **FACT** (SoC util) | not an encoder DSP=0 gate |
| `clk_pll_i→core_clk` Unsafe=0 (1-bit s_done syncs) | **FACT** | vs SGO Unsafe=3 |
| 3-bit `dma_st` not in ATOM pack | **FACT** | RTL `atom_now` |
| Frozen LM-06 / 01R / 02M / A0.3 / SGO `832E55E2…` not overwritten | **FACT** | SHA + mtime |
| H_CANDIDATE / H_RIVAL | **not tested** | PROGRAM=NO |

---

## Forbidden PASS routes (searched)

| Route | Result |
|-------|--------|
| Self-declared BOARD_PASS / NATIVE_V1_*_BOARD_PASS | **absent** |
| UART class / sequential `SDONE=` sold as silicon answer | **absent** |
| JTAG program sold as this gate's silicon | **absent** — authorize still SGO |
| C-FIX / A2 / force dest / LiteScope | **absent** |
| XSim occupancy sold as board ATOM | **absent** |
| Golden/expected edited to match | **absent** — no class rows |
| Host winner/answer/pred | **absent** |
| H5 / S2 clamp / 01R-02M-LM06 glue | **absent** |
| SGO / F1x / frozen LM-06 overwrite | **absent** |
| `graph_late_materialize_00` promoted | **absent** — DEFERRED |

---

## Dispatch vs LOOP_STATE (process)

| Item | Value |
|------|--------|
| `LOOP_STATE.next` / first OPEN | `graph_late_materialize_00` QUEUED, DEFERRED (`EXISTENCE_BEFORE_QUALITY`) |
| DISPATCH_LOG last `gate` | `E2R-ATOMIC-SDONE-PROBE-00` |
| last `agent` | `a7-vivado-gate` |
| last `result` | `BUILD_PASS` (SHA `9DC0F8DF…`, `program=false`, `existence=false`, `board_pass=false`) |
| last `note` | existence side-lane; not `graph_late_materialize_00` |

Side-lane exemption is written. Do **not** treat last-gate ≠ `graph_late_materialize_00` as a FAIL.

---

## Existence / BOARD_PASS

| Item | Value |
|------|--------|
| EXISTENCE | **NO** — `pred=664` not measured |
| BOARD_PASS | **not_claimed** |
| NATIVE_V1_MINI_AI_BOARD_PASS | **not claimed** |
| NATIVE_V1_EXISTENCE_BOARD_PASS | **not claimed** |
| C_FIX | **NONE** |
| NEXT | COM12 program only when `com12_authorized_gate=E2R-ATOMIC-SDONE-PROBE-00`. Do not reprogram SGO `832E55E2…`. |

---

## NOT VERIFIED

- Named CDC endpoints for the residual 4 No-ASYNC_REG on `clk_pll_i→core_clk` (`report_cdc.rpt` is summary-only). Attribution to leftover F1 sequential `dma_st` probes is ENGINEERING_INFERENCE.
- Whether a later COM12 program of this SHA would print `ATOM0=` / `ATOM1=` or `pred=664`. Existence remains NO until that capture.
- Live JTAG uniqueness — not applicable (PROGRAM=NO).
- Task-vs-parent authorship of the `soc_top` pack edit beyond DISPATCH_LOG `agent=a7-vivado-gate` and board-tree SHA match.

**Stop:** do not program on leftover SGO authorize. Do not classify silicon. Do not promote BUILD_PASS to existence or BOARD_PASS.

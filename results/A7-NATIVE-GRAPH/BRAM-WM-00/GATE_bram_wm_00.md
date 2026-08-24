# GATE: bram_wm_00 (A7-BRAM-WM-00)

**Agent:** `a7-ng-memory-arch`  
**Evidence class:** XSIM (+ OOC util if present)  
**Marker:** `A7NG_BRAM_WM00_XSIM_PASS`  
**Date:** 2026-08-22  
**Law id:** `a7ng-bram-wm00-v0`

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | schema frozen; LM+graph naive BRAM still 135/135; WM concept not proven independent of LM-06 |
| UNKNOWN | can A7-BRAM-WM-00 (256 cand / 64 frontier / Top-8 evidence / 32 learning updates / 16 PE iface / synthetic DDR) meet lossless+measurable util without instantiating LM-06? |
| H_CANDIDATE | shared BRAM WM proves correct/lossless/bankable without LM (spec §33) |
| H_RIVAL | silent overwrite / dual owner / BRAM>headroom without LM still fails HS-11 style |
| FALSIFIER | DROP>0 on capacity bags; dual-write accepted; BRAM report exceeds device if claimed; LM-06 bit touched |
| UNIT | query/seed WM bag — not cycles-as-queries |
| CONTROL | frozen LM-06/01R/02M/A0.3 SHAs MATCH; mem_schema_v1 SHA F0FE426E… MATCH |
| METRICS | lane util (16 PE grants); DROP counted not silent; DDR bytes/query; lm_grant=0; OOC LUT/FF/BRAM/DSP/WNS if routed |

## Verdict

**PASS (engineering / XSIM).** H_CANDIDATE supported for this gate: WM bags are lossless under capacity, overflow is counted (not silent), dual-owner is rejected, Top-8 exact, mem_schema_v1 NodeRecordV1 used, 16 PE grants measured, **no LM-06**.

H_RIVAL (silent overwrite / dual owner accepted / LM touch) **falsified** under these bags.

`XSIM ≠ BOARD`. No BOARD_PASS. Not `BRAM_WORKING_MEMORY_ARCH_PASS` (§45 full list) — that needs post-route ownership sharing + integrate later.

## CHANGED

| Path | Role |
|------|------|
| `rtl/native_graph/memory/a7ng_wm00_cand_buf.sv` | NEW — 256 cand LUTRAM; DROP on full |
| `rtl/native_graph/memory/a7ng_wm00_frontier.sv` | NEW — 64 frontier LUTRAM |
| `rtl/native_graph/memory/a7ng_wm00_evidence.sv` | NEW — exact Top-8 |
| `rtl/native_graph/memory/a7ng_wm00_learn_upd.sv` | NEW — 32 coalesce + DDR drain |
| `rtl/native_graph/memory/a7ng_wm00_synth_ddr.sv` | NEW — mem_schema_v1 Node/Edge store |
| `rtl/native_graph/memory/a7ng_wm00_owner.sv` | NEW — single owner; LM never granted |
| `rtl/native_graph/memory/a7ng_wm00_pe_iface.sv` | NEW — 16 PE pull iface + util |
| `rtl/native_graph/memory/a7ng_wm00_top.sv` | NEW — glue |
| `tests/xsim/tb_a7ng_wm00.sv` | NEW — 8 bags |
| `tests/xsim/run_a7ng_wm00.tcl` | NEW |
| `docs/native_graph/RESOURCE_BUDGET.md` | WM-00 measured table |
| `docs/native_graph/TEST_MATRIX.md` | WM-00 rows |

**NOT changed:** LM-06/01R/02M/A0.3 bits; TermGen; TRAIN-V2; HNSW; integrate_fit; PE>16; mem_schema_v1 layout.

## TESTS

| ID | Result |
|----|--------|
| FILL256 | PASS count=256 DROP=0 ddr_rd_bytes=4096 |
| OVERFLOW | PASS DROP=1 count stays 256 (not silent) |
| FRONTIER | PASS count=64 DROP on 65th |
| TOP8 | PASS nodes/scores 31..24 |
| LEARN | PASS 32 + coalesce=1 + DDR wr bytes=512 |
| 16PE | PASS grants=16 lm_grant=0 |
| DUAL_OWNER | PASS dual_err sticky |
| SCHEMA | PASS NodeRecordV1 version=1 |
| Frozen SHA | MATCH all four + mem_schema F0FE426E… |

## SHA256 (primary)

`1F7F39506DF0D0F21F0F7E60B658047AE38ACB11E5B0924E005413B2B8B8AD98  a7ng_wm00_top.sv`  
(full list: `SHA256.txt`)

## OOC util / timing (measured — not silicon)

| Resource | Post-route | Device | % |
|----------|----------:|-------:|--:|
| LUT | 10238 | 63400 | 16.15 |
| FF | 7359 | 126800 | 5.80 |
| BRAM | **0** | 135 | 0.00 |
| DSP | 0 | 240 | 0.00 |
| WNS @100 MHz | **−290.499 ns** | — | FAIL (comb Top-8; not claimed PASS) |
| TNS | −108584.445 | — | FAIL |

BRAM=0 falsifies H_RIVAL “BRAM>headroom without LM”. Timing FAIL is archived honestly; §45 item 8 not claimed this gate.

## NEXT

Parent verify trio / `--dispatch`. Likely `ddr_feed` (WM-01). No BOARD_PASS.

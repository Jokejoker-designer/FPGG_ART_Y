# A7-BRAM-WM-00 closeout

**Gate:** `bram_wm_00`  
**Marker:** `A7NG_BRAM_WM00_XSIM_PASS`  
**Agent:** `a7-ng-memory-arch`  
**Evidence_class:** XSIM + OOC_UTIL (timing measured, not claimed PASS @100 MHz)

## UNKNOWN resolution

| Item | Result |
|------|--------|
| H_CANDIDATE (WM lossless/bankable without LM) | **Supported** (XSim bags) |
| H_RIVAL (silent overwrite / dual owner / LM touch) | **Falsified** |
| BRAM tiles (OOC route) | **0 / 135** — does not exceed device; no LM-06 competition |
| LM-06 bit | **untouched** MATCH |
| 100 MHz OOC WNS | **−290.499 ns** (FAIL) — comb Top-8 insert; **not** claimed as timing PASS; pipeline deferred |

## Key metrics (file-backed)

```text
FILL256: count=256 DROP=0 ddr_rd_bytes=4096
OVERFLOW: DROP=1 (counted, not silent)
FRONTIER: count=64 DROP on 65th
TOP8: nodes/scores 31..24 exact
LEARN: 32 entries coalesce=1 ddr_wr_bytes=512
16PE: grants=16 lm_grant=0
DUAL: dual_owner_err sticky
SCHEMA: NodeRecordV1 version=1
OOC route: LUT=10238 FF=7359 BRAM=0 DSP=0
OOC timing @10ns: WNS=-290.499 TNS=-108584.445 (FAIL — measured)
```

## Artifacts

- `GATE_bram_wm_00.md`
- `xsim_wm00.log` / `xvlog_wm00.log` / `xelab_wm00.log`
- `util_route.rpt` / `timing_route.rpt` / `util_synth.rpt`
- `frozen_sha_control.txt` / `SHA256.txt`
- `run_wm00_ooc.tcl`

## Out of scope (held)

TermGen, TRAIN-V2, HNSW, integrate_fit, LM-06 phase-share (WM-02/03), PE>16, BOARD_PASS, §45 full `BRAM_WORKING_MEMORY_ARCH_PASS`.

## NEXT

Parent verify / `--dispatch`. Candidate next: `ddr_feed` (WM-01 ping-pong) or timing pipeline before integrate.

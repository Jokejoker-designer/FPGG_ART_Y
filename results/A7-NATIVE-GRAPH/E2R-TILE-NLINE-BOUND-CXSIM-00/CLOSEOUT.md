# E2R-TILE-NLINE-BOUND-CXSIM-00 — CLOSEOUT

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_NLINE_BOUND_CXSIM_DISPATCH.md`  
**Claim scope:** Tile-only one-region nline bound — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No** (`C_FIX=NONE`)  
**Forbidden bypass:** not used (no leftover grant bags; `SIM_FULL=0`; stub completes every `dma_go`; did not stop at dest4_2; mid-refill stall=1 not treated as stuck)

XSim ≠ board. Silicon ATOM1 dest=5 then 300 s no `CORE_DONE` is not this bag.  
Silicon time (nline × MIG ms/chunk) is ENGINEERING_INFERENCE only (stub ≠ MIG).

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Chunk 1 then chunk 2 start on completable stub. Silicon first-chunk SDONE then 300 s no `CORE_DONE`. `rg_nline`: POS `rg==1` → 128 else 1024. ~20 min refill is ENGINEERING_INFERENCE. |
| UNKNOWN | on this same miss, does one region refill reach `stall=0`, and how many dest=4 / `dma_go` bursts? |
| H_CANDIDATE | `STALL_HOLD` — timeout still `stall=1` |
| H_RIVAL | `REGION_DONE` — `stall=0` and dest4_cnt == nline |
| FALSIFIER | stop at chunk 2; hold busy after first done; `SIM_FULL=1`; leftover grant; C-FIX; treat mid-refill stall=1 as stuck |
| UNIT | one miss, one region (not clock-as-query) |
| CONTROL | CHUNK2_GO dest4_2 at cyc=304 stall=1; `rg_nline` law |
| METRICS | dest4_cnt, dma_go bursts, dest-clk to stall=0, nline, bst at end |

## Vehicle (TB-only)

Copy of `tb_e2r_tile_next_chunk_cxsim_00.sv`. **One change:** do not stop at second dest=4. Completable stub for **every** `dma_go` (8 R + done + busy clear; return `ST_IDLE`). Watch until `stall==0` **or** timeout **1000000** dest-clk. Count rising dest==4 and `dma_go` bursts. Print measured `nline_h`. Do not require `stall=0` as a pass bit.

`weight_tile803k` `#(.SIM_FULL(0))` TILE generate only. Same clk for `clk` and `clk_dma`. After reset, `addr_a=OFF_POS` (131072). `we_a=0`.

## UNIT snaps

| Snap | cyc | dest | bst | stall | dest4 | burst | notes |
|------|-----|------|-----|-------|-------|-------|-------|
| first `dma_go` burst | 7 | 1 | 4 | 1 | 0 | 1 | hold_rg=1 `nline_h=128` |
| first `D_WAITDONE` | 18 | **4** | 4 | 1 | 1 | 1 | CONTROL match |
| first `D_ACK` | 20 | **5** | 4 | 1 | 1 | 1 | not a stop |
| dest idle after ACK | 28 | **0** | 5 | 1 | 1 | 1 | dest left 5 |
| second burst / dest4_2 | 293 / **304** | 1 / **4** | 4 | **1** | 2 | 2 | CONTROL CHUNK2_GO exact |
| dest4=32 / 64 / 96 | 8884 / 18036 / 27188 | 4 | 4 | 1 | … | … | mid-refill stall=1 (not stuck) |
| dest4=128 | 36340 | **4** | 4 | 1 | **128** | **128** | last chunk `ch=127` |
| stall=0 | **36610** | 0 | **0** | **0** | 128 | 128 | `cur_rg=1` `bst=B_IDLE` |

Timeout cap 1000000 unused (`$finish` at 366215 ns / cyc=36610).  
`dma_go` high-cycles=384 = 128 bursts × 3 dest-clk. Rising dest==4 count = burst count = measured nline.

Measured nline: `nline_h=128`, `hold_rg=1` (POS), `NLINE_LAW_HOLD=128`. Dispatch note that OFF_POS + `cur_rg_reset=0` might yield 1024 is **not** what this vehicle measured: `nline_h` uses `hold_rg` on a clean refill (`is_flush=0`), and `rg_of(OFF_POS)=1`.

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-TILE-NLINE-BOUND-CXSIM-00** |
| XSIM | **PASS** (`E2R_TILE_NLINE_BOUND_CXSIM_00_XSIM_PASS`) |
| CLASS | **REGION_DONE** |
| DEST4_CNT | **128** |
| DMA_GO bursts | **128** |
| NLINE | **128** (measured) |
| STALL0_CYC | **36610** |
| STALL_END | **0** |
| BST_END | **0** (`B_IDLE`) |
| DEST4_2 | cyc=**304** stall=**1** (CONTROL) |
| C_FIX | **NONE** |
| H_CANDIDATE | **falsified** on this tile+completable-stub vehicle (`stall=0`, dest4_cnt == nline) |
| H_RIVAL | **supported** on this vehicle |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| PROGRAM | **NO** |

n = 1 tile miss, one POS region (one UNIT). Descriptive class only. Not a cycle farm. No inferential test.

## Evidence quotes (`xsim.log`)

```text
VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB_EVERY_GO
MISS_FORCE addr_a=OFF_POS(131072) cur_rg_reset=0 we_a=0
RG_NLINE_LAW POS_rg1=128 else=1024
WATCH until stall==0 OR timeout; TO_CYC=1000000; do not stop at dest4_2; stall=0 not required
SNAP_D4_2 cyc=304 dest=4 dbg_dst=3 bst=4 stall=1 dest4=2 nline_h=128 hold_rg=1 cur_rg=0 ch=1 CONTROL_CHUNK2
SNAP_D4 cyc=36340 dest4=128 dest=4 bst=4 stall=1 nline_h=128 hold_rg=1 cur_rg=0 ch=127 burst=128
SNAP_STALL0 cyc=36610 dest=0 bst=0 dest4=128 burst=128 nline_h=128 nline_meas=128 hold_rg=1 cur_rg=1 ch=127
CLASS=REGION_DONE
C_FIX=NONE
BOARD_PASS=not_claimed
EXISTENCE=not_claimed
PROGRAM=NO
XSIM=PASS
TIMEOUT_CAP=1000000
NLINE_MEAS=128 NLINE_H=128 NLINE_LAW_HOLD=128 HOLD_RG=1 CUR_RG=1 DBG_CUR_RG=1 CH=127
DEST4_CNT=128 DMA_GO_BURST=128 DMA_GO_CYC=384 STALL0_CYC=36610 STALL_END=0 BST_END=0
E2R_TILE_NLINE_BOUND_CXSIM_00_XSIM_PASS class=REGION_DONE c_fix=NONE dest4_cnt=128 dma_go_burst=128 nline=128 stall_end=0 stall0_cyc=36610 bst_end=0 dest5=1 dest0=1 dest4_2=1 dest4_2_cyc=304
```

Log SHA256 `29285B79C56965FE0AC3CE9681C622081D323CDF42DCBB33146BF0E23143EA49` (`xsim.log`).  
TB SHA256 `EAD56CE37FAA03EF777171722F869295E50E8193AF3C3F448A0B3E953883090B` (`tb_e2r_tile_nline_bound_cxsim_00.sv`).  
RTL SHA256 `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` (`weight_tile803k.sv`, not edited; same as CHUNK2_GO bag).  
Vivado 2026.1 xvlog / xelab / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board. `$finish` at 366215 ns.

## Interpretation (critical)

On this tile-only completable stub, one OFF_POS miss used POS `hold_rg=1` and measured `nline_h=128`. Dest reached dest=4 once per chunk for 128 chunks, 128 `dma_go` bursts, then `stall=0` at dest-clk 36610 with `bst=B_IDLE` and `cur_rg=1`. That **supports** H_RIVAL `REGION_DONE` and **falsifies** H_CANDIDATE `STALL_HOLD` on this vehicle: nline finishes when every `dma_go` completes and busy drops. Mid-refill `stall=1` (including CONTROL dest4_2 cyc=304) is expected until the last chunk, not stuck.

This does **not** prove silicon finishes a region or emits `CORE_DONE`. XSim stub, same-clk DMA, no MIG, no WDMA CDC, no leftover grant. Silicon ATOM1 dest=5 + 300 s silence / LONG listen SILENT remains a different unknown. Mapping 128 × assumed MIG ms/chunk onto wall time is ENGINEERING_INFERENCE only.

**No C-FIX.** Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_tile_nline_bound_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_tile_nline_bound_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_tile_nline_bound_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_tile_nline_bound_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `log.jsonl` | Gate log line |

# E2R-TILE-AFTER-SDONE-CXSIM-00 — CLOSEOUT

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_AFTER_SDONE_CXSIM_DISPATCH.md`  
**Claim scope:** Tile-only first-chunk handshake after `dma_done` — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No** (`C_FIX=NONE`)  
**Forbidden bypass:** not used (no leftover grant bags; `SIM_FULL=0`; no hold-busy after done; stall=1 after one chunk not treated as stuck)

XSim ≠ board. UART first-seen `TILE_BST=4` is not this bag.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | REARM silicon dest=4→5, ATOM0=`0000059C` sdone sticky=1, hold 300 s, no CORE_DONE. UART `TILE_BST=4` is first-seen `B_REQ`. `stall=(bst!=B_IDLE)||miss` for the whole refill. |
| UNKNOWN | after `dma_done` at `D_WAITDONE`, does `bst` leave `B_REQ` (first-chunk handshake)? |
| H_CANDIDATE | `ACK_STUCK` — dest=5, `bst` stays `B_REQ` |
| H_RIVAL | `CHUNK_ACK` — dest=5 and `bst` reaches `B_WAITACK` or `B_STORE` |
| FALSIFIER | leftover grant bags; `SIM_FULL=1`; hold busy after done; treat one-chunk `stall=1` as stuck |
| UNIT | one tile miss, first DMA chunk (not clock-as-query) |
| CONTROL | silicon ATOM dest 4→5; F1p dest=0∧B_REQ |
| METRICS | `dbg_dst`, `dbg_bst`, stall, `dbg_req` after `dma_done` |

## Vehicle (TB-only)

`weight_tile803k` `#(.SIM_FULL(0))` TILE generate only. Same clk for `clk` and `clk_dma`. After reset, `addr_a=OFF_POS` (131072) so `rg_of` ≠ `cur_rg=0`. `we_a=0`. Stub: `dma_go` → `busy=1`; on `dma_r_ready` (D_DRAIN) 8 `dma_r_valid` beats; pulse `dma_done` 1 cycle and clear busy.

## UNIT snaps

| Snap | cyc | dest | dbg_dst | bst | stall | req | notes |
|------|-----|------|---------|-----|-------|-----|-------|
| D_WAITDONE | 18 | **4** | 3 | **4** (`B_REQ`) | 1 | 1 | busy=1 done=0; dest just entered 4 (`dbg_dst` lags) |
| D_ACK | 20 | **5** | 4 | **4** (`B_REQ`) | 1 | 1 | busy=0 done=0; first dest=5, ack CDC not yet |
| bst after dest=5 | 24 | 5 | **5** | **5** (`B_WAITACK`) | 1 | 1 | ack=1, watch=5 |

`stall_after=1` (nline>1). Not treated as stuck.

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-TILE-AFTER-SDONE-CXSIM-00** |
| XSIM | **PASS** (`E2R_TILE_AFTER_SDONE_CXSIM_00_XSIM_PASS`) |
| CLASS | **CHUNK_ACK** |
| DEST4 | **1** |
| DEST5 | **1** |
| BST_AFTER | **5** (`B_WAITACK`) |
| STALL_AFTER | **1** |
| C_FIX | **NONE** |
| H_CANDIDATE | **falsified** on this tile+completable-stub vehicle (`bst` left `B_REQ`) |
| H_RIVAL | **supported** on this vehicle |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| PROGRAM | **NO** |

n = 1 tile miss, first chunk (one UNIT). Descriptive class only. Not a cycle farm.

## Evidence quotes (`xsim_stdout.txt` / `xsim.log`)

```text
VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB
MISS_FORCE addr_a=OFF_POS(131072) cur_rg_reset=0 we_a=0
SNAP_D4 cyc=18 dest=4 dbg_dst=3 bst=4 stall=1 req=1 req_s1=1 miss=1 busy=1 done=0 r_ready=0 go_seen=1 ack=0
SNAP_D5 cyc=20 dest=5 dbg_dst=4 bst=4 stall=1 req=1 req_s1=1 miss=1 busy=0 done=0 ack=0
SNAP_BST_AFTER cyc=24 dest=5 dbg_dst=5 bst=5 bst_max=5 stall=1 req=1 ack=1 watch=5
CLASS=CHUNK_ACK
C_FIX=NONE
BOARD_PASS=not_claimed
EXISTENCE=not_claimed
PROGRAM=NO
XSIM=PASS
E2R_TILE_AFTER_SDONE_CXSIM_00_XSIM_PASS class=CHUNK_ACK c_fix=NONE dest4=1 dest5=1 bst_after=5 stall_after=1 req_after=1
```

Log SHA256 `F660793B12EB2749C6E4F4C41F8136C322D017311E240F07D6A7ED98D375B034` (`xsim.log`).  
TB SHA256 `0DEEFEC9CE468047F0CCD0C506A6FEDEA26DC2030BDCC49373691D02F437BB45` (`tb_e2r_tile_after_sdone_cxsim_00.sv`).  
RTL SHA256 `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` (`weight_tile803k.sv`, not edited).  
Vivado 2026.1 xvlog / xelab / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board. $finish at 355 ns.

## Interpretation (critical)

On this tile-only completable stub, dest reached `D_WAITDONE` then `D_ACK` (4→5), matching CONTROL silicon ATOM dest 4→5. Two dest-clk after dest=5, `bst` reached `B_WAITACK` (5). `ack` rose. That **supports** H_RIVAL `CHUNK_ACK` and **falsifies** H_CANDIDATE `ACK_STUCK` on this vehicle: dest=5 is not sufficient to keep `bst` in `B_REQ` when `dma_done` pulses and busy drops.

This does **not** prove silicon `bst` left `B_REQ`. XSim stub, same-clk DMA, no MIG, no WDMA CDC, no leftover grant. UART `TILE_BST=4` is a **first-seen** latch (snap at dest=4/first dest=5 is still `B_REQ`); that print is compatible with this bag. `stall=1` after one chunk is the refill law (`nline`>1), not stuck. Silicon hold 300 s / no `CORE_DONE` remains a different unknown (later chunks, CDC, mux, or core). F1p dest=0∧B_REQ is old, no `s_done`.

**No C-FIX.** Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_tile_after_sdone_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_tile_after_sdone_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_tile_after_sdone_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_tile_after_sdone_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `log.jsonl` | Gate log line |

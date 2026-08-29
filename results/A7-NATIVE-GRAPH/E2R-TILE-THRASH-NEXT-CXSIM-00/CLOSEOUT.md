# E2R-TILE-THRASH-NEXT-CXSIM-00 — CLOSEOUT

**Date:** 2026-08-29  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_THRASH_NEXT_CXSIM_DISPATCH.md`  
**Claim scope:** Tile-only POS-then-TOK miss — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No** (`C_FIX=NONE`)  
**Forbidden bypass:** not used (no leftover grant bags; `SIM_FULL=0`; stub completes every `dma_go`; switch only after first `stall=0`; did not require TOK region to finish)

XSim ≠ board. Silicon ~1.18e6 DMA remains ENGINEERING_INFERENCE (n=1 switch on stub).  
`--dispatch` `graph_late_materialize_00` is DEFERRED. This bag is existence side-lane only.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | One POS miss completes on stub. ST_EMB alternates TOK/POS. Law: miss when `rg_of(addr_a) != cur_rg`. |
| UNKNOWN | after first POS `stall=0`, does `addr_a` in TOK (`rg=0`) start a second dest=4 train? |
| H_CANDIDATE | `THRASH_NEXT` — new dest=4 / `dma_go` after the switch |
| H_RIVAL | `HIT_HOLD` — `stall` stays 0; no second dest=4 |
| FALSIFIER | switch before first `stall=0`; `SIM_FULL=1`; hold busy; C-FIX; stop at first region |
| UNIT | one POS refill then one TOK address (not 2048 switches; not clock-as-query) |
| CONTROL | REGION_DONE dest4_cnt=128 stall=0; `rg_of(<OFF_POS)=0` |
| METRICS | dest4 after switch, miss, cur_rg, stall, dma_go bursts |

## Vehicle (TB-only)

Copy of `tb_e2r_tile_nline_bound_cxsim_00.sv`. **One change:** after first `stall=0`, set `addr_a=OFF_TOK` (0). Completable stub for **every** `dma_go`. Watch for a **new** dest=4 or timeout **500000** dest-clk after switch. Do not require TOK region to finish.

`weight_tile803k` `#(.SIM_FULL(0))` TILE generate only. Same clk for `clk` and `clk_dma`. After reset, `addr_a=OFF_POS` (131072) until first `stall=0`. `we_a=0`.

## UNIT snaps

| Snap | cyc | dest | bst | stall | dest4 | burst | notes |
|------|-----|------|-----|-------|-------|-------|-------|
| first `dma_go` | 7 | 1 | 4 | 1 | 0 | 1 | hold_rg=1 `nline_h=128` miss=1 |
| first `D_WAITDONE` | 18 | **4** | 4 | 1 | 1 | 1 | first POS chunk |
| dest4_2 | **304** | **4** | 4 | **1** | 2 | 2 | CONTROL CHUNK2 |
| dest4=128 | 36340 | **4** | 4 | 1 | **128** | **128** | last POS chunk `ch=127` |
| first stall=0 (before switch) | **36610** | 0 | 0 | **0** | **128** | 128 | CONTROL REGION_DONE; `cur_rg=1` miss=0 `addr_a=131072` |
| TOK switch | **36610** | 0 | 0 | 0 | 128 | 128 | `addr_a=0` `OFF_TOK`; `cur_rg` still 1 |
| first `dma_go` after switch | **36617** | 1 | 4 | **1** | 128 | **129** | `hold_rg=0` `nline_h=1024` miss=1 |
| dest=4 after switch | **36628** | **4** | 4 | 1 | **129** | 129 | dest4_after_switch=**1**; TOK region not finished |

Timeout-after 500000 unused (`$finish` at 366395 ns / dest4_post_cyc=36628).  
Same-cycle `SNAP_SWITCH_TOK` printed miss=0 / stall=0 because `addr_a` and `dbg_miss` were sampled in the same blocking slot. The next dest-clk snaps (36617, 36628) show miss=1 and dest=4. Classification uses dest=4 after switch, not that same-cycle sample.

CONTROL match: dest4_cnt=128 stall=0 at cyc=36610 (prior NLINE-BOUND bag). `rg_of(OFF_TOK)=0`. After switch `cur_rg` stayed 1 until a new refill started (`hold_rg=0`).

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-TILE-THRASH-NEXT-CXSIM-00** |
| XSIM | **PASS** (`E2R_TILE_THRASH_NEXT_CXSIM_00_XSIM_PASS`) |
| CLASS | **THRASH_NEXT** |
| DEST4_AFTER_SWITCH | **1** |
| DEST4_CNT | **129** (128 POS + 1 TOK-start) |
| DMA_GO bursts | **129** |
| CUR_RG_BEFORE | **1** |
| CUR_RG_AFTER | **1** (resident POS until TOK refill commits) |
| STALL0_CYC | **36610** |
| SWITCH_CYC | **36610** |
| DEST4_POST_CYC | **36628** |
| C_FIX | **NONE** |
| H_CANDIDATE | **supported** on this tile+completable-stub vehicle |
| H_RIVAL | **falsified** on this vehicle (dest=4 18 dest-clk after switch) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| PROGRAM | **NO** |

n = 1 POS refill then 1 TOK address (one UNIT). Descriptive class only. Not a cycle farm. No inferential test. 1.18e6 DMA stays ENGINEERING_INFERENCE.

## Evidence quotes (`xsim.log`)

```text
VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB_EVERY_GO
MISS_FORCE addr_a=OFF_POS(131072) then after stall=0 addr_a=OFF_TOK(0) we_a=0
SNAP_D4_2 cyc=304 dest=4 dbg_dst=3 bst=4 stall=1 dest4=2 nline_h=128 hold_rg=1 cur_rg=0 miss=1 ch=1 CONTROL_CHUNK2
SNAP_STALL0_BEFORE_SWITCH cyc=36610 dest=0 bst=0 dest4=128 burst=128 nline_h=128 nline_meas=128 hold_rg=1 cur_rg=1 miss=0 stall=0 ch=127 addr_a=131072
SNAP_SWITCH_TOK cyc=36610 addr_a=0 OFF_TOK=0 dest4=128 cur_rg=1 miss=0 stall=0 dest=0 bst=0
SNAP_GO_BURST cyc=36617 burst=129 dest=1 dbg_dst=0 bst=4 stall=1 nline_h=1024 hold_rg=0 cur_rg=1 miss=1 ch=0 dest4=128 switched=1
SNAP_D4_AFTER_SWITCH cyc=36628 dest=4 bst=4 stall=1 dest4=129 dest4_after=1 nline_h=1024 hold_rg=0 cur_rg=1 miss=1 ch=0 burst=129
CLASS=THRASH_NEXT
C_FIX=NONE
BOARD_PASS=not_claimed
EXISTENCE=not_claimed
PROGRAM=NO
XSIM=PASS
DEST4_CNT=129 DEST4_AT_SWITCH=128 DEST4_AFTER_SWITCH=1 DMA_GO_BURST=129 DMA_GO_CYC=387
STALL0_CYC=36610 SWITCH_CYC=36610 DEST4_POST_CYC=36628 STALL_END=1 BST_END=4
CUR_RG_BEFORE=1 CUR_RG_AFTER=1 MISS_BEFORE=0 MISS_AFTER=0 STALL_BEFORE=0 STALL_AFTER=0
E2R_TILE_THRASH_NEXT_CXSIM_00_XSIM_PASS class=THRASH_NEXT c_fix=NONE dest4_cnt=129 dest4_after_switch=1 dma_go_burst=129 nline=128 stall_end=1 stall0_cyc=36610 switch_cyc=36610 dest4_post_cyc=36628 cur_rg_before=1 cur_rg_after=1 miss_before=0 miss_after=0 dest5=1 dest0=1 dest4_2=1
```

Log SHA256 `7222BDAF8137D7BA3AB9AFE17203C955B6B3F11286982680E857EAD54A075924` (`xsim.log`).  
TB SHA256 `D4ED74316CB1633D347BC9E549253439855EF1D4FD5CC5969D9DD7B32AA491F4` (`tb_e2r_tile_thrash_next_cxsim_00.sv`).  
RTL SHA256 `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` (`weight_tile803k.sv`, not edited; same as NLINE-BOUND bag).  
Vivado 2026.1 xvlog / xelab / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board. `$finish` at 366395 ns.

## Interpretation (critical)

On this tile-only completable stub, one OFF_POS miss reached CONTROL `stall=0` dest4=128 `cur_rg=1`. Driving `addr_a=OFF_TOK` (rg=0) then started a **new** dest=4 / `dma_go` 18 dest-clk later (`hold_rg=0`, TOK nline_h=1024, dest4_cnt 128→129). That **supports** H_CANDIDATE `THRASH_NEXT` and **falsifies** H_RIVAL `HIT_HOLD` on this vehicle: after POS is resident, a TOK address is a miss and starts another refill train.

This does **not** prove silicon thrashes for ~1.18e6 DMA beats, nor that UART emits `pred=664`. n=1 switch. Stub ≠ MIG. Same-clk DMA. No WDMA CDC. TOK region was not required to finish (first dest=4 after switch is the UNIT). Mapping 1024 TOK chunks × assumed MIG ms/chunk onto wall time is still ENGINEERING_INFERENCE.

**No C-FIX.** Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`. `lock.owner=grok` unchanged.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_tile_thrash_next_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_tile_thrash_next_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_tile_thrash_next_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_tile_thrash_next_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `log.jsonl` | Gate log line |

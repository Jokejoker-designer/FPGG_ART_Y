# E2R-TILE-TOK-NLINE-CXSIM-00 — CLOSEOUT

**Date:** 2026-08-29  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_TOK_NLINE_CXSIM_DISPATCH.md`  
**Claim scope:** Tile-only TOK nline after POS — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No** (`C_FIX=NONE`)  
**Forbidden bypass:** not used (no leftover grant bags; `SIM_FULL=0`; stub completes every `dma_go`; did **not** stop at first dest=4 after switch)

XSim ≠ board. Silicon ~1.18e6 DMA remains ENGINEERING_INFERENCE (n=1 TOK refill on stub).  
`--dispatch` `graph_late_materialize_00` is DEFERRED. This bag is existence side-lane only.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | THRASH_NEXT dest4 128→129. POS REGION_DONE nline=128. `rg_nline` says TOK=1024. |
| UNKNOWN | after the TOK switch, does that refill reach `stall=0` with dest4 increment = 1024? |
| H_CANDIDATE | `TOK_DONE` — `stall=0` and dest4 increment after switch == 1024 |
| H_RIVAL | `TOK_HOLD` — timeout still `stall=1` |
| FALSIFIER | stop at first dest=4 after switch; `SIM_FULL=1`; hold busy; C-FIX |
| UNIT | one TOK refill after one POS refill (not 2048 switches; not clock-as-query) |
| CONTROL | THRASH_NEXT dest4_post=36628 dest4=129; `rg_nline(0)=1024` |
| METRICS | dest4 increment after switch, stall_end, nline, bst |

## Vehicle (TB-only)

Copy of `tb_e2r_tile_thrash_next_cxsim_00.sv`. **One change:** do not stop at first dest=4 after switch. Completable stub for **every** `dma_go`. Watch until `stall=0` again or timeout **2000000** dest-clk after switch.

`weight_tile803k` `#(.SIM_FULL(0))` TILE generate only. Same clk for `clk` and `clk_dma`. After reset, `addr_a=OFF_POS` (131072) until first `stall=0`, then `addr_a=OFF_TOK` (0). `we_a=0`.

## UNIT snaps

| Snap | cyc | dest | bst | stall | dest4 | burst | notes |
|------|-----|------|-----|-------|-------|-------|-------|
| first `dma_go` | 7 | 1 | 4 | 1 | 0 | 1 | hold_rg=1 `nline_h=128` miss=1 |
| first `D_WAITDONE` | 18 | **4** | 4 | 1 | 1 | 1 | first POS chunk |
| dest4_2 | **304** | **4** | 4 | **1** | 2 | 2 | CONTROL CHUNK2 |
| dest4=128 | 36340 | **4** | 4 | 1 | **128** | **128** | last POS chunk `ch=127` |
| first stall=0 (before switch) | **36610** | 0 | 0 | **0** | **128** | 128 | CONTROL REGION_DONE; `cur_rg=1` miss=0 |
| TOK switch | **36610** | 0 | 0 | 0 | 128 | 128 | `addr_a=0` `OFF_TOK` |
| first `dma_go` after switch | **36617** | 1 | 4 | **1** | 128 | **129** | `hold_rg=0` `nline_h=1024` miss=1 |
| dest=4 after switch | **36628** | **4** | 4 | 1 | **129** | 129 | CONTROL dest4_post; CONTINUE_WATCH |
| dest4 after=1024 | 329206 | **4** | 4 | 1 | **1152** | **1152** | last TOK chunk `ch=1023` |
| second stall=0 | **329476** | 0 | 0 | **0** | **1152** | 1152 | dest4_after=**1024** `nline_tok=1024` `cur_rg=0` |

Timeout-after 2000000 unused (`$finish` at 3294875 ns / stall0_tok_cyc=329476).  
CONTROL match: dest4_post_cyc=**36628** dest4=**129** (prior THRASH_NEXT bag). `rg_nline(0)=1024` measured as dest4 increment **1024**.

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-TILE-TOK-NLINE-CXSIM-00** |
| XSIM | **PASS** (`E2R_TILE_TOK_NLINE_CXSIM_00_XSIM_PASS`) |
| CLASS | **TOK_DONE** |
| DEST4_AFTER_SWITCH | **1024** |
| DEST4_CNT | **1152** (128 POS + 1024 TOK) |
| DMA_GO bursts | **1152** |
| NLINE_MEAS (POS) | **128** |
| NLINE_TOK | **1024** |
| STALL_END | **0** |
| BST_END | **0** |
| STALL0_CYC | **36610** |
| STALL0_TOK_CYC | **329476** |
| SWITCH_CYC | **36610** |
| DEST4_POST_CYC | **36628** |
| C_FIX | **NONE** |
| H_CANDIDATE | **supported** on this tile+completable-stub vehicle |
| H_RIVAL | **falsified** on this vehicle (second `stall=0` before timeout) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| PROGRAM | **NO** |

n = 1 POS refill then 1 TOK refill (one UNIT). Descriptive class only. Not a cycle farm. No inferential test. 1.18e6 DMA stays ENGINEERING_INFERENCE.

## Evidence quotes (`xsim.log`)

```text
VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB_EVERY_GO
MISS_FORCE addr_a=OFF_POS(131072) then after stall=0 addr_a=OFF_TOK(0) we_a=0
SNAP_D4_2 cyc=304 dest=4 dbg_dst=3 bst=4 stall=1 dest4=2 nline_h=128 hold_rg=1 cur_rg=0 miss=1 ch=1 CONTROL_CHUNK2
SNAP_STALL0_BEFORE_SWITCH cyc=36610 dest=0 bst=0 dest4=128 burst=128 nline_h=128 nline_meas=128 hold_rg=1 cur_rg=1 miss=0 stall=0 ch=127 addr_a=131072
SNAP_SWITCH_TOK cyc=36610 addr_a=0 OFF_TOK=0 dest4=128 cur_rg=1 miss=0 stall=0 dest=0 bst=0
SNAP_GO_BURST cyc=36617 burst=129 dest=1 dbg_dst=0 bst=4 stall=1 nline_h=1024 hold_rg=0 cur_rg=1 miss=1 ch=0 dest4=128 dest4_after=0 switched=1
SNAP_D4_AFTER_SWITCH cyc=36628 dest=4 bst=4 stall=1 dest4=129 dest4_after=1 nline_h=1024 hold_rg=0 cur_rg=1 miss=1 ch=0 burst=129 CONTINUE_WATCH
SNAP_D4 cyc=329206 dest4=1152 dest4_after=1024 dest=4 bst=4 stall=1 nline_h=1024 hold_rg=0 cur_rg=1 miss=1 ch=1023 burst=1152 switched=1
SNAP_STALL0_AFTER_TOK cyc=329476 dest=0 bst=0 dest4=1152 dest4_after=1024 burst=1152 nline_h=1024 nline_tok=1024 hold_rg=0 cur_rg=0 miss=0 stall=0 ch=1023
CLASS=TOK_DONE
C_FIX=NONE
BOARD_PASS=not_claimed
EXISTENCE=not_claimed
PROGRAM=NO
XSIM=PASS
DEST4_CNT=1152 DEST4_AT_SWITCH=128 DEST4_AFTER_SWITCH=1024 DMA_GO_BURST=1152 DMA_GO_CYC=3456
STALL0_CYC=36610 STALL0_TOK_CYC=329476 SWITCH_CYC=36610 DEST4_POST_CYC=36628 STALL_END=0 BST_END=0
E2R_TILE_TOK_NLINE_CXSIM_00_XSIM_PASS class=TOK_DONE c_fix=NONE dest4_cnt=1152 dest4_after_switch=1024 dma_go_burst=1152 nline=128 nline_tok=1024 stall_end=0 stall0_cyc=36610 stall0_tok_cyc=329476 switch_cyc=36610 dest4_post_cyc=36628 cur_rg_before=1 cur_rg_after=1 miss_before=0 miss_after=0 dest5=1 dest0=1 dest4_2=1 dest4_after=1
```

Log SHA256 `EE2BE38BB35DB7731A20F0FB535C4CAC67E2E015EB2E3F7D06917FD84FAE310A` (`xsim.log`).  
TB SHA256 `73C73ECF79918A8746CF6472DF6D0FB141D2796B9DF9FCB3C336258262D4AAE1` (`tb_e2r_tile_tok_nline_cxsim_00.sv`).  
RTL SHA256 `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` (`weight_tile803k.sv`, not edited; same as THRASH-NEXT bag).  
Vivado 2026.1 xvlog / xelab / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board. `$finish` at 3294875 ns.

## Interpretation (critical)

On this tile-only completable stub, CONTROL matched THRASH_NEXT: first `stall=0` dest4=128 at cyc=36610, then dest=4 at cyc=36628 dest4=129. The TB **continued** past that first dest=4. TOK refill then reached a **second** `stall=0` at cyc=329476 with dest4 increment **1024** and `nline_tok=1024` (`cur_rg=0`, `ch=1023`). That **supports** H_CANDIDATE `TOK_DONE` and **falsifies** H_RIVAL `TOK_HOLD` on this vehicle: `rg_nline(0)=1024` is the measured dest4 count for one TOK refill after one POS refill.

This does **not** prove silicon completes 1024 TOK chunks under MIG, nor that UART emits `pred=664`. n=1 refill pair. Stub ≠ MIG. Same-clk DMA. No WDMA CDC. Timeout 2_000_000 unused. Mapping 1024 TOK chunks × assumed MIG ms/chunk onto wall time is still ENGINEERING_INFERENCE.

**No C-FIX.** Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`. `lock.owner=grok` unchanged.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_tile_tok_nline_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_tile_tok_nline_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_tile_tok_nline_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_tile_tok_nline_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `log.jsonl` | Gate log line |

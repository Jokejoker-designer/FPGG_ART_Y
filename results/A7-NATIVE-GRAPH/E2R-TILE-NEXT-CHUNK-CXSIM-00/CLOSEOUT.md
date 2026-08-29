# E2R-TILE-NEXT-CHUNK-CXSIM-00 — CLOSEOUT

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_TILE_NEXT_CHUNK_CXSIM_DISPATCH.md`  
**Claim scope:** Tile-only dest after first `D_ACK` — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No** (`C_FIX=NONE`)  
**Forbidden bypass:** not used (no leftover grant bags; `SIM_FULL=0`; stub completes every `dma_go`; did not stop at first dest=5; stall=1 after chunk 2 not treated as stuck)

XSim ≠ board. Silicon ATOM1 dest=5 then silence is not this bag.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | First-chunk handshake works on stub. Silicon ATOM1 dest=5 then 300 s silence. `D_ACK` exits only when `!req_s[1]`. `nline>1` so stall stays 1 until `B_IDLE`. LONG listen SILENT. |
| UNKNOWN | after first `D_ACK`, does dest return `D_IDLE` and reach `D_WAITDONE` again (chunk 2 `dma_go`)? |
| H_CANDIDATE | `ACK_HOLD` — dest stays 5; no second `dma_go` |
| H_RIVAL | `CHUNK2_GO` — dest returns 0 then 4 again |
| FALSIFIER | stop at first dest=5; hold busy after first done; `SIM_FULL=1`; leftover grant; C-FIX |
| UNIT | one miss, chunk1 then chunk2 (not clock-as-query) |
| CONTROL | CHUNK_ACK dest=5 bst=5; silicon ATOM1 dest=5 |
| METRICS | dest after ACK, second `dma_go`, second dest=4, `bst` |

## Vehicle (TB-only)

Copy of `tb_e2r_tile_after_sdone_cxsim_00.sv`. **One change:** do not stop at first dest=5. Completable stub for **every** `dma_go` (8 R + done + busy clear; return `ST_IDLE`). Watch until dest=0 after first ACK **and** dest=4 a second time, or timeout 20000 dest-clk. Do not require `stall=0`.

`weight_tile803k` `#(.SIM_FULL(0))` TILE generate only. Same clk for `clk` and `clk_dma`. After reset, `addr_a=OFF_POS` (131072). `we_a=0`.

## UNIT snaps

| Snap | cyc | dest | dbg_dst | bst | stall | go_n | notes |
|------|-----|------|---------|-----|-------|------|-------|
| first `dma_go` burst | 7–9 | 1→3 | 0→1 | 4 | 1 | 1–3 | dest holds `dma_go` in `D_GO` until busy |
| first `D_WAITDONE` | 18 | **4** | 3 | 4 | 1 | 3 | CONTROL match |
| first `D_ACK` | 20 | **5** | 4 | 4 | 1 | 3 | CONTROL match; not a stop |
| dest idle after ACK | 28 | **0** | 5 | **5** (`B_WAITACK`) | 1 | 3 | dest left 5 |
| second `dma_go` burst | 293–295 | 1→3 | 0→1 | 4 | 1 | 4–6 | second chunk start |
| second `D_WAITDONE` | 304 | **4** | 3 | 4 | 1 | 6 | class `CHUNK2_GO` |

`stall=1` at second dest=4 (`nline>1`). Not treated as stuck. Timeout cap 20000 unused (`$finish` at 3155 ns / cyc=304).

`dma_go_cnt=6` is dest-clk with `dma_go=1`, not two isolated 1-cycle pulses. Two bursts (chunk1 cyc 7–9, chunk2 cyc 293–295). Marker `dest_after_ack=4` / `bst_after_ack=4` is dest/bst **at classify** (second `D_WAITDONE`), not dest immediately after first ACK. Dest after first ACK is SNAP_IDLE dest=0 bst=5.

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-TILE-NEXT-CHUNK-CXSIM-00** |
| XSIM | **PASS** (`E2R_TILE_NEXT_CHUNK_CXSIM_00_XSIM_PASS`) |
| CLASS | **CHUNK2_GO** |
| DEST5 | **1** |
| DEST0 after ACK | **1** (cyc=28) |
| DEST4_2 | **1** (cyc=304) |
| DMA_GO bursts | **2** (`dma_go` high-cycles=6) |
| BST at D4_2 | **4** (`B_REQ`) |
| STALL at D4_2 | **1** |
| C_FIX | **NONE** |
| H_CANDIDATE | **falsified** on this tile+completable-stub vehicle (dest left 5; second dest=4) |
| H_RIVAL | **supported** on this vehicle |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| PROGRAM | **NO** |

n = 1 tile miss, chunk1 then chunk2 (one UNIT). Descriptive class only. Not a cycle farm. No inferential test.

## Evidence quotes (`xsim.log`)

```text
VEHICLE=weight_tile803k SIM_FULL=0 TILE_ONLY same_clk_dma COMPLETABLE_STUB_EVERY_GO
MISS_FORCE addr_a=OFF_POS(131072) cur_rg_reset=0 we_a=0
WATCH past first dest=5 until dest=0 AND dest=4 again; TO_CYC=20000; stall=0 not required
SNAP_D4_1 cyc=18 dest=4 dbg_dst=3 bst=4 stall=1 req=1 go_n=3 ack=0
SNAP_D5_1 cyc=20 dest=5 dbg_dst=4 bst=4 stall=1 req=1 go_n=3 ack=0
SNAP_IDLE cyc=28 dest=0 dbg_dst=5 bst=5 stall=1 req=0 go_n=3 ack=0
SNAP_GO cyc=293 go_n=4 dest=1 dbg_dst=0 bst=4 stall=1 req=1 busy=0 ack=0
SNAP_D4_2 cyc=304 dest=4 dbg_dst=3 bst=4 stall=1 req=1 go_n=6 ack=0
CLASS=CHUNK2_GO
C_FIX=NONE
BOARD_PASS=not_claimed
EXISTENCE=not_claimed
PROGRAM=NO
XSIM=PASS
TIMEOUT_CAP=20000
E2R_TILE_NEXT_CHUNK_CXSIM_00_XSIM_PASS class=CHUNK2_GO c_fix=NONE dest5=1 dest0=1 dest4_2=1 dma_go_cnt=6 dest_after_ack=4 bst_after_ack=4 bst_d4_2=4 stall_d4_2=1
```

Log SHA256 `6D371C0377FB335D391B5F4D0ADB8E19E797B39960D5DCBE48FF619985684D9F` (`xsim.log`).  
TB SHA256 `A96218DA3C30B95CDCF9D6E1D2C8F40081016D6A11A93D2B36C5AB86C56190D8` (`tb_e2r_tile_next_chunk_cxsim_00.sv`).  
RTL SHA256 `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` (`weight_tile803k.sv`, not edited; same as CHUNK_ACK bag).  
Vivado 2026.1 xvlog / xelab / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board. `$finish` at 3155 ns.

## Interpretation (critical)

On this tile-only completable stub, dest reached first `D_ACK` (5), returned to `D_IDLE` (0) at cyc=28 with `bst=B_WAITACK`, then started a second `dma_go` burst at cyc=293 and reached `D_WAITDONE` (4) again at cyc=304. That **supports** H_RIVAL `CHUNK2_GO` and **falsifies** H_CANDIDATE `ACK_HOLD` on this vehicle: dest=5 is not a terminal hold when the stub completes every go and busy drops.

Gap first ACK → second go is ~273 dest-clk (`B_STORE`/`B_SWAIT` over one chunk, then `B_NEXT`→`B_REQ`). That is refill law, not timeout.

This does **not** prove silicon starts chunk 2. XSim stub, same-clk DMA, no MIG, no WDMA CDC, no leftover grant. Silicon ATOM1 dest=5 + 300 s silence / LONG listen SILENT remains a different unknown (CDC, mux, MIG R, or core). `stall=1` at second dest=4 is `nline>1`, not stuck.

**No C-FIX.** Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_tile_next_chunk_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_tile_next_chunk_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_tile_next_chunk_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_tile_next_chunk_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `log.jsonl` | Gate log line |

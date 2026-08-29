# E2R-ACK-WHILE-R-CXSIM-00 — CLOSEOUT

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_ACK_WHILE_R_CXSIM_DISPATCH.md`  
**Claim scope:** Mux leftover XSim, dest vs in-R from first dest=4 until dest=5 only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No** (`C_FIX=NONE`)  
**Forbidden bypass:** not used (no force dest; no complete before dest=4; no hold-forever; no `soc_top` / MIG; no LiteScope)

XSim ≠ board. Silicon ATOM `dma_st=5` is **FINDING**, not class. AI does not declare `BOARD_PASS`.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon ATOM1 dest=5 (`D_ACK`). STILLR dest stays 4 while in-R until complete. Tile: `D_WAITDONE → D_ACK` iff `dma_done \|\| !dma_busy`. `dma_st` CDC is FINDING. |
| UNKNOWN | On the STILLR vehicle (in-R through dest=4, then complete), can dest become 5 while responder still in-R/busy? |
| H_CANDIDATE | `ACK_WHILE_R` — dest=5 and in-R/busy without done (tile desync). |
| H_RIVAL | `ACK_ONLY_AFTER_DONE` — dest=5 only after `s_done` or `!busy`. |
| FALSIFIER | Force dest; C-FIX; complete before dest=4; `soc_top`+MIG. |
| UNIT | One query. dest vs in-R each core cycle from first dest=4 until dest=5. |
| CONTROL | STILLR SNAP_DONE0 SHA `4F71A710F5899FBA1E45AD53C7FED59274CF0018073D8861FB395A6DFA7CABD7`; ATOM0 dest=4 ATOM1 dest=5; tile law above. |
| METRICS | dest (`dbg_tile_dst`), in-R, `dma_busy`, `s_done`, first dest=5 vs first done. |

## Vehicle (TB-only vs STILLR CONTROL)

Copy of `tb_e2r_sdone_stillr_cxsim_00.sv`. Kept mux + B1 + shared stub + `s_dma_idle=1'b0`. `SIM_FULL=0`. DUT-driven dest only.

**Same occupancy law as STILLR:** do not pulse `s_done` / clear busy until after first dest=4; then complete. Completing before dest=4 is the ROSE FALSIFIER. Forcing dest=5 is forbidden.

Class dest = `dbg_tile_dst` (`dst_s1`, two core cycles behind raw `TILE.dst`). Raw dest is FINDING only.

## UNIT snaps

| Metric | dest=4 (CONTROL occupancy) | first dest=5 (class) |
|--------|----------------------------|----------------------|
| `dbg_tile_dst` | **4** | **5** |
| raw `TILE.dst` | 4 | 5 |
| in-R (`w_st==W_R` ∧ `s_busy`) | **1** (`w_st=3`) | **0** (`w_st=1`) |
| `s_dma_busy` | 1 | 1 |
| `wdma_busy` (tile `dma_busy`) | 1 | **0** |
| `dbg_s_done_sticky` | **0** (snap) | 1 |
| `s_done` ever | 0 at dest=4 snap | **1** before dest=5 |
| `wdma_done` at dest=5 snap | — | 0 |
| cycle after dest=4 | `snap_cyc=355` | `snap5_cyc=7` |

Dest-wait latch at t=29640000 (`snap_cyc=355`), same cycle count as STILLR CONTROL. Dest=4 snap is still in-R, sticky=0 — vehicle matched CONTROL. First `dbg` dest=5 at t=30040000, `m_busy=0`, done already seen.

## DEST_BUSY (relevant core cycles, dest=4 → dest=5)

```text
DEST_BUSY t=29640000 phase=DEST4      dest=4 raw=4 in_r=1 s_busy=1 m_busy=1 s_done=0 m_done=0 sdone_ever=1 wst=3
DEST_BUSY t=29720000 phase=ACK_WATCH  dest=4 raw=4 in_r=0 s_busy=1 m_busy=1
DEST_BUSY t=29800000 phase=ACK_WATCH  dest=4 raw=4 in_r=1 s_busy=1 m_busy=0
DEST_BUSY t=29880000 phase=ACK_WATCH  dest=4 raw=5 in_r=0 s_busy=1 m_busy=1
DEST_BUSY t=29960000 phase=ACK_WATCH  dest=4 raw=5 in_r=1 s_busy=1 m_busy=0 m_done=1
DEST_BUSY t=30040000 phase=ACK_WATCH  dest=5 raw=5 in_r=0 s_busy=1 m_busy=0
```

FINDING (not class): raw dest became 5 two core cycles before `dbg_tile_dst` (known `dst_s1` delay). `DEST_BUSY` `in_r`/`w_st` rows are ui-domain samples on `core_clk` and are **not** used as class. Class uses the dest=5 always_ff snap (`IN_R_AT_DEST5=0`, `m_busy=0`, `S_DONE_BEFORE_DEST5=1`).

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-ACK-WHILE-R-CXSIM-00** |
| XSIM | **PASS** (`E2R_ACK_WHILE_R_CXSIM_00_XSIM_PASS`) |
| CLASS | **ACK_ONLY_AFTER_DONE** |
| DEST5 | **1** |
| IN_R_AT_DEST5 | **0** |
| S_DONE_BEFORE_DEST5 | **1** |
| C_FIX | **NONE** |
| H_CANDIDATE | **not supported** on this vehicle (no dest=5 while in-R without done) |
| H_RIVAL | **supported** on this vehicle (dest=5 after done / `!m_busy`) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

n = 1 query (one UNIT). Descriptive class only. Not a cycle farm.

## Evidence quotes (`xsim_stdout.txt` / `xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1+MUX ungated_cdc_rvalid SHARED_STUB_WDMA STILLR_THEN_COMPLETE s_dma_idle=0
SNAP destwait_cyc=355 ... SNAP_SDONE sdone_st=0 ... s_busy=1 m_busy=1 wst=3
IN_R_AT_SNAP=1
DEST4=1
DEST5=1
IN_R_AT_DEST5=0
S_DONE_BEFORE_DEST5=1
BUSY_AT_DEST5 s_busy=1 m_busy=0 wst=1
DEST5_WHILE_IN_R_NODONE=0 DEST5_WHILE_BUSY_NODONE=0
CLASS=ACK_ONLY_AFTER_DONE
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=PASS
E2R_ACK_WHILE_R_CXSIM_00_XSIM_PASS class=ACK_ONLY_AFTER_DONE c_fix=NONE dest5=5 raw=5 in_r_at_dest5=0 s_done_before_dest5=1 s_busy=1 m_busy=0 wst=1 dest5_cyc=7 done_cyc=0
```

Log SHA256 `ADA5C6E36E88624570EF5F795E9EDBB8EDE70EC851F4863DED5BA73F5FA840D5` (`xsim.log`).  
TB SHA256 `6D7AA58E7B84532969941C629DE54E0C0718B6CB048B0F7701218B186B067812` (`tb_e2r_ack_while_r_cxsim_00.sv`).  
STILLR CONTROL SHA256 `4F71A710F5899FBA1E45AD53C7FED59274CF0018073D8861FB395A6DFA7CABD7` (`E2R-SDONE-STILLR-CXSIM-00/xsim.log`, not re-run).  
CDC SHA256 `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` (`a7ng_wdma_cdc.sv`, not edited).  
Vivado 2026.1 xvlog / xelab (`-L xpm` + `glbl`) / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board.

## Interpretation (critical)

On this STILLR-then-complete vehicle, first dest=4 was still in-R (`w_st=3`, `s_busy=1`, `m_busy=1`, sticky=0) — CONTROL occupancy held. First `dbg` dest=5 came 7 core cycles later with `m_busy=0` and done already seen. That **supports** H_RIVAL `ACK_ONLY_AFTER_DONE` and **does not support** H_CANDIDATE `ACK_WHILE_R` on this stimulus.

Tile `dma_busy` at dest=5 was 0. Residual `s_busy=1` is ui-side occupancy after CDC; class follows tile `m_busy` / done, not ATOM `dma_st`. Raw dest leading dbg dest by two core cycles is the documented `dst_s1` delay (FINDING).

This does **not** prove silicon ATOM1 dest=5 means the core saw done/idle. XSim stub+CDC ≠ board UART / MIG. ATOM `dma_st=5` remains CDC FINDING, not FACT. Grant still rose before dest-wait (`grant=1` at dest=4), same MUX deviation vs sequential silicon `GRANT=0`. One query, one occupancy — not a cycle farm.

**No C-FIX.** Still-in-R-then-complete TB is not a product patch. Existence remains UART `pred=664`. AI does not declare `BOARD_PASS`.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_ack_while_r_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_ack_while_r_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_ack_while_r_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_ack_while_r_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | dest vs busy/done table |
| `log.jsonl` | Gate log line |

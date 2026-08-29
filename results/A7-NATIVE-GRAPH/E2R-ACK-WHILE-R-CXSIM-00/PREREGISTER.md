# E2R-ACK-WHILE-R-CXSIM-00 — PREREGISTER

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_ACK_WHILE_R_CXSIM_DISPATCH.md`  
**Control bags:** STILLR `xsim.log` SHA `4F71A710F5899FBA1E45AD53C7FED59274CF0018073D8861FB395A6DFA7CABD7` (SNAP_DONE0, dest=4 while in-R); silicon ATOM0 dest=4 ATOM1 dest=5  
**Class:** C-XSIM mux vehicle, still-in-R through dest=4, then complete; dest vs in-R until dest=5  
**Board:** NOT used. No COM. No program. No bitstream. No `vivado.exe` impl.

Frozen before UNIT run. XSim ≠ board. Silicon ATOM `dma_st` CDC is FINDING, not class. AI does not declare `BOARD_PASS`.

## Scientific frame (frozen before UNIT run)

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon ATOM1 dest=5 (`D_ACK`) one core cycle after dest=4; pack still reports `dma_st=5`. STILLR dest stays 4 while in-R until complete. Tile law: `D_WAITDONE → D_ACK` iff `dma_done \|\| !dma_busy`. `dma_st` CDC is FINDING (unsafe 3b). |
| UNKNOWN | On the STILLR vehicle (busy/in-R through dest=4, then complete), can dest become 5 while responder still in-R/busy? |
| H_CANDIDATE | `ACK_WHILE_R` — dest=5 and in-R/busy in the same cycle (tile desync). |
| H_RIVAL | `ACK_ONLY_AFTER_DONE` — dest=5 only after `s_done` or `!busy`. Silicon dest=5 means core saw done/idle; ATOM `dma_st=5` is CDC. |
| FALSIFIER | Force dest; C-FIX; complete before dest=4; hold forever; `soc_top`+MIG; A2; LiteScope. |
| UNIT | One query. dest vs in-R each core cycle from first dest=4 until dest=5 or timeout. |
| CONTROL | STILLR SNAP_DONE0 SHA `4F71A710…`; ATOM0 dest=4 ATOM1 dest=5; tile law above. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. `s_dma_idle=1'b0` kept. |
| METRICS | dest (`dbg_tile_dst`), raw `TILE.dst` (FINDING, 2-FF behind dbg), in-R, `dma_busy` (`wdma_busy` / `s_dma_busy`), `s_done`, cycle of first dest=5 vs first done. |

## Verdict classes (preregistered)

| Class | Meaning | C-FIX | Marker |
|-------|---------|-------|--------|
| `ACK_WHILE_R` | dest=5 on some core cycle where responder still in-R (`w_st==W_R` ∧ `s_busy`) **or** tile `dma_busy` with no done seen | none | `E2R_ACK_WHILE_R_CXSIM_00_XSIM_PASS` |
| `ACK_ONLY_AFTER_DONE` | dest=5 occurs, and only after `s_done`/`wdma_done` or `!busy` (no dest=5 while still in-R without done) | none | `E2R_ACK_WHILE_R_CXSIM_00_XSIM_PASS` |
| `FAIL_NO_ACK` | dest=4 seen, dest=5 never | none | no PASS marker |
| `FAIL_NO_DESTWAIT` | dest=4 never | none | no PASS marker |

Vehicle miss (dest=4 but not in-R at first dest=4) = FALSIFIER / no PASS (complete-before-dest=4 occupancy). Not a cycle farm.

**dest** for class = `dbg_tile_dst` (same probe as silicon ATOM dest). Raw `TILE.dst` is FINDING only (`dbg` is `dst_s1`, two core cycles late). `dma_st` is not class.

Overlap rule (frozen): dest=5 on the same cycle as `s_done`/`wdma_done` while still `busy` is **`ACK_ONLY_AFTER_DONE`** if not still in-R without prior/current done (law path `dma_done \|\| !dma_busy`). dest=5 while in-R and no done seen = **`ACK_WHILE_R`**.

## Vehicle (TB-only vs STILLR CONTROL)

Copy `tb_e2r_sdone_stillr_cxsim_00.sv`. Keep mux + B1 + shared stub + `s_dma_idle=1'b0`. `SIM_FULL=0`. DUT-driven dest only. No `soc_top`. No MIG.

Keep in-R through dest=4, then complete. Do not force dest=5. Print dest vs busy/done each relevant core cycle from first dest=4 until dest=5.

## Forbidden

- Force dest / `TILE_DST`
- Complete before dest=4 (ROSE / FALSIFIER)
- Hold `busy=1` forever after dest=4 (MUX / FALSIFIER)
- C-FIX / A2 / LiteScope
- `soc_top` + MIG
- Product RTL edit
- Board / COM / bitstream / JTAG
- Sell ATOM `dma_st=5` as FACT
- `BOARD_PASS` / existence PASS

## Analysis plan (before run)

- Latch first `dbg_tile_dst==4` (vehicle: require in-R/busy).
- Allow complete only after that dest=4 (STILLR `dest4_seen_ui`).
- Each core cycle from dest=4 until dest=5: record dest, raw dst, in-R, `s_busy`, `m_busy`, `s_done`, `m_done`.
- Classify from first dest=5 vs first done / in-R. One query = one UNIT.
- `C_FIX=NONE`. `BOARD_PASS` not claimed. XSim ≠ board.

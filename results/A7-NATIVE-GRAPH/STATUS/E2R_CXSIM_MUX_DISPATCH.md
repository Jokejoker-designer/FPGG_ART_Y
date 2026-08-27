# E2R C-XSIM-MUX — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-RPATH-IDLE-CXSIM-MUX-00/`  
**Do not program. Do not edit product RTL. Do not apply C-FIX.**

This is the **mux half** of option B (`mux-tile-MIG dest-wait`). Tile dest-wait half is SEALED NONE on a **separate WDMA port**.

## Scientific frame

- **OBSERVATION:** Dest-wait XSim idle=1 with separate WDMA. Silicon dest-wait `RPATH_IDLE=0` `GRANT=0`. SoC `cdc_rvalid = rvalid` ungated (`arty_a7_ng_native_v1_ab_soc_top.sv` ~201). `rready` steals when `wdma_owner_ui`.
- **UNKNOWN:** at first legal `TILE_DST==4` through **shared AXI stub + AXI-read CDC + B1 grant + ungated `cdc_rvalid=rvalid`**, which of `r_drain_hold` / `fifo_cnt` / `m_axi_rvalid` (`c_rvalid`) / `tr_cnt` is 1.
- **H_CANDIDATE:** after grant or leftover WDMA/SOA R on the shared bus, ungated `cdc_rvalid` holds `c_rvalid` / `m_axi_rvalid` → idle=0.
- **H_RIVAL:** mux+CDC dest-wait still idle=1 (`NONE`); leftover is true MIG-only.
- **FALSIFIER:** force `dst` / `r_path_idle`; instantiate full `soc_top`+MIG as the only plan; apply C-FIX; never reach dest-wait (`FAIL_NO_DESTWAIT`); `SET` if >1 term.
- **UNIT:** first dest-wait occupancy after one query. Not a cycle farm.
- **CONTROL:** dest-wait separate-WDMA idle=1 (SHA `DAD0E6DE…`); silicon GRANT=0 RPATH_IDLE=0.
- **METRICS:** tile_dst, four AND terms, r_path_idle, wdma_owner, wdma_owner_grant, wdma_owner_ui, cdc_rvalid, stub rvalid, grant-rose-before-destwait.

## Vehicle (legal)

Copy dest-wait TB. Add, **TB-only**:
1. `a7ng_axi_read_cdc` between core AXI and **one** shared mem stub.
2. B1 grant FF (same law as SoC: grant rises only when `wdma_owner && r_path_idle`).
3. Mux assigns copied from SoC (do not edit SoC):
   - `arvalid = wdma_owner_ui ? d_arvalid : cdc_arvalid`
   - `rready  = wdma_owner_ui ? d_rready  : cdc_rready`
   - **`cdc_rvalid = rvalid` ungated**
   - `cdc_arready = !wdma_owner_ui && arready`
4. WDMA responder (or `ddr_tile_dma` if it compiles without MIG) on the **same** stub R bus — not a private port.
5. `SIM_FULL=0`. DUT-driven `dbg_tile_dst==4` only.

Do **not** instantiate `arty_a7_ng_native_v1_ab_soc_top` or `mig_native_wrap`. Dual clocks OK (core 12.5 MHz / ui 100 MHz like CDC bag).

## Verdict classes

| Class | Meaning | C-FIX |
|-------|---------|-------|
| `ONE` | exactly one AND term 1 at dest-wait | name only |
| `SET` | two or more | no C-FIX |
| `NONE` | dest-wait reached, all four 0 | no C-FIX |
| `FAIL_NO_DESTWAIT` | never dst=4 | no C-FIX |

Print `E2R_RPATH_IDLE_CXSIM_MUX_00_XSIM_PASS` only if dest-wait reached and classified.

## Done

Archive TB/tcl/log/`CLOSEOUT.md`. `BOARD_PASS: not claimed`. Parent writes `STATUS/E2R_CXSIM_MUX_CLOSEOUT.md`.

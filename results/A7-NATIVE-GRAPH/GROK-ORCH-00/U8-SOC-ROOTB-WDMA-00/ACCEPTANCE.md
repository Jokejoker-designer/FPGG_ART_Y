# ACCEPTANCE — U8-SOC-ROOTB-WDMA-00 (re-audit after one patch)

```text
AUDITOR     = gstack-acceptance-auditor (qa-only; report-only; no RTL/TB/CLOSEOUT patch)
GATE        = U8-SOC-ROOTB-WDMA-00
BAG         = results/A7-NATIVE-GRAPH/GROK-ORCH-00/U8-SOC-ROOTB-WDMA-00
AUTHORITY   = skill SKILL.md + a7-fpga-gate + a7-native-graph-gate
              + PREREG/LOCK + CLOSEOUT/RESULTS + raw xsim.log + RTL/TB
VERDICT     = PASS
OVERCLAIM   = false
FRAUD       = false
LOGIC_BUG   = false
FIRST_DIV   = NONE (this run; prior WDMA_SILENT_DROP retained)
WIRE        = a7ng_wdma_cdc.m_go_ready
SOC_WDMA    = SLICE_XSIM_PASS (not full SoC; dest port unwired)
```

Evidence > chat memory. This file does not change CLOSEOUT, RESULTS, RTL, or TB.
Re-audit after the named-wire patch. Previous ACCEPTANCE (FAIL / `WDMA_SILENT_DROP`) is superseded by this file against the **accepted** `xsim.log` dated Mon Sep 7 05:57:24 2026.

## Authority / hard stops

| Token | Observed |
|---|---|
| BIT | NO. `vivado.jou` is `source run_xsim.tcl` only. No `write_bitstream`, `open_hw`, `program_device`. |
| PROGRAM | NO |
| REPROGRAM_AGAIN | NO |
| QHEAD | NO |
| HOLD_A_ORACLE_RETARGET | NO (no pred/OUT 653/689/237/60; METRICS `pred_obs=null`) |
| reseat `1F0F2ABB` / `9CA2B30D` / `F24150BD` / `3A7EF204` | no bit in bag |
| U8R / U9S / U9I / U9P / U10 | CLOSEOUT NEXT forbids auto-open; auditor does not open them |
| BOARD_PASS / GATE14_PASS | CLOSEOUT = NO; log has no such marker |
| force-push / history rewrite | prior fail retained as `xsim_054007_fail.backup.log`; accepted run is a new xsim (05:57:24) |
| MIG / `a7lm06_wmem.hex` | not in bag; not git-added here |

Semantic LM class remains `LM_CHECKPOINT_CONTEXT_MISMATCH` (not this unknown). Cycle watchdog (`WATCH_CYC=2000000` on `core_clk`), not ns overflow. `$finish` 56805 ns ≈ 5680 core cycles.

## Fail-closed inputs

| Artifact | Status |
|---|---|
| `xsim.log` | present; XSim 2026.1; start Mon Sep 7 05:57:24 2026; exit 05:57:26; `$finish` 56805 ns at TB line 602 (`U8_SOC_ROOTB_WDMA_PASS`) |
| `SHA256.txt` | present (store, persist_axi_bridge, wdma_cdc, ddr_tile_dma, weight_tile803k, both TBs, tcl) |
| PASS marker vs log | `U8_SOC_ROOTB_WDMA_PASS` **present**. No `FIRST_DIVERGENCE`. `run_xsim.tcl` treats `FIRST_DIVERGENCE` as exit 6. `vivado.log` tail: `U8_SOC_ROOTB_WDMA_XSIM_OK`. CLOSEOUT `RESULT=PASS` **matches** the log. |
| xvlog / xelab | bag `xvlog.log` analyzes store, persist_axi_bridge, wdma_cdc, ddr_tile_dma, bag TBs, glbl. Snapshot `u8wdma`. No SoC top, no MIG, no `persist_gen_fast`, no LM, no encoder, no `native_ctx_bind`, **no `weight_tile803k`**. xelab warnings: XPM `prog_full` unconnected (pre-existing CDC). |

CLOSEOUT `BASE=109b10da19a954809469d0dca334a197a521c0ba` is recorded, not re-verified (`.git/HEAD` not readable from this auditor process).

## SHA256.txt vs frozen bags (not live Get-FileHash)

| File | This bag | Cross-check |
|---|---|---|
| `a7ng_learned_prior_store.sv` | `AEF40392…08722C` | U7A-R1 SHA256.txt identical |
| `a7ng_persist_axi_bridge.sv` | `809C3C8E…0AC6FF` | unchanged vs prior FAIL bag |
| `a7ng_wdma_cdc.sv` | `9BE3A8CD…744485` | **changed** (prior FAIL bag `5AF2FBDA…`; named-wire patch) |
| `ddr_tile_dma.sv` | `20BAE36E…0AD7C5` | unchanged vs prior FAIL bag |
| `weight_tile803k.sv` | `8D602D10…51231D` | hashed; **not xvlog'd** this snapshot |

RTL_EDIT=YES on `m_go_ready` is consistent with the CDC digest change. Dest hash is extra evidence of a defaulted port, not of this xvlog snapshot.

## Accepted xsim.log lines (verbatim)

```text
U8-SOC-ROOTB-WDMA-00 START
CASE_A_STALL_GRANT req=1 grant=0 cyc=4
CASE_A_BOOT_STALL PASS boot_done=1 wr_ok=0 rd_ok=1 aw=0 ar=1
CASE_B_UPD_ACK_EQ_COMMIT PASS seq=3 ack=3 pdone=4 axi_aw=0
CASE_C_STORE_FULL done=0 nak=1 seq=32 ack=32
CASE_C_OVERFLOW_NAK PASS
CASE_D_FLUSH_STALL done_delta=33 aw_delta=65 b_ok_delta=65 wr_ok_delta=65
CASE_D_FLUSH_STALL PASS beats=65
CASE_E_FLUSH_RELOAD PASS
CASE_G_WDMA_STALL cmd_wr=1 s_go=1 m_done=1 b_ok=1 ovf=0 dma_st=0 under=1 ready=1
CASE_G_WDMA_STALL PASS ACK=1 BRESP=1
CASE_H_BACKPRESSURE ready=0 hold=1 ovf=0
CASE_H_WDMA_READY_WAIT ovf=0 cmd_wr=2 s_go=2 m_done=2 b_ok=2
CASE_H_WDMA_READY_WAIT PASS ACK=2 BRESP=2 ovf=0
CASE_I_MID_RST dma_st=1 hold=0 cmd_wr=4
CASE_I_AFTER_RST hold=0 ovf=0 dma_st=0 ready=1
CASE_I_POST_RST cmd_wr=1 s_go=1 m_done=1 b_ok=1 ovf=0
CASE_I_MID_TXN_RESET PASS ACK=1 BRESP=1
U8_SOC_ROOTB_WDMA_PASS
```

No `FIRST_DIVERGENCE`. Prior fail retained as `xsim_054007_fail.backup.log` (`WDMA_SILENT_DROP` cyc=5397).

## DUT vs PREREG unknown

PREREG primary unknown: on a **SoC-reachable** persist/WDMA path, do stall / eviction / mid-txn reset / overflow / flush-reload preserve **ACK ⇔ one BRAM/DDR commit** (no drop, no double-write)?

LOCK DUT (this lake):

```text
persist: a7ng_learned_prior_store → a7ng_persist_axi_bridge → tb_u8_persist_axi_mem
         c7_valid_i = 0 (matches arty_a7_ng_native_v1_ab_soc_top)
         grant = bag analog of persist_owner_ui (not full SoC mux)
WDMA:    a7ng_wdma_cdc → ddr_tile_dma → always-ready AXI stub
         dest-like one-cycle m_go after m_go_ready; no MIG
NOT:     arty_a7_ng_native_v1_ab_soc_top
NOT:     persist_gen_fast (DISCONNECTED)
NOT:     weight_tile803k (hashed, not xvlog'd)
NOT:     concurrent persist owner-mux + WDMA
```

Those modules are the objects SoC top wires (`u_persist_axi`, `u_wdma_cdc`, `u_wdma`). CLOSEOUT labels SOC_TOP / MIG **NOT instantiated** and `SOC_WDMA_ROOT_B = SLICE_XSIM_PASS (not full SoC; dest port unwired)`. That is honest. It is **not** a full-chip txn proof and **not** a PROGRAM license.

## RTL_FACT — named wire (this patch)

`rtl/board/a7ng_wdma_cdc.sv`:

```text
assign m_go_ready = m_rst_n && !cmd_hold_valid;
hold capture = m_go && m_go_ready
else if (m_go && cmd_hold_valid) cmd_hold_overflow <= 1  // illegal GO; payload not stored
```

TB `dest_pulse_go` waits `m_go_ready` then one-cycle `m_go`. CASE H: unowned first GO occupies hold and drops ready; overflow stays 0; after grant, second waited GO commits; cmd/s_go/m_done/BRESP = 2. Matches log. Prior `WDMA_SILENT_DROP` (second `m_go` with no ready) is gone on this producer.

Illegal `m_go` while hold occupied still sets overflow and **does not store** the new payload. That path was not stimulated this run (producer waits). METRICS `wdma_overflow=PASS` means **ovf=0 under dest-like wait**, not “overflow-with-drop still ACK⇔commit”. CLOSEOUT text is the honest one.

## Hunt

| Hunt | Result |
|---|---|
| FAIL hidden as PASS | **no.** Accepted `xsim.log` has `U8_SOC_ROOTB_WDMA_PASS` and no `FIRST_DIVERGENCE`. `vivado.log` `U8_SOC_ROOTB_WDMA_XSIM_OK`. CLOSEOUT/RESULTS/METRICS = PASS matching the log. |
| WDMA ACK=commit when only store XSim ran | **no.** Persist A–E **and** WDMA G/H/I ran on `a7ng_wdma_cdc`→`ddr_tile_dma`→always-ready stub. Claim is slice, not MIG / SoC top. |
| SoC top instantiated when it was not | **not claimed.** xvlog has no `arty_a7_ng_native_v1_ab_soc_top`. |
| Silicon / Gate14 / Q-head / NLU / OUT=653 / “LM understands TYPE_CLASS” | not claimed |
| CLASS_ID as token / NID / first-member | N/A; encoder / `native_ctx_bind` not in snapshot |
| TB inspects CLASS_ID to pick reward | no CLASS_ID / reward path in this TB |
| Host builds learn key / host counters nonzero | no; updates are TB `issue_upd`; no `n_host_tok` / winner / addr |
| BIT/PROGRAM/QHEAD performed | no |
| History rewrite | `xsim_054007_fail.backup.log` keeps the prior FAIL. Accepted log is a later run (05:57:24), not a rewrite of 05:40:07. |

## CLOSEOUT vs log

Allowed CLOSEOUT claim (persist slice A–E; WDMA stall G; dest-like ready-wait H; WDMA mid-txn reset I; marker `U8_SOC_ROOTB_WDMA_PASS`) is what the accepted log supports. `overclaim=false`.

Not proven (CLOSEOUT already lists; auditor agrees; **do not treat as closed**):

- `arty_a7_ng_native_v1_ab_soc_top` instantiate / owner-mux + WDMA + persist concurrent
- SoC top / `tiny_gpt803k_core` wiring `m_go_ready` → dest `dma_go_ready` (dest default `1`; core leaves the port open)
- `weight_tile803k` dest FSM in this xvlog snapshot
- persist_gen_fast repaired
- C7 as commit identity (bridge `c7_valid_i=0`; CASE_B uses store `commit_seq`/`ack_count` + no AXI on P_UPD)
- persist mid-txn reset (CASE_F present in `xsim_47900.backup.log`, not in the accepted run)
- MIG / silicon / Gate14 / BOARD_PASS / OUT=653

## Residuals (do not flip PASS → OVERCLAIM)

1. CASE_G prints `under=1` and still PASS. `ddr_tile_dma` underflow is sticky `!w_valid` while in W; beats can still complete. TB does not require `under=0`. WDMA BRESP identity is an always-ready stub, not MIG.
2. Persist grant in TB is a simplified `req && !grant_block` analog, not SoC `persist_owner_ui`.
3. CASE_B `pdone=4` vs `seq=ack=3` includes boot `persist_done`; not a hidden mismatch.
4. CASE_I `cmd_wr=4` is the **absolute** counter at mid-rst (G1+H2+I1); post-rst delta is 1. Not a double-write.
5. Live dest (`weight_tile803k` via `tiny_gpt803k_core`) still sees `dma_go_ready=1` until a later `SOC_TOP_EDIT` lake. That is **out of LOCK DUT**. This PASS does not prove the dest pin is driven on silicon.
6. `FILES_CHANGED` includes `weight_tile803k.sv` (defaulted `dma_go_ready`) beyond the named CDC wire. Dest is not in xvlog; default 1 keeps `SOC_TOP_EDIT=NO`. Extra file, not a hidden SoC edit.

## Verdict

**PASS.** `overclaim=false` `fraud=false` `logic_bug=false`.

Locked DUT (store+bridge | wdma_cdc+ddr_tile_dma, dest-like TB producer) showed ACK ⇔ one commit on stall / store-full NAK / flush-reload / WDMA ready-wait / WDMA mid-txn reset. Prior `WDMA_SILENT_DROP` is closed **on this slice**.

This PASS is **SLICE_XSIM_PASS**, not full-chip Root-B, not a PROGRAM license. Do not auto-open U8R / U9S / U9I / U9P / U10. Do not declare BOARD_PASS or GATE14_PASS. Do not reseat `1F0F2ABB` / `9CA2B30D` / `F24150BD` / `3A7EF204`. Semantic LM stays `LM_CHECKPOINT_CONTEXT_MISMATCH`.

## Fix hint (not this lake; auditor does not patch)

Dest `dma_go_ready` remains default 1 in `tiny_gpt803k_core` / SoC (`SOC_TOP_EDIT=NO`). Wiring CDC `m_go_ready` to dest is a later owner-opened lake. Cycle watchdog, not ns overflow. Do not git add MIG or `a7lm06_wmem.hex`.

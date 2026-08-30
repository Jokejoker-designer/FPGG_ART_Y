# GO-POP-GATE-00 — CLOSEOUT

**Gate:** `GO-POP-GATE-00`  
**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` only  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**Prereg:** `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-POP-GATE-00_PREREG.md`  
**PROGRAM:** NO. **C_FIX on Cursor tree:** NONE. **JTAG:** NO.  
**Not** OPEN-CTRL. **Not** `graph_late_materialize_00`. **Not** 664/744.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | CONTROL `cmd_rd_en` has no `s_owner` |
| UNKNOWN | After owned enqueue, drop `m_owner` before slave pop: does `s_go` stay 0 while `s_owner=0`? Later owned window still pop? |
| H_CANDIDATE | CLASS=`POP_GATED` (`DROP_S_GO=0` and `GRANT_S_GO=1`) |
| H_RIVAL | `s_go` while `s_owner=0` (`DROP_S_GO=1`) or owned window never pops (`GRANT_S_GO=0`) |
| FALSIFIER | second wire in same hunk; edit `cmd_wr_en`; xvlog Cursor files; SoC instantiate; program |
| UNIT | owned enqueue → drop owner → 2000 `s_clk` watch → re-grant |
| CONTROL | `a7ng_wdma_cdc.sv` SHA `A036F216…D56E3F` (post ISSUE-GATE) |

## One wire (only RTL edit)

```text
- assign cmd_rd_en = s_rst_n && (cmd_st == C_IDLE) && !cmd_pend && !cmd_empty &&
-                    (!s_busy || ghost_busy_rel);
+ assign cmd_rd_en = s_rst_n && (cmd_st == C_IDLE) && !cmd_pend && !cmd_empty &&
+                    (!s_busy || ghost_busy_rel) && s_owner;
```

`cmd_wr_en` **not edited** this gate (remains `m_rst_n && m_go && m_owner && !cmd_full`).  
tile / top / DMA / QSTAR / frozen 01R/02M/LM-06: **not edited**.

## SHA256

| File | When | SHA256 |
|------|------|--------|
| `rtl/board/a7ng_wdma_cdc.sv` | BEFORE (CONTROL) | `A036F21644EF29E4DA9A9702D01CE26E7AB6994EEFF634A0110F56352DD56E3F` |
| `rtl/board/a7ng_wdma_cdc.sv` | AFTER | `C02F0D5403AADEAF21ED161116BE607D0A45B3180544995D3623F03A8B66DDEE` |
| `tests/xsim/tb_go_pop_gate_00.sv` | TB | `EAD0FAD4839EABCB35504C9C734B069E18019EFE05B99A1A23E28BE5F1C467C4` |

## Isolated TB

- Instantiates **only** `a7ng_wdma_cdc` as `u_cdc`.
- Clocks: `m_clk` period 80 ns (half=40), `s_clk` period 10 ns (half=5). Both rst released + XPM recovery.
- Hold `s_busy=1` / `s_dma_idle=0` during enqueue so pop cannot race the owner drop; then stub `s_busy=0`, `s_done=0`, `s_dma_idle=1` so pop is legal when owned.
- Probe: hierarchical `u_cdc.cmd_empty` / `cmd_rd_en` / `cmd_wr_en` (visible; **no** debug export added).
- Pulse: `m_owner=1`, 1-cycle `m_go` (issue-gated enqueue). Wait `cmd_empty=0`.
- Drop `m_owner=0`. Wait `s_owner==0`. Watch 2000 `s_clk` for `s_go`.
- Raise `m_owner=1`. Wait `s_owner=1`. `GRANT_S_GO=1` if `s_go` while `s_owner=1` (first command remained in FIFO; extra `m_go` not needed).

No QSTAR on SoC. No Cursor paths in xvlog.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`xvlog` + `xelab -mt off -O0 -L xpm` + `glbl` + `xsim -runall`) |
| CLASS | **POP_GATED** (`DROP_S_GO=0` and `GRANT_S_GO=1`) |
| H_CANDIDATE | **SUPPORTED** under this isolated unit |
| H_RIVAL | **FALSIFIED** under this isolated unit |
| UNIT_PASS | **YES** (SHA recorded + TB finished) |
| EXISTENCE | **not claimed** |
| pred=664 | **not claimed** |
| BOARD_PASS | **not claimed** |

`UNIT_PASS` ≠ existence ≠ `pred=664`.

## Required prints (`xsim.log`)

```text
DROP_S_GO=0
GRANT_S_GO=1
CLASS=POP_GATED
GO_POP_GATE_00_UNIT_PASS
```

## Transcript tail (authoritative)

Workdir: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-POP-GATE-00/`  
Wrapper: `run_tb_go_pop_gate_00.bat`  
Log: `xsim.log`

```text
GO-POP-GATE-00 START m_period=80ns s_period=10ns
RESET_RELEASED T=1960000
RECOVERY T=5955000 m_owner=1 s_owner=1 cmd_empty=1 cmd_wr_en=0 cmd_rd_en=0
PULSE_OWNED_ENQ T=6040000 m_owner=1 m_go=1 cmd_wr_en=1 cmd_full=0
ENQ_WAIT T=6200000 cmd_empty=0 saw_empty=1 s_owner=1 s_go=0 cmd_rd_en=0 s_busy=1
DROP_M_OWNER T=6200000 m_owner=0
S_OWNER_LOW T=6235000 s_owner=0 cmd_empty=0 cmd_rd_en=0 s_go=0
POP_LEGAL_STUB T=6235000 s_busy=0 s_dma_idle=1
DROP_WIN_END T=26235000 DROP_S_GO=0 cmd_empty=0 cmd_rd_en=0 s_owner=0
RAISE_M_OWNER T=26235000 m_owner=1
S_OWNER_HIGH T=26315000 s_owner=1 cmd_empty=0 cmd_rd_en=1
DROP_S_GO=0
GRANT_S_GO=1
CLASS=POP_GATED
GO_POP_GATE_00_UNIT_PASS
EXISTENCE=not_claimed
PRED664=not_claimed
$finish called at time : 46315 ns : File ".../tests/xsim/tb_go_pop_gate_00.sv" Line 206
INFO: [Common 17-206] Exiting xsim at Sat Aug 29 21:07:49 2026...
```

xelab warnings: unused XPM `prog_full` only (pre-existing DUT). Hierarchical probe succeeded. First command remained in FIFO across the drop window (`cmd_empty=0`); extra owned `m_go` not used.

## Explicitly not done

- No `open_hw_manager` / program / COM
- No Cursor tree / MAIN STATUS dispatch
- No `cmd_wr_en` edit this gate
- No QSTAR instantiate on SoC
- No frozen LM-06 / 01R / 02M rebuild
- No tile / top / DMA RTL

## NEXT_ONE_UNKNOWN

Not this bag. Do not start the next gate from this closeout.

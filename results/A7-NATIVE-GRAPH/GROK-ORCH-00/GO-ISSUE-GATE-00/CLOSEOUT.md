# GO-ISSUE-GATE-00 — CLOSEOUT

**Gate:** `GO-ISSUE-GATE-00`  
**Date:** 2026-08-29  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` only  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**Prereg:** `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-ISSUE-GATE-00_PREREG.md`  
**PROGRAM:** NO. **C_FIX on Cursor tree:** NONE. **JTAG:** NO.  
**Not** OPEN-CTRL. **Not** `graph_late_materialize_00`. **Not** 664/744.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Unowned `m_go` can enqueue (P0-A) on CONTROL CDC |
| UNKNOWN | After AND `m_owner`, does unowned `m_go` print `CMD_WR_EN=0` while owned prints `CMD_WR_EN=1`? |
| H_CANDIDATE | CLASS=`ISSUE_GATED` |
| H_RIVAL | unowned still `CMD_WR_EN=1` |
| FALSIFIER | second wire in same hunk; xvlog Cursor files; SoC instantiate; program |
| UNIT | one unowned pulse, then one owned pulse |
| CONTROL | `a7ng_wdma_cdc.sv` SHA `FE13D1BB…BF92D7` before the wire (`140345e`) |

## One wire (only RTL edit)

```text
- assign cmd_wr_en = m_rst_n && m_go && !cmd_full;
+ assign cmd_wr_en = m_rst_n && m_go && m_owner && !cmd_full;
```

`git diff --stat`: `rtl/board/a7ng_wdma_cdc.sv | 2 +-`  
`cmd_rd_en` / tile / top / DMA / QSTAR / frozen 01R/02M/LM-06: **not edited**.

## SHA256

| File | When | SHA256 |
|------|------|--------|
| `rtl/board/a7ng_wdma_cdc.sv` | BEFORE (CONTROL) | `FE13D1BBECB95D88BCBAC525BE680AE5281F6EA3FD0B1E729D7E781884BF92D7` |
| `rtl/board/a7ng_wdma_cdc.sv` | AFTER | `A036F21644EF29E4DA9A9702D01CE26E7AB6994EEFF634A0110F56352DD56E3F` |
| `tests/xsim/tb_go_issue_gate_00.sv` | TB | `C48D13AB18F1252FB1CADEBAE80D12EDBBEDA2A141F41934EDB3CDD85C9989CA` |

## Isolated TB

- Instantiates **only** `a7ng_wdma_cdc` as `u_cdc`.
- Stubs: `s_busy=0`, `s_done=0`, `s_dma_idle=0`.
- Clocks: `m_clk` half=40 ns (12.5 MHz), `s_clk` half=5 ns (100 MHz). Both rst released + XPM recovery.
- Probe: hierarchical `u_cdc.cmd_wr_en` (visible; **no** debug export added).
- Pulse 1: `m_owner=0`, 1-cycle `m_go`.
- Pulse 2: `m_owner=1`, 1-cycle `m_go`.

No QSTAR on SoC. No Cursor paths in xvlog.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`xvlog` + `xelab -mt off -O0 -L xpm` + `glbl` + `xsim -runall`) |
| CLASS | **ISSUE_GATED** (`CMD_WR_UNOWNED=0` and `CMD_WR_OWNED=1`) |
| H_CANDIDATE | **SUPPORTED** under this isolated unit |
| H_RIVAL | **FALSIFIED** under this isolated unit |
| UNIT_PASS | **YES** (SHA recorded + TB finished) |
| EXISTENCE | **not claimed** |
| pred=664 | **not claimed** |
| BOARD_PASS | **not claimed** |

`UNIT_PASS` ≠ existence ≠ `pred=664`.

## Required prints (`xsim.log`)

```text
CMD_WR_UNOWNED=0
CMD_WR_OWNED=1
CLASS=ISSUE_GATED
GO_ISSUE_GATE_00_UNIT_PASS
```

## Transcript tail (authoritative)

Workdir: `results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-ISSUE-GATE-00/`  
Wrapper: `run_tb_go_issue_gate_00.bat`  
Log: `xsim.log`

```text
GO-ISSUE-GATE-00 START m_period=80ns s_period=10ns
RESET_RELEASED T=1960000
RECOVERY T=5955000 cmd_full=0 cmd_wr_en=0
PULSE_UNOWNED T=6040000 m_owner=0 m_go=1 cmd_wr_en=0 cmd_full=0
PULSE_OWNED T=6920000 m_owner=1 m_go=1 cmd_wr_en=1 cmd_full=0
CMD_WR_UNOWNED=0
CMD_WR_OWNED=1
CLASS=ISSUE_GATED
GO_ISSUE_GATE_00_UNIT_PASS
EXISTENCE=not_claimed
PRED664=not_claimed
$finish called at time : 7 us : File ".../tests/xsim/tb_go_issue_gate_00.sv" Line 145
INFO: [Common 17-206] Exiting xsim at Sat Aug 29 21:01:15 2026...
```

xelab warnings: unused XPM `prog_full` only (pre-existing DUT). Hierarchical probe succeeded.

## Explicitly not done

- No `open_hw_manager` / program / COM
- No Cursor tree / MAIN STATUS dispatch
- No second fence wire (`cmd_rd_en` / `s_owner` / ready-gate)
- No QSTAR instantiate on SoC
- No frozen LM-06 / 01R / 02M rebuild

## NEXT_ONE_UNKNOWN

Prereg DAG: **E2 `GO-POP-GATE-00`** after this UNIT_PASS. Not this bag.

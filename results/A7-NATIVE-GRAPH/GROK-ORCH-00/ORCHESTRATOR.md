# Orchestrator — Native AI on grok-orch-00

**Goal (human, 2026-08-29):** hoàn thiện Native AI **trên nhánh này**.  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Branch:** `research/native-ai-v1-grok-orch-00` @ `140345e` + untracked QSTAR/fence.  
**AI never stamps BOARD_PASS.**  
**PROGRAM=NO** until `com12_authorized_gate` **names this branch**.  
**Cursor board / close664 / MAIN STATUS dispatch: out of scope.**

```text
EXISTENCE (this tree)  = XSim vehicle prints pred=664, then (later) UART
                         NATIVE_V1_EXIST_ROW,pred=664 on a bit built HERE.
QUALITY / encoder Si / Kidi / 800k / Mini-AI = after existence.
QSTAR-COFIT            = ADDON-LAB parallel. Never glued onto SoC to “fix” 664.
XSim ≠ board. 744 ≠ 664. UNIT_PASS ≠ BOARD_PASS.
```

## DAG (this tree only)

```text
Q  QSTAR-V0 + ctrl+qhead co-sim  DONE  ADDON-LAB (not SoC)

E0 A-FAST SIM_FULL=1 pred=664     ARCHIVE (2026-08-24) — not board
E1 GO-ISSUE-GATE-00               DONE  ISSUE_GATED
E2 GO-POP-GATE-00                 DONE  POP_GATED
E3 GO-READY-GATE-00               DONE  READY_GATED
E3b GO-REQUEST-PENDING-00         DONE  REQUEST_HELD
E3c GO-TWOPASS-EMB-00             DONE  POS→TOK switches=1 (core 355182A7…)
E3d GO-GRANT-QUIESCE-00           DONE  QUIESCE_HOLD
E5 GO-EXISTENCE-SOC-00            DONE  BIT_OK sha256=B64B2649… PROGRAM=NO
E5b GO-AFAST-REPLAY-00            DONE  A_FAST pred=664 (XSim, 10:17)
E6 UART                           PROGRAM_DONE; row pred=371 ≠ 664; BOARD_PASS not_claimed
then encoder / Kidi / A1 / scale / Mini-AI / GlassBox
```

Do **not** Task Cursor. Do **not** copy their dirty `rtl/`. Re-implement fence **from published class law** on this checkout.

## Sealed this session (this tree)

| Track | Gate | Class | PROGRAM |
|-------|------|-------|---------|
| E | `GO-ISSUE-GATE-00` | **ISSUE_GATED** | NO |
| E | `GO-POP-GATE-00` | **POP_GATED** | NO |
| E | `GO-READY-GATE-00` | **READY_GATED** | NO |
| E | `GO-REQUEST-PENDING-00` | **REQUEST_HELD** | NO |
| E | `GO-TWOPASS-EMB-00` | POS→TOK `RG_SWITCHES=1` | NO |
| E | `GO-GRANT-QUIESCE-00` | **QUIESCE_HOLD** | NO |
| Q | `QSTAR-CTRL-QHEAD-00` | **UNIT_PASS** `best_action=3` | NO |

## Product SHA (this checkout, 2026-08-30)

| File | SHA256 | Law |
|------|--------|-----|
| `a7ng_wdma_cdc.sv` | `E951F1F3…AA582` | REQUEST_HELD + `cmd_rd_en && s_owner` |
| `arty_a7_ng_native_v1_ab_soc_top.sv` | `57BD7B4D…C717F` | READY ANDs + QUIESCE_HOLD grant |
| `tiny_gpt803k_core.sv` | `355182A7…8F3DD7` | ST_EMB_POS then ST_EMB_TOK |
| `ddr_tile_dma.sv` | `20BAE36E…0AD7C5` | UNCHANGED |
| `weight_tile803k.sv` | `A4E5FEAC…32FCF1` | UNCHANGED |

## Board (physical, 2026-08-30)

COM12 `210319BE776EB` Status=OK. Converter A (JTAG `210319BE776EA`) Status=OK.  
**Attach ≠ token.** Leftover LONGBOOT `9DC0F8DF` / two-pass `15B0E502` **forbidden**.  
AI does not stamp BOARD_PASS. No `open_hw_manager` until a **new** `com12_authorized_gate` names `research/native-ai-v1-grok-orch-00`.

A foreign Vivado batch (close664 `E2R-OWNER-FENCE-INTEGRATE-00`, PID observed 175800) occupies the license. Grok-orch impl **waits** for that process; it does **not** steal JTAG.

## Now

COM12 back (human). D_GO **1-cycle pulse** on this tile (`4D90838C…`). XSim3 `GO=1152 DONE=1152 GO_WHILE_BUSY=0`. Impl `GO-DGO-PULSE-SOC-00` running. Old bit `B64B2649` (level-hold, pred=371) will not be reprogrammed. New bit after BIT_OK, then arm COM12. Not BOARD_PASS.


## Forbidden

Cursor DECIDE · their tile revert · SoC instantiate `qstar_*` · leftover LONGBOOT/two-pass program · 664/744 mix · `graph_late_materialize_00` as existence.

# GROK-ORCH-00 — index

| File | Source |
|------|--------|
| `research/NATIVE_AI_GROK_ORCH_LANE.md` | Lane charter |
| `CLOSE_DAG.md` | Plan agent close DAG |
| `ENCODER_SURVEY.md` | Explore 03E / H5 |
| `EXISTENCE_SURVEY.md` | Explore fence / LONGBOOT |
| `RESOURCE_OPT_PLAN.md` | Resource envelope + ranked trades (no board QoR) |
| `QSTAR_V0_PLAN.md` | QSTAR-HEURISTIC-V0 start |
| `QSTAR_V0_XSIM.md` | `tb_qstar_ctrl_v0` UNIT_PASS |
| `QSTAR_QHEAD_XSIM.md` | `tb_qstar_qhead_serial_v0` UNIT_PASS |
| `QSTAR_CTRL_QHEAD_XSIM.md` | `tb_qstar_ctrl_qhead_v0` UNIT_PASS (ctrl+qhead co-sim) |
| `ORCHESTRATOR.md` | Native AI DAG on this tree only |
| `GO-ISSUE-GATE-00_PREREG.md` | E1 one-wire `cmd_wr_en && m_owner` |
| `QSTAR-CTRL-QHEAD-00_PREREG.md` | QSTAR ctrl+qhead co-sim ADDON-LAB |
| `research/QSTAR_NATIVE_FPGA_RESEARCH_GUIDE_2026-08-29.md` | Ingested human guide |

Mailbox for Cursor: `D:\Jetking_sem4\SEM_4\arty-a7-online-lm\.agents\handoff\GROK_ORCH_LANE.md`

| `G14-PERSISTENCE-IDENTITY-00/` | XSim PASS: FLUSH/KILL/RELOAD restores HOLD_A C9 `8382238122802120`. PROGRAM=NO. GATE14_PASS=NO. Do not reprogram `1F0F2ABB`. Next=`G14-RESET-RETRAIN-00`. |
| `G14-RESET-RETRAIN-00/` | XSim PASS: A→TRESET hides A→B→A not resurrected. SoC OUT 653/689/237/60. PROGRAM=NO. GATE14_PASS=NO. RESET_RETRAIN_BOARD=not_claimed. |
| `G14-TEACHER-OFF-NATIVE-CAUSALITY-00/` | Gate T XSim PASS: host wires 0, learn=0 freeze=1, HOLD_A C9 oracle. OUT observed not scored. PROGRAM=NO. Next=Gate L LM-06. |
| `G14-LM06-ACTIVE-CHAIN-00/` | Gate L XSim `LM_ACTIVE_CHAIN_PROVEN`. C9→bind→start_fwd→TinyGPT st/busy→pred=OUT 653. UNREL perturb 689. PROGRAM=NO. GATE14_PASS=NO. |
| `G14-FINAL-GAP-RECONCILIATION-00/` | READ-ONLY §14: 56 boxes. PASS=22 PASS_NARROW=20 OPEN_BOARD=7 OPEN_METRIC=5 FAIL=0. Reset/retrain already BOARD on 1F0F2ABB. Root B does not block a box. PROGRAM=NO. |
| `G14-OPEN-METRIC-00/` | READ-ONLY on `F24150BD`. C5 PASS (ceilings≠throughput). P3/P4/M7 INCONCLUSIVE. M10 not_proven (no silent N/A). OPEN_METRIC 5→4. PROGRAM=NO. GATE14_PASS=NO. Canonical: preboard `results/.../G14-OPEN-METRIC-00/`. |
| `G14-METRIC-MEASURE-01/` | NO RTL/BIT/PROGRAM. P3 util=0.007063 MIG_XSIM PASS. P4 stall=0 MIG_XSIM PASS. M7 1024 B/SOA query + 0 B/C9 exam PASS. M10 KEEP_OPEN. OPEN_METRIC 4→1. GATE14_PASS=NO. |
| `P2-GATE14-C1-UART-RX-COMMAND-01/` | UART RX command path. Parent FAIL_C1 preserved. Codex-named bit `4569115F…`; live filename `46E11DA9…`. PROGRAM=NO. |
| `P2-GATE14-UART-CMD-BOARD-PREFLIGHT-02/` | Read-only preflight. Token later granted. |
| `P2-GATE14-UART-CMD-BOARD-PROGRAM-20-00/` | Programmed SHA `4569115F…` once. pred=249. C1 MODE 5→8. C10 OUT=0. BOARD_PASS=not_claimed. |
| `P2-GATE14-TXN-ECHO-EXAM-HOST-01/` | PROGRAM=NO. Decoder 8-byte PASS offline. Live COM12 no CFRAME 15s. WAIT_NEW_HUMAN_TOKEN. |
| `P2-GATE14-TXN-ECHO-EXAM-BOARD-01/` | Reprogrammed SHA `4569115F…`. pred=249. LMDN_NEVER 60s. wait/decoder FALSIFIED. BOARD_PASS=not_claimed. |
| `P2-GATE14-WIDTH-CORRECT-EXAM-BOARD-01/` | SHA `46E11DA9…` once. pred=249. LMDN_NEVER same as R0. width-fix insufficient. BOARD_PASS=not_claimed. |
| `P2-GATE14-LM-START-WIRE-01/` | Unique bit `A0B338E0…` once. PASS_NARROW_C10_G5_MATCH (2-lesson, cons=2, OUT 549/861/237). Not Gate14-20. BOARD_PASS=not_claimed. |
| `P2-GATE14-20FACT-RESIDENT-02/` | PROGRAM=NO resident `A0B338E0…`. 20 A lessons C5 2→22. STOP HOLD_A OUT=733 want=549. CLASS=FAIL_DIVERGENCE. GATE14_PASS/BOARD_PASS=not_claimed. |
| `P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03/` | PROGRAM=NO FAST. C9 graph TopK after G4 prior lookup. XSim PASS 20 distinct facts. OOC WNS+51.6 DSP=0. LM RTL not run; unique bit not created. BOARD_PASS=not_claimed. |
| `P2-GATE14-C9-SOA-LM-BIT-04/` | C9 SoA+LM XSim bag. Even-only GRAPH_Q handshake races; superseded by FIX-05. PROGRAM=NO. |
| `P2-GATE14-C9-CMD-ACCEPT-FIX-05/` | Handshake = cmd_valid&&cmd_ready; TRESET wait GEN+1; vis_w 20 B in 32 slots. XSim PASS_NARROW. PROGRAM=NO. |
| `P2-GATE14-C9-SOC-COFIT-BIT-06/` | Full-chip C9 SoC. Bit SHA `B0F64E6C…`. Codex rejected: ja[7:0] NSTD-1/UCIO-1 waived. PROGRAM=NO. |
| `P2-GATE14-C9-SOC-IO-SAFE-BIT-07/` | Unique IO-safe bit SHA `3A7EF204…`. JA removed. NSTD=0 UCIO=0. Programmed once COM12. CLASS=SILICON_FAIL_DIVERGENCE HOLD_A OUT=748 want=653. GATE14_PASS=NO. BOARD_PASS=not_claimed. |
| `CURRENT_GATE14_STATUS.md` | **CURRENT** pointer. Epoch BOARD_CLOSED on `1F0F2ABB` commit `9656245`. Next=`G14-PERSISTENCE-IDENTITY-00`. GATE14_PASS=NO. PROGRAM=NO. |
| `G14-EPOCH-REBIRTH-BIT-00/` | Unique bit SHA `1F0F2ABB…` programmed **once** JTAG `210319BE776EA`. CLASS=`EPOCH_CHAIN_CLOSED_ON_BOARD`. E0–E5 exact 653/689/237/60 C9 `8382238122802120` boot GEN=1. GATE14_PASS=NO. Do not reprogram. |
| `G14-ROOT-B-TXN-AUDIT-00/` | Read-only Root B. CLASS=`ROOT_B_PARTIALLY_CONFIRMED`. No RTL. WDMA `WDMA_PROTOCOL_AMBIGUOUS`. ACK≠commit latent. Next persistence identity. |
| `CODEX-AUDIT-GATE14-C9-SILICON-HOLD-A-748.md` | Codex audit branch pointer. Frozen oracle SHA `062932B3…`. Do not retarget. Do not auto-reprogram. |

| `CODEX_GATE14_BALANCED_MVP_HANDOFF_20260831.md` | Prompt SHA `C0ACFDE7…` — R2=`MINHEAP-AREA-CLEAN-00` not Serial |
| `TERMGEN-FOLD6-16LANE-00/` | Gate R1 fold6 16-lane; PROGRAM=NO |
| `TERMGEN-FOLD6-BIT-00/` | R1 full-chip impl seat; PROGRAM=NO |
| `MINHEAP-AREA-CLEAN-00/` | Gate R2 minheap area-clean; never import Serial |
| `MINHEAP-AREA-CLEAN-BIT-00/` | R2 full-chip impl seat LABEL=MINHEAP; PROGRAM=NO |

| `GO-H4-SIMFULL0-00/` | XSim H4 MATCH_664 pack=`3b392b291b190b09` (stub ≠ board) |
| `GO-H2PACK-SOC-00/` | UART PACK=16hex + stall-idle + bind hold; impl to BIT_OK; PROGRAM=NO |

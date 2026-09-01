# Same-bit Gate14 20-fact sequence — prepared paths only

**PROGRAM=NO.** Not executed. Not Teacher-Off. Not BOARD_PASS. XSim ≠ board.

Candidate bit (only legal program image after human token):

```text
results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-WDMA-RELEASE-CDC-AUDIT-03/arty_a7_ng_native_v1_grok_orch_p2_wdma_release_cdc_audit_03.bit
SHA256=6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A
```

Do **not** use D5B / F06C / 2E18 / AOS / mailbox / pred=664 leftovers.

## Frozen 20-fact corpus (identical CONTROL vs V2)

```text
results/A7-NATIVE-GRAPH/TRAIN-V2/corpus_20.json
corpus_id=train_v2_facts_20
n_facts=20
SHA256=23A4B5039CB80FECC338DF26BAB4E31EC8B314F7DBC178AD3AA572EA06963F8E
```

Facts f01–f20 (FPGA/LUT/FF/BRAM/DSP/DDR/MIG/Arty/teacher/blind/hotset/frontier/bomb/contradiction/LM-06). Host still must not send hashes, gradients, weights, addresses, winners, or next-token.

## Capture paths (this bag)

| Step | Path | When |
|------|------|------|
| UART arm marker | `LISTEN_START.txt` | after human token, before program |
| Boot UART transcript | `uart_gate14_preflight.txt` | same COM12 session |
| 20-fact exam transcript | `uart_gate14_20fact.txt` | after boot capture; **not created this gate** |
| 20-fact result JSON | `gate14_20fact_result.json` | after exam; **not created this gate** |

## Sequence (after human token only)

1. Re-hash bit `6975AB75…`. Refuse any other SHA.
2. Arm COM12 115200 (`capture_uart_gate14_preflight.py --i-have-human-token`).
3. Program exclusive TCL (JTAG `210319BE776EA`, device `xc7a100t_0`).
4. Capture boot stream. Expected **existence** markers (not Teacher-Off):
   - `BOOT` / `MIG_OK` / `WMEM_OK` if printed
   - `TOPK=` / `PACK=` A-FAST `3B392B291B190B09`
   - `POISON=0`
   - `CORE_DONE`
   - `NATIVE_V1_EXIST_ROW,pred=249`  (LN-FIX). **Refuse pred=664.**
5. Gate14 20-fact teacher-off exam uses the frozen corpus above, then:
   - teacher=0 external_LLM=0 learn=0 freeze=1
   - host_semantic_cue=0 host_winner=0 host_episode_address=0 host_next_token=0 host_weight_writes=0
   - held-out wording / unrelated reject / contradiction probe
6. G5 XSim four-query oracle (not silicon, not 20-fact UART) remains:
   - HOLD_A OUT **549** pack `0706050403010002`
   - UNREL OUT **861** pack `0f0e0d0c0b0a0908`
   - CONTRA OUT **549** (same pack as A)
   - HOLD_B OUT **237** pack `0f0e0d0c090b080a`
   - oracle file SHA `A4F6998E…F51623`

## Honesty

This SoC UART is a **print stream** after one boot query. A full 20-fact teacher-off packet protocol on silicon is **not claimed present** on this bit. Step 5 is the Gate14 exam path to run only after human program + captured boot. This preflight writes the paths and frozen corpus pointer; it does not run the exam and does not stamp Teacher-Off / Gate14 / BOARD_PASS.

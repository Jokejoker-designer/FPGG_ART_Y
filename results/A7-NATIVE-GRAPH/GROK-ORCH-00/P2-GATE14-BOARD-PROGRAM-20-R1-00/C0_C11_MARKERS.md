# C0–C11 from live UART (UART_SLIM existence stream)

Evidence class: **BOARD** for printed lines. **NOT_OBSERVED** where UART_SLIM does not print.  
Host RX `uart_txd_in` is `unused_rx` on this bit — host cannot inject TRAIN/FLUSH/RELOAD/20-fact packets.

| ID | Required | Observed | Class |
|----|----------|----------|-------|
| C0 | bit SHA / same bit | SHA `6975AB75…` programmed once; UART after that program | BOARD |
| C1 | TRAIN MODE=5, FREEZE MODE=8 live | **NOT_OBSERVED** — no MODE= line | first divergence |
| C2 | FPGA ANCH distinct | **NOT_OBSERVED** | |
| C5 | CONSUME / DROP_FREEZE=5 | **NOT_OBSERVED** | |
| C6 | contextual delta | **NOT_OBSERVED** | |
| C7 | MIG/AXI ACK BRESP/RRESP/RLAST | **NOT_OBSERVED** on UART; `MIG_OK` printed (calib, not persist ACK) | |
| C8 | GEN/SDIG never 0 | **NOT_OBSERVED** | |
| C9 | TOPK/PACK/POISON/typed R | TOPK=`3B392B291B190B09` PACK=`3B392B291B190B09` POISON=0. Scores/R1S/R1R/R1O/learned movement **NOT_OBSERVED** | BOARD partial |
| C10 | unique LMST→LMDN, OUT, no X | **NOT_OBSERVED** (no OUT=549/861/237) | |
| C11 | ADIG≠BDIG, A forgotten | **NOT_OBSERVED** | |

A-FAST existence (not 20-fact exam): `NATIVE_V1_EXIST_ROW,pred=249` matches patched LN-FIX / pack `3b392b291b190b09`. Historical pred=664 **not** seen.

20-fact sequence (RESET→TRAIN A→FLUSH→BRAM loss→RELOAD→FREEZE→held-out/unrelated/contra→TRAIN_RESET→B…) **not executed** — no host command path on this bit. Frozen corpus not sent (legal: host must not send hashes/winners/addresses).

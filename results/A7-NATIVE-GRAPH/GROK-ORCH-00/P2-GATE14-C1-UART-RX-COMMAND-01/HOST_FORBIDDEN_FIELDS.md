# Host forbidden fields — hard FAIL if accepted as command payload

- node index / idx / winner / way
- memory address / delta / gradient / updated weight
- subject / relation / object
- native confidence / contradiction flag
- semantic cue / anchor / Top-K / score
- query/path generation / next token / final answer / LM output
- GEN / SDIG / ADIG / BDIG
- direct MODE bits

Host may send: query tokens, TRAIN/FREEZE/FLUSH/KILL/RELOAD/RESET sequencing, reward ∈ [-3,+3], txn echo (must match FPGA txn).

Live MODE is FPGA-only (`C_TRAIN`→5, `C_FREEZE`→8).

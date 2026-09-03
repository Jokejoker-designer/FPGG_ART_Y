# BOARD — G14-EPOCH-REBIRTH-BIT-00

```text
CLASS              = EPOCH_CHAIN_CLOSED_ON_BOARD
PROGRAM_ATTEMPTS   = 1
PROGRAM_RESULT     = OK
FIRST_DIVERGENCE   = NONE
REACHED            = E5
GATE14_PASS        = NO
BOARD_PASS         = not_claimed
NATIVE_V1_MINI_AI_BOARD_PASS = NO
oracle_retarget    = NO
reprogram          = NO
```

One JTAG program of unique bit `1F0F2ABB…`. UART armed before program.
Stopped only after E0–E5 all matched. Did **not** declare Gate14 pass.

---

## Pin

```text
BIT_SHA256   = 1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
JTAG         = localhost:3121/xilinx_tcf/Digilent/210319BE776EA  xc7a100t_0
UART         = COM12 @ 115200
LISTEN_START = 2026-09-03T15:14:56+07:00
PROGRAM_END  = 2026-09-03T15:15:22+07:00
JTAG_DONE    = 2026-09-03T15:15:42+07:00
UART_RAW     = BOARD/uart_raw.bin  27994 bytes  1260 CFRAMEs
UART_SHA256  = F7BCC0B130C95AA52F3757038F18210071EEE15618CCA74E758F4DF46DD47267
```

---

## E0–E5

| CKPT | Result | Evidence |
|------|--------|----------|
| E0 BOOT | PASS | C0=`34314347C00114A7` MODE=5 |
| E1 GEN legal | PASS | boot C8 GEN=**1** (not `FFFFFFFF`) |
| E2 semantic commits | PASS | A graph=20 rew=20 cons 0→20 txn 1→20 addr 50987008…50987312 GEN stayed 2 |
| E3 HOLD_A C9 | PASS | `8382238122802120` |
| E4 HOLD_A OUT | PASS | **653** LMST=1 LMDN=1 X=0 MODE=8 |
| E5 U/C/B | PASS | OUT 689 / 237 / 60 ; C9 `8786858483828180` / `2322832182208180` / `8382438142804140` |

Vs fail bit `3A7EF204` (same COM12, same JTAG, programmed once historically):

```text
3A7EF204  boot GEN=FFFFFFFF  HOLD_A C9=2322838281802120  OUT=748
1F0F2ABB  boot GEN=1         HOLD_A C9=8382238122802120  OUT=653
```

Historical P_BOOT / dirty-DRAM / illegal epoch causal chain is **CLOSED ON BOARD**.

---

## What this is not

- Not `GATE14_PASS`. Teacher-off, reset/retrain as Gate14 acceptance,
  persistence identity beyond this exam, LM active-chain, and remaining
  checklist items stay open.
- Not same physical placement as `3A7EF204`. Observability-only TOP + new impl.
- GEN after TRAIN_RESET was 2, after forget 3 (legal, ≤ WRAP_LIMIT=6).
  Forget HOLD_A produced OUT=237 pack=CONTRA (not the HOLD_A oracle) — expected
  in this exam, not a divergence.

Do not program this bit a second time. Do not retarget the oracle.

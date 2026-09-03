# CURRENT_GATE14_STATUS

```text
STATUS_CLASS = CURRENT
as_of        = 2026-09-03
commit       = 9656245cc05072d6299611c847eecc697baf4212
```

This file is the **live pointer** for a new session. It does not erase
August roll-ups. Those are `HISTORICAL` / `SUPERSEDED` relative to this
September BOARD closure.

---

## Frozen board artifact (do not reprogram)

```text
BIT      = arty_a7_ng_native_v1_g14_epoch_rebirth_00.bit
SHA256   = 1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
UART_SHA = F7BCC0B130C95AA52F3757038F18210071EEE15618CCA74E758F4DF46DD47267
PROGRAM_ATTEMPTS = 1
CLASS    = EPOCH_CHAIN_CLOSED_ON_BOARD
evidence = G14-EPOCH-REBIRTH-BIT-00/BOARD/RESULTS.md
```

E0–E5 exact: boot GEN=1, 20/20, C9 `8382238122802120`, OUT 653/689/237/60.

---

## Live statuses

```text
EPOCH_CHAIN                    = BOARD_CLOSED
HISTORICAL_C9_748_ROOT         = CLOSED
P_BOOT_DIRTY_DDR_ROOT          = CLOSED

TRANSACTION_INTEGRITY          = OPEN_AUDIT   (see G14-ROOT-B-TXN-AUDIT-00)
PERSISTENCE_IDENTITY           = OPEN_ACCEPTANCE
RESET_RETRAIN                  = OPEN_ACCEPTANCE
TEACHER_OFF_CAUSALITY          = OPEN
LM06_ACTIVE_CHAIN              = OPEN
MEMORY/PARALLELISM_ACCEPTANCE  = OPEN
SCALE_800K                     = OPEN

GATE14_PASS                    = NO
BOARD_PASS                     = not_claimed
NATIVE_V1_MINI_AI_BOARD_PASS   = NO
PROGRAM                        = NO
```

---

## Authority (CURRENT)

```text
1. BOARD bag G14-EPOCH-REBIRTH-BIT-00/BOARD/   (commit 9656245)
2. Root-B audit G14-ROOT-B-TXN-AUDIT-00/       (this session)
3. this file
4. HISTORICAL: STATUS/LOOP_STATE.json (updated 2026-08-23, next=ddr_cue_soa_00r…)
5. HISTORICAL: PROJECT_COMPLETE.md (2026-08-22 rematch; no Gate14 C9 silicon)
```

`LOOP_STATE.json` `next=ddr_cue_soa_00r_axi_liveness` is **SUPERSEDED**.
Do not start a session from that August NEXT.

---

## Next bounded gate

```text
G14-PERSISTENCE-IDENTITY-00
PROGRAM = NO
```

Prove semantically:

```text
state before FLUSH  ==  state after RELOAD
```

generation, occupancy, {subj,rel,obj}, priority, penalty, query-visible
C9/OUT. Do not treat “header restored” as enough.

Root B is **not** a confirmed silicon fail on `1F0F2ABB`. Hazards are
archived in `G14-ROOT-B-TXN-AUDIT-00`. Do not patch WDMA/AXI/LM together.

---

## Frozen (do not open without new first-divergence)

```text
epoch historical root
oracle HOLD_A C9=8382238122802120 OUT=653 / 689 / 237 / 60
scorer / Top-K / TinyGPT arithmetic / bind / LM weights
bit 1F0F2ABB
```

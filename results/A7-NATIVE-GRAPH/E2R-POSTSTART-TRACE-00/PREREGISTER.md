# E2R-POSTSTART-TRACE-00 — PREREGISTER

**Opened:** 2026-08-27  
**Worktree:** `arty-a7-online-lm-board`  
**ONE UNKNOWN:** After observed `CORE_START` on silicon, what is the **first functional non-progress** milestone?

## In scope

Instrumentation / mapping of existing sticky UART only.  
Do not change 01R, 02M, TinyGPT arithmetic, scorer, Top-K, bind law, DDR layout, weights, PE count, pipeline RTL.

## Out of scope

Option B, Option C, R7, `lm06_wm_ladder`, teacher-off semantic, performance, existence `pred=664` seal.

## Pass language (this gate only)

Identify the first missing post-`CORE_START` milestone with **hardware-observed** UART.  
Does **not** require `pred=664`. Then **STOP**.

## SOA invariant (do not cheat)

Boot `SOA_OK` ≠ query SOA PASS.  
Frozen 104-bit descriptor / 64-candidate query: expected **832 B** and **64** candidates.  
Those counts must be UART-observed to claim SOA payload PASS.

## Telemetry law

Stickies observe DUT bits. UART CDC via `sync_bits`.  
Must not affect ready/valid/winner/address/Top-K/bind/LM start/pred.  
Timeout must not mutate the functional FSM.

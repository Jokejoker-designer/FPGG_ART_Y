# Project A memory contract v0 — handoff to Project B

**Status:** engineering contract for the first Project B XSim bind; not BOARD authority  
**Project A evidence:** reachability `B_REQUIRED_OR_MIXED` + snapshot `PASS_NARROW`

## Physical decomposition after accepted snapshot candidate

| Subsystem | BRAM36 | Semantic TinyGPT `pred` cone? | Frozen C3 recipe? |
|---|---:|---|---|
| Core activation `act_ram128k16` | 64 | yes | yes |
| Core weight working tile | 32 | yes | yes |
| Snapshot LUTRAM candidate | 0 | yes, training/backward state | candidate only |
| BOARD tensor weight ping-pong | 32 | no direct `pred` edge | yes, K257/511/513 sibling gate |
| BOARD tensor activation | 2 | no direct `pred` edge | yes, K257/511/513 sibling gate |
| **Full frozen-recipe candidate** | **130** | mixed | candidate requires new evidence |
| **Semantic TinyGPT core subset** | **96** | yes | XSim bind scope only |

## Project B binding rule

For `HS22-LM06-NATIVE-CTX-FWD-00` XSim, Project B may instantiate the 96-BRAM-equivalent semantic core service: frozen weight/activation architecture plus the accepted snapshot LUTRAM candidate. The BOARD tensor subsystem is not required to compute `pred`, but omitting it means the test does not inherit the frozen C3 BOARD recipe or its K257/K511/K513 claim.

## Logical interface

```text
inputs:  clk_lm, rst_n, grant_lm,
         ctx_we, ctx_idx[6:0], ctx_n_in[6:0], ctx_pack[63:0], start_fwd
outputs: busy, done, pred[9:0], phase[7:0], w_stall
```

Invariants:

- GRAPH and LM grants are mutually exclusive.
- Native evidence logic, not host UART, drives `ctx_*` and `start_fwd` in Project B.
- `start_train`, `start_corpus`, host weight writes and host next-token authority are zero during the first answer-path gate.
- Frozen `tiny_gpt803k_core.sv`, TermGen, scorer, Global Top-K and descriptor laws remain unchanged.
- Weight bytes remain DDR-backed; BRAM is working state.

## Clock/service boundary

- TinyGPT core executes on `clk50`.
- Weight-tile refill service crosses to MIG `ui_clk` through the existing frozen DMA contract.
- Project B first gate is XSim causality, not full MIG/board integration; it must report any zero-latency memory substitution explicitly.

## What this contract does not grant

- No `BOARD_PASS`, timing, silicon or 800K-scale claim for Project B.
- No right to remove the 34-BRAM tensor sibling and reuse frozen C3 BOARD evidence.
- No right to edit frozen LM arithmetic or use sticky `lm_path` as the answer.


# ALLOW_PROGRAM — Grok proxy (Codex off)

**Date:** 2026-08-25T02:10:00+07:00  
**Gate:** `native_v1_existence_board_parallel_00`  
**Authority:** human assigned Grok DECIDE; E1-CLOCK80 PASS

```text
ALLOW_PROGRAM: native_v1_existence_board_parallel_00
```

## Scope (narrow)

| Allowed | Forbidden |
|---------|-----------|
| E2 bitstream from CLOCK80-lineage candidate @ **12.5 MHz** | `NATIVE_V1_MINI_AI_BOARD_PASS` self-claim |
| Program COM12 / JTAG for this gate only | HS-02, 800k, reset/retrain |
| UART/counter capture for existence | R6 worktree edits |
| Board worktree only | 100 MHz claim |

## Lineage

| Item | Value |
|------|-------|
| Stage A | `pred=664` XSIM_FAST_CAUSAL |
| E1 disposition | `DONE_ENG / BRAM_ONLY_PASS / OOC_TIMING_LIMIT` |
| E1-CLOCK80 WNS | +3.648 ns @ 80 ns |
| BRAM | 96 |
| DCP | `E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_post_route.dcp` |
| DCP SHA256 | `92A27DF729039D60BD18704F7B857FB62CA54AA331B2244F331FC8CB35F358EA` |

## E2 unknown (one)

On programmed Arty: does live Native evidence → actual LM06 → FPGA-owned pred with `host_next_token=0`, `teacher=0` during response window?

## Cursor execute

After this file is acknowledged in mailbox: preregister E2, build bitstream from same lineage, program exact JTAG target, capture evidence. Human `program_authorized=true` already in BRIDGE.

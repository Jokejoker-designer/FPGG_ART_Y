# E2R-CORE-START-RST-PROBE-00 PREREG

**PROGRAM=NO** until a unique bit SHA is built and explicitly authorized.

## Question

If COM12 shows

```
BOOT → MIG_OK → WMEM_OK → SOA_OK → CORE_START
BOOT → MIG_OK → WMEM_OK → SOA_OK → CORE_START
```

in **one** continuous capture, is the hang

- **A** CORE_START then stall (FSM / handshake / bind / LM), or
- **B** CORE_START then reset/reboot (reset tree / clk_locked / start CDC)?

## Archived evidence (read-only)

| Capture | Bytes | What |
|---------|------:|------|
| `E2R-HB-UART-00/uart_capture.txt` | 76 | Exactly two copies of BOOT…CORE_START. Listener armed before one JTAG program. |
| `E2R-HB-UART-00/uart_capture_r3.txt` | same | Same ×2. |
| `E2R-DDR-TILE-DMA-FSM-PROBE-00/uart_capture.txt` | 1060 | Two **full** telemetry cycles through `PHASE=01`, then BOOT again. |

RTL discriminator: UART `sent_mask` clears only on `!clk_locked`. Reprinting `BOOT` cannot be `core_rst_n`-only.

Caveat: arm-UART-then-program can concatenate leftover previous bitstream + new bitstream. That is **not** ruled out for HB-UART-00. TILE-DMA ×2 after progress is stronger for in-session restart.

## Probe (this gate)

Four sticky bits in CLK100MHZ, reset = `btn[0]` only (survives `clk_locked` and `core_rst_n`):

| UART | Meaning |
|------|---------|
| `CLK_ALIVE=H` | core_clk toggle seen (`CORE_CLK_ALIVE`) |
| `RST_REL=H` | `core_rst_n` was high (`CORE_RST_RELEASED`) |
| `START_SEEN=H` | core domain ran a cycle after `core_rst_n` (`CORE_START_SEEN_IN_CORE`) |
| `RST_CAUSE=H n=HH f=HH` | last cause + `boot_count` + `core_rst` fall count |

Cause nibble: `0` POR `1` BTN `2` MIG `3` CORE_RST `4` LOCK_DROP `5` OTHER.

Does **not** change scorer / minheap / TinyGPT / bind law.

## Ranking if ×2 is one bitstream after DONE

1. reset/restart after core release (`clk_locked` drop reprints BOOT)
2. start handshake never reaches core (`CORE_START` 100 MHz vs `START_SEEN`)
3. core clock/reset release (`CLK_ALIVE` / `RST_REL`)
4. owner/query FSM
5. TopK/bind
6. LM

If capture is two separate board runs, ranking stays: no progress after CORE_START.

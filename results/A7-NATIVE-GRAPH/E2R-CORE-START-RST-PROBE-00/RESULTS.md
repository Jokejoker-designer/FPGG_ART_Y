# E2R-CORE-START-RST-PROBE-00 RESULTS

**GATE14_PASS = NO. BOARD_PASS = NO. EXISTENCE_PASS = NO.**

HEAD: `cd8c41c10259f5362e5b64e9043604277ae54409` + probe patch on `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv`.

## Step A–C (RTL)

See `RTL_AUDIT.md`. Probe patched before synth:

- 2FF all probe inputs with `rst_n=1'b1` (not `clk_locked`)
- `START_SEEN` = `start_q` toggle + 100 MHz edge
- `RST_CAUSE=4` sticky

`sent_mask` clears only on `!clk_locked`. `core_rst_n` alone cannot reprint BOOT.

START: `start_q` is **same** `core_clk` as `u_ab` (1-cycle). UART `CORE_START` is 100 MHz `calib&&wmem&&boot`, not consume.

## Step D — unique bit

| Item | Value |
|------|-------|
| Vivado | 2026.1 SW 6511674 |
| UART_SLIM | 0 |
| BIT_SHA256 | `7ECCA0E21BF27DD13451F3EFB4F180A7B15627B610D81BECAE07CA9FFA12E219` |
| WNS / TNS / WHS / THS | 0.651 / 0 / 0.010 / 0 |
| core_WNS / ui_WNS | 44.611 / 2.019 |
| RAMB36 / DSP | 104 / 19 |
| CDC | parser unsafe=5, all User Ignored; `core_clk→sys_clk_pin` 252/0 |

Not `A0B338E0`.

## Step E — one program after DONE

| Item | Value |
|------|-------|
| JTAG | `210319BE776EA` |
| COM | COM12 115200 |
| PROGRAM | once |
| `uart_raw.bin` SHA256 | `7EAB12E74E3E9B8C1CF3F2A4331413A65FFA4E0C0518FFC182C7C3E4290462BC` |
| bytes | 732, **before_done=0**, after_done=732 |
| BOOT | **1** |
| Hold after DONE | 180 s |

Raw log not edited. File: `uart_capture.txt`.

## Step F — classification

| Case | This bit after DONE |
|------|---------------------|
| 1 LOCK_DROP `n>=2` CAUSE=4 | **NO** — `n=01` CAUSE=0, one BOOT |
| 2 CORE_START + START_SEEN=0 | print is **too early**; `Q_GO` later ⇒ start consumed |
| 3 CLK_ALIVE=0 | **NO** — `CLK_ALIVE=1` |
| 4 RST_REL=0 | print too early; `CORE_DONE` ⇒ reset released |
| 5 START_SEEN=1, no BOOT, owner | owner **did** run (`Q_GO`…`CORE_DONE`) |

**Not A. Not B on `7ECCA0E2`.** Archived TILE-DMA BOOT×2 was a **different bit**.

Primary class: `INCONCLUSIVE` (archive B root not re-measured here).

Verdict: `FAILURE MOVED DOWNSTREAM` (`pred=249` observed; scorer/TopK/LM not opened).
